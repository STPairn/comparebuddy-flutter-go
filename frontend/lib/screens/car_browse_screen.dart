import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/car.dart';
import '../services/api_service.dart';
import '../widgets/car_model_card.dart';
import '../widgets/car_variant_card.dart';
import 'car_variant_detail_screen.dart';
import 'car_compare_screen.dart';

const _prefKeyIds    = 'pending_comparison_ids';
const _prefKeyLabels = 'pending_comparison_labels';

enum _FilterStep { powertrain, brand, range, price }

class CarBrowseScreen extends StatefulWidget {
  const CarBrowseScreen({Key? key}) : super(key: key);

  @override
  State<CarBrowseScreen> createState() => _CarBrowseScreenState();
}

class _CarBrowseScreenState extends State<CarBrowseScreen> {
  final ApiService _apiService = ApiService();

  List<CarBrand> _brands = [];
  List<CarModel> _models = [];
  List<CarVariantSummary> _variants = [];
  bool _isLoadingBrands = true;
  bool _isLoadingModels = false;
  bool _isLoadingVariants = false;

  int? _selectedBrandId;
  int? _selectedModelId;
  final Set<String> _selectedPowertrains = {};
  final Set<int> _selectedVariantIds = {};
  final Map<int, String> _selectedVariantLabels = {}; // variantId → display label

  _FilterStep? _activeStep;

  double _minPrice = 0;
  double _maxPrice = 5000000;
  List<CarSearchResult> _filterResults = [];
  bool _isLoadingFilter = false;
  bool _filterActive = false;

  double _minRange = 0;

  // Brand filter (based on powertrain + price)
  Set<String>? _filteredBrandNames; // null = show all
  bool _isLoadingBrandFilter = false;

  @override
  void initState() {
    super.initState();
    _loadBrands();
    _loadPendingComparison();
  }

  Future<void> _loadPendingComparison() async {
    final prefs = await SharedPreferences.getInstance();
    final idsJson = prefs.getString(_prefKeyIds);
    final labelsJson = prefs.getString(_prefKeyLabels);
    if (idsJson == null) return;
    final ids = (json.decode(idsJson) as List).map((e) => e as int).toList();
    final labels = <int, String>{};
    if (labelsJson != null) {
      final raw = json.decode(labelsJson) as Map<String, dynamic>;
      for (final entry in raw.entries) {
        labels[int.parse(entry.key)] = entry.value as String;
      }
    }
    setState(() {
      _selectedVariantIds.addAll(ids);
      _selectedVariantLabels.addAll(labels);
    });
  }

  Future<void> _savePendingComparison() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedVariantIds.isEmpty) {
      await prefs.remove(_prefKeyIds);
      await prefs.remove(_prefKeyLabels);
    } else {
      await prefs.setString(_prefKeyIds, json.encode(_selectedVariantIds.toList()));
      final labelsStr = _selectedVariantLabels.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_prefKeyLabels, json.encode(labelsStr));
    }
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoadingBrands = true);
    final brands = await _apiService.getCarBrands();
    setState(() {
      _brands = brands;
      _isLoadingBrands = false;
    });
  }

  void _togglePowertrain(String type) {
    setState(() {
      if (_selectedPowertrains.contains(type)) {
        _selectedPowertrains.remove(type);
      } else {
        _selectedPowertrains.add(type);
      }
      _selectedBrandId = null;
      _selectedModelId = null;
      _models = [];
      _variants = [];
      _filterActive = false;
      _filterResults = [];
      _filteredBrandNames = null;
      _activeStep = _selectedPowertrains.isNotEmpty ? _FilterStep.brand : null;
    });
    if (_selectedPowertrains.isNotEmpty) _refreshFilteredBrands();
  }

  Future<void> _refreshFilteredBrands() async {
    setState(() => _isLoadingBrandFilter = true);
    // Call API in parallel for each selected powertrain type
    final futures = _selectedPowertrains.isNotEmpty
        ? _selectedPowertrains.map((type) => _apiService.browseCarsByPrice(
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              powertrainType: type,
              minRange: _minRange > 0 ? _minRange.toInt() : null,
            ))
        : [
            _apiService.browseCarsByPrice(
              minPrice: _minPrice,
              maxPrice: _maxPrice,
              minRange: _minRange > 0 ? _minRange.toInt() : null,
            )
          ];
    final allResults = await Future.wait(futures);
    final brandNames = <String>{};
    for (final list in allResults) {
      brandNames.addAll(list.map((r) => r.brandName));
    }
    setState(() {
      _filteredBrandNames = brandNames;
      _isLoadingBrandFilter = false;
    });
  }

  Future<void> _selectBrand(int brandId) async {
    setState(() {
      _selectedBrandId = brandId;
      _selectedModelId = null;
      _variants = [];
      _isLoadingModels = true;
      _activeStep = null;
      _filterActive = false;
      _filterResults = [];
    });

    final data = await _apiService.getCarBrandById(brandId);
    if (data != null && data['models'] != null) {
      final models = (data['models'] as List).map((m) => CarModel.fromJson(m)).toList();
      final filtered = _selectedPowertrains.isNotEmpty
          ? models.where((m) => _selectedPowertrains.contains(m.powertrainType.toUpperCase())).toList()
          : models;
      setState(() {
        _models = filtered;
        _isLoadingModels = false;
      });
    } else {
      setState(() {
        _models = [];
        _isLoadingModels = false;
      });
    }
  }

  Future<void> _selectModel(int modelId) async {
    setState(() {
      _selectedModelId = modelId;
      _isLoadingVariants = true;
    });

    final data = await _apiService.getCarModelById(modelId);
    if (data != null && data['variants'] != null) {
      setState(() {
        _variants = (data['variants'] as List).map((v) => CarVariantSummary.fromJson(v)).toList();
        _isLoadingVariants = false;
      });
    } else {
      setState(() {
        _variants = [];
        _isLoadingVariants = false;
      });
    }
  }

  Future<void> _loadFiltered() async {
    setState(() => _isLoadingFilter = true);
    List<CarSearchResult> allResults = [];
    if (_selectedPowertrains.isEmpty) {
      allResults = await _apiService.browseCarsByPrice(
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRange: _minRange > 0 ? _minRange.toInt() : null,
      );
    } else {
      final futures = _selectedPowertrains.map((type) => _apiService.browseCarsByPrice(
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            powertrainType: type,
            minRange: _minRange > 0 ? _minRange.toInt() : null,
          ));
      final lists = await Future.wait(futures);
      final seen = <int>{};
      for (final list in lists) {
        for (final r in list) {
          if (seen.add(r.variantId)) allResults.add(r);
        }
      }
      allResults.sort((a, b) => (a.priceBaht ?? 0).compareTo(b.priceBaht ?? 0));
    }
    setState(() {
      _filterResults = allResults;
      _filteredBrandNames = allResults.map((r) => r.brandName).toSet();
      _isLoadingFilter = false;
      _filterActive = true;
      _selectedBrandId = null;
      _selectedModelId = null;
      _models = [];
      _variants = [];
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedPowertrains.clear();
      _selectedBrandId = null;
      _selectedModelId = null;
      _models = [];
      _variants = [];
      _minRange = 0;
      _minPrice = 0;
      _maxPrice = 5000000;
      _filterActive = false;
      _filterResults = [];
      _filteredBrandNames = null;
      _isLoadingBrandFilter = false;
      _activeStep = null;
    });
  }

  void _toggleVariantSelection(int variantId, {String label = ''}) {
    bool changed = false;
    setState(() {
      if (_selectedVariantIds.contains(variantId)) {
        _selectedVariantIds.remove(variantId);
        _selectedVariantLabels.remove(variantId);
        changed = true;
      } else if (_selectedVariantIds.length < 4) {
        _selectedVariantIds.add(variantId);
        _selectedVariantLabels[variantId] = label.isNotEmpty ? label : 'รุ่น #$variantId';
        changed = true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เลือกได้สูงสุด 4 คัน'),
            backgroundColor: Color(0xFF795548),
          ),
        );
      }
    });
    if (changed) _savePendingComparison();
  }

  void _goToCompare() {
    if (_selectedVariantIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เลือกอย่างน้อย 2 คันเพื่อเปรียบเทียบ'),
          backgroundColor: Color(0xFF795548),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CarCompareScreen(variantIds: _selectedVariantIds.toList()),
      ),
    ).then((_) async {
      // Clear ก่อน แล้ว reload จาก prefs เพื่อคงเฉพาะที่เหลือ
      setState(() {
        _selectedVariantIds.clear();
        _selectedVariantLabels.clear();
      });
      await _loadPendingComparison();
    });
  }

  void _toggleStep(_FilterStep step) {
    setState(() {
      _activeStep = _activeStep == step ? null : step;
    });
  }

  bool get _hasActiveFilters =>
      _selectedPowertrains.isNotEmpty ||
      _selectedBrandId != null ||
      _minRange > 0 ||
      _filterActive;

  Color _powertrainColor(String type) {
    switch (type.toLowerCase()) {
      case 'bev':  return const Color(0xFF4CAF50);
      case 'phev': return const Color(0xFF2196F3);
      case 'hev':  return const Color(0xFF009688);
      case 'ice':  return const Color(0xFF795548);
      default:     return Colors.grey;
    }
  }

  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final selectedBrandName = _selectedBrandId != null && _brands.any((b) => b.id == _selectedBrandId)
        ? _brands.firstWhere((b) => b.id == _selectedBrandId).name
        : null;
    final showRangeChip = _selectedPowertrains.contains('BEV') || _selectedPowertrains.contains('PHEV');

    // Powertrain chip label
    String? powertrainChipValue;
    if (_selectedPowertrains.length == 1) {
      powertrainChipValue = _selectedPowertrains.first;
    } else if (_selectedPowertrains.length > 1) {
      powertrainChipValue = '${_selectedPowertrains.length} ประเภท';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E2723),
        title: const Text(
          'เปรียบเทียบรถยนต์',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: _CarSearchDelegate(_apiService)),
          ),
        ],
      ),
      body: _isLoadingBrands
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF795548)))
          : Column(
              children: [
                // ── Filter bar ──────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'ประเภท',
                          value: powertrainChipValue,
                          step: _FilterStep.powertrain,
                          icon: Icons.bolt,
                          accentColor: _selectedPowertrains.length == 1
                              ? _powertrainColor(_selectedPowertrains.first)
                              : const Color(0xFF795548),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'ยี่ห้อ',
                          value: selectedBrandName,
                          step: _FilterStep.brand,
                          icon: Icons.business,
                          accentColor: const Color(0xFF795548),
                        ),
                        if (showRangeChip) ...[
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'ระยะทาง',
                            value: _minRange > 0 ? '≥${_minRange.toInt()} km' : null,
                            step: _FilterStep.range,
                            icon: Icons.electric_car,
                            accentColor: const Color(0xFF4CAF50),
                          ),
                        ],
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'ราคา',
                          value: (_minPrice > 0 || _maxPrice < 5000000)
                              ? '${_minPrice > 0 ? '฿${(_minPrice / 1000).toStringAsFixed(0)}K' : '฿0'}–${_maxPrice < 5000000 ? '฿${(_maxPrice / 1000).toStringAsFixed(0)}K' : 'Max'}'
                              : null,
                          step: _FilterStep.price,
                          icon: Icons.attach_money,
                          accentColor: const Color(0xFF795548),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _clearFilters,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close, size: 13, color: Colors.red.shade400),
                                  const SizedBox(width: 3),
                                  Text(
                                    'ล้าง',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Selected variants bar ────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _selectedVariantIds.isNotEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3E2723).withOpacity(0.05),
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.compare_arrows, size: 14, color: Color(0xFF795548)),
                                  const SizedBox(width: 5),
                                  Text(
                                    'เลือกเปรียบเทียบ ${_selectedVariantIds.length}/4 คัน',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF795548),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: _selectedVariantIds.map((id) {
                                    final label = _selectedVariantLabels[id] ?? 'รุ่น #$id';
                                    return Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF795548).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFF795548).withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF3E2723),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          GestureDetector(
                                            onTap: () => _toggleVariantSelection(id),
                                            child: const Icon(Icons.close, size: 13, color: Color(0xFF795548)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // ── Step Panel (animated expand/collapse) ────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _activeStep != null
                      ? Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F5F2),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: _buildStepPanel(),
                        )
                      : const SizedBox.shrink(),
                ),

                // ── Content ──────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_hasActiveFilters) _buildGuideCard(),

                        // Price / range filter results
                        if (_filterActive) ...[
                          _buildSectionHeader(
                            'ผลลัพธ์ (${_filterResults.length} คัน)',
                            Icons.list_alt,
                          ),
                          const SizedBox(height: 8),
                          if (_isLoadingFilter)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Color(0xFF795548)),
                              ),
                            )
                          else if (_filterResults.isEmpty)
                            _buildEmptyState('ไม่พบรถในเงื่อนไขนี้')
                          else
                            ..._filterResults.map((r) => _buildResultItem(r)),
                        ],

                        // Brand → models list
                        if (!_filterActive && _selectedBrandId != null) ...[
                          _buildSectionHeader(
                            'รุ่นรถ${selectedBrandName != null ? ' · $selectedBrandName' : ''}',
                            Icons.directions_car,
                          ),
                          const SizedBox(height: 8),
                          if (_isLoadingModels)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Color(0xFF795548)),
                              ),
                            )
                          else if (_models.isEmpty)
                            _buildEmptyState('ไม่พบรุ่นรถ')
                          else
                            ..._models.map((model) => CarModelCard(
                                  model: model,
                                  onTap: () => _selectModel(model.id),
                                )),
                        ],

                        // Variants
                        if (_selectedModelId != null) ...[
                          const SizedBox(height: 20),
                          _buildSectionHeader(
                            'รุ่นย่อย',
                            Icons.list_alt,
                          ),
                          const SizedBox(height: 8),
                          if (_isLoadingVariants)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: Color(0xFF795548)),
                              ),
                            )
                          else if (_variants.isEmpty)
                            _buildEmptyState('ไม่พบรุ่นย่อย')
                          else
                            ..._variants.map((variant) {
                              final modelName = _models.any((m) => m.id == variant.modelId)
                                  ? _models.firstWhere((m) => m.id == variant.modelId).name
                                  : '';
                              final brandName = selectedBrandName ?? '';
                              return CarVariantCard(
                                variant: variant,
                                isSelected: _selectedVariantIds.contains(variant.id),
                                onTap: () => _toggleVariantSelection(
                                  variant.id,
                                  label: '$brandName $modelName ${variant.name}'.trim(),
                                ),
                                onViewDetail: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CarVariantDetailScreen(variantId: variant.id),
                                  ),
                                ),
                              );
                            }),
                        ],

                        if (_selectedVariantIds.isNotEmpty) const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _selectedVariantIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _goToCompare,
              backgroundColor: const Color(0xFF795548),
              icon: const Icon(Icons.compare_arrows, color: Colors.white),
              label: Text(
                'เปรียบเทียบ (${_selectedVariantIds.length})',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  // ── Filter chip ────────────────────────────────────────────────────────
  Widget _buildFilterChip({
    required String label,
    required String? value,
    required _FilterStep step,
    required IconData icon,
    required Color accentColor,
  }) {
    final isOpen = _activeStep == step;
    final isSelected = value != null;

    return GestureDetector(
      onTap: () => _toggleStep(step),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOpen
              ? const Color(0xFF3E2723)
              : isSelected
                  ? accentColor.withOpacity(0.1)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOpen
                ? const Color(0xFF3E2723)
                : isSelected
                    ? accentColor
                    : Colors.grey.shade300,
            width: isOpen || isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isOpen
                  ? Colors.white
                  : isSelected
                      ? accentColor
                      : Colors.grey.shade600,
            ),
            const SizedBox(width: 5),
            Text(
              value ?? label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOpen
                    ? Colors.white
                    : isSelected
                        ? accentColor
                        : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 13,
              color: isOpen
                  ? Colors.white
                  : isSelected
                      ? accentColor
                      : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step panel router ──────────────────────────────────────────────────
  Widget _buildStepPanel() {
    switch (_activeStep) {
      case _FilterStep.powertrain: return _buildPowertrainPanel();
      case _FilterStep.brand:      return _buildBrandPanel();
      case _FilterStep.range:      return _buildRangePanel();
      case _FilterStep.price:      return _buildPricePanel();
      default:                     return const SizedBox.shrink();
    }
  }

  // ── Step 1: Powertrain ─────────────────────────────────────────────────
  Widget _buildPowertrainPanel() {
    const info = {
      'BEV':  (Icons.electric_car,     Color(0xFF4CAF50), 'ไฟฟ้า 100%'),
      'PHEV': (Icons.ev_station,        Color(0xFF2196F3), 'ปลั๊กอินไฮบริด'),
      'HEV':  (Icons.eco,               Color(0xFF009688), 'ไฮบริด'),
      'ICE':  (Icons.local_gas_station, Color(0xFF795548), 'น้ำมัน'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกประเภทขุมพลัง',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Row(
            children: ['BEV', 'PHEV', 'HEV', 'ICE'].map((type) {
              final d = info[type]!;
              final isSelected = _selectedPowertrains.contains(type);
              return Expanded(
                child: GestureDetector(
                  onTap: () => _togglePowertrain(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: type != 'ICE' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? d.$2 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? d.$2 : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: d.$2.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(d.$1, color: isSelected ? Colors.white : d.$2, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : d.$2,
                          ),
                        ),
                        Text(
                          d.$3,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? Colors.white70 : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Brand ──────────────────────────────────────────────────────
  Widget _buildBrandPanel() {
    final displayBrands = _filteredBrandNames != null
        ? _brands.where((b) => _filteredBrandNames!.contains(b.name)).toList()
        : _brands;

    String subtitle = 'เลือกยี่ห้อ';
    if (_selectedPowertrains.isNotEmpty || _filteredBrandNames != null) {
      final parts = <String>[];
      if (_selectedPowertrains.isNotEmpty) parts.add(_selectedPowertrains.join(', '));
      if (_filteredBrandNames != null) parts.add('${displayBrands.length} ยี่ห้อ');
      subtitle = 'เลือกยี่ห้อ (${parts.join(' · ')})';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 10),
          if (_isLoadingBrandFilter)
            const SizedBox(
              height: 82,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF795548), strokeWidth: 2),
              ),
            )
          else if (displayBrands.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Text(
                'ไม่พบยี่ห้อในเงื่อนไขนี้',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            )
          else
            SizedBox(
              height: 82,
              width: double.infinity,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: displayBrands.length,
                padding: const EdgeInsets.only(right: 16),
                itemBuilder: (context, index) {
                  final brand = displayBrands[index];
                  final isSelected = _selectedBrandId == brand.id;
                  return GestureDetector(
                    onTap: () => _selectBrand(brand.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF795548) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF795548) : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [const BoxShadow(color: Color(0x33795548), blurRadius: 6, offset: Offset(0, 2))]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 20,
                            color: isSelected ? Colors.white : const Color(0xFF795548),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            brand.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF3E2723),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 3: Range (EV) ────────────────────────────────────────────────
  Widget _buildRangePanel() {
    final options = [0, 200, 300, 400, 500, 600];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ระยะทางขั้นต่ำ (EV range)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((km) {
              final isSelected = (km == 0 && _minRange == 0) || _minRange.toInt() == km;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _minRange = km.toDouble();
                    _activeStep = null;
                  });
                  if (_filterActive) _loadFiltered();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    km == 0 ? 'ทุกระยะ' : '≥ $km km',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _activeStep = null);
                _loadFiltered();
              },
              icon: const Icon(Icons.search, size: 16),
              label: const Text('ค้นหา', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Price ──────────────────────────────────────────────────────
  Widget _buildPricePanel() {
    const minOptions = [0.0, 500000.0, 700000.0, 1000000.0, 1500000.0, 2000000.0, 3000000.0];
    const maxOptions = [500000.0, 700000.0, 1000000.0, 1500000.0, 2000000.0, 3000000.0, 5000000.0];

    String priceLabel(double v, {bool isMax = false}) {
      if (v == 0) return 'ทุกราคา';
      if (v == 5000000 && isMax) return 'ไม่จำกัด';
      if (v >= 1000000) {
        final m = v / 1000000;
        return '${m == m.toInt() ? m.toInt() : m.toStringAsFixed(1)}ล.';
      }
      return '${(v / 1000).toStringAsFixed(0)}K';
    }

    Widget priceRow(List<double> options, double selected, bool isMax) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: options.map((v) {
            final isSel = selected == v;
            return GestureDetector(
              onTap: () => setState(() {
                if (isMax) {
                  _maxPrice = v;
                  if (_minPrice > _maxPrice) _minPrice = 0;
                } else {
                  _minPrice = v;
                  if (_maxPrice < _minPrice) _maxPrice = 5000000;
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF795548) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel ? const Color(0xFF795548) : Colors.grey.shade300,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Text(
                  priceLabel(v, isMax: isMax),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSel ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ราคาเริ่มต้น',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          priceRow(minOptions, _minPrice, false),
          const SizedBox(height: 14),
          Text('ราคาสูงสุด',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          priceRow(maxOptions, _maxPrice, true),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _activeStep = null);
                _loadFiltered();
              },
              icon: const Icon(Icons.search, size: 16),
              label: const Text('ค้นหาตามราคา', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF795548),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Guide card ────────────────────────────────────────────────────────
  Widget _buildGuideCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3E2723).withOpacity(0.05),
            const Color(0xFF795548).withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF795548).withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app, color: Color(0xFF795548), size: 18),
              SizedBox(width: 8),
              Text(
                'เริ่มค้นหารถ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF3E2723)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStepRow(1, Icons.bolt, 'เลือกประเภท', 'BEV / PHEV / HEV / ICE'),
          const SizedBox(height: 10),
          _buildStepRow(2, Icons.business, 'เลือกยี่ห้อ', 'Toyota, Honda, BYD...'),
          const SizedBox(height: 10),
          _buildStepRow(3, Icons.electric_car, 'กรองระยะทาง', 'สำหรับรถ EV (BEV/PHEV)'),
          const SizedBox(height: 10),
          _buildStepRow(4, Icons.attach_money, 'กรองราคา', 'ค้นหาตามงบประมาณ'),
        ],
      ),
    );
  }

  Widget _buildStepRow(int step, IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF795548).withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF795548)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 15, color: const Color(0xFF795548)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3E2723))),
            Text(sub, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }

  // ── Result item ────────────────────────────────────────────────────────
  Widget _buildResultItem(CarSearchResult result) {
    final color = _powertrainColor(result.powertrainType);
    final isSelected = _selectedVariantIds.contains(result.variantId);
    return GestureDetector(
      onTap: () => _toggleVariantSelection(
        result.variantId,
        label: '${result.brandName} ${result.modelName} ${result.variantName}',
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF795548).withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF795548).withOpacity(0.4) : Colors.grey.shade100,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF795548) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF795548) : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 10),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${result.brandName} ${result.modelName}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3E2723)),
                      ),
                      Text(result.variantName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        children: [
                          _tag(result.powertrainType.toUpperCase(), color),
                          if (result.priceBaht != null)
                            Text(
                              _formatPrice(result.priceBaht),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF795548), fontWeight: FontWeight.w500),
                            ),
                          if (result.rangeKm != null &&
                              (result.powertrainType.toUpperCase() == 'BEV' ||
                                  result.powertrainType.toUpperCase() == 'PHEV'))
                            _tag('⚡ ${result.rangeKm} km', const Color(0xFF4CAF50)),
                          if (result.fuelConsumptionKml != null &&
                              (result.powertrainType.toUpperCase() == 'ICE' ||
                                  result.powertrainType.toUpperCase() == 'HEV'))
                            _tag('⛽ ${result.fuelConsumptionKml!.toStringAsFixed(1)} km/L', const Color(0xFF795548)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // ── ปุ่มดูรายละเอียด ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CarVariantDetailScreen(variantId: result.variantId),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ดูรายละเอียด',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF795548),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 14, color: Color(0xFF795548)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _formatPrice(double? price) {
    if (price == null) return 'ไม่ระบุราคา';
    return NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0).format(price);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF795548)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, color: Color(0xFF3E2723), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Delegate
// ─────────────────────────────────────────────────────────────────────────────
class _CarSearchDelegate extends SearchDelegate<int?> {
  final ApiService _apiService;

  _CarSearchDelegate(this._apiService)
      : super(
          searchFieldLabel: 'ค้นหารถยนต์...',
          searchFieldStyle: const TextStyle(fontSize: 16),
        );

  String _formatPrice(double? price) {
    if (price == null) return 'ไม่ระบุราคา';
    return NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0).format(price);
  }

  Color _powertrainColor(String type) {
    switch (type.toLowerCase()) {
      case 'bev':  return const Color(0xFF4CAF50);
      case 'phev': return const Color(0xFF2196F3);
      case 'hev':  return const Color(0xFF009688);
      case 'ice':  return const Color(0xFF795548);
      default:     return Colors.grey;
    }
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF3E2723),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('พิมพ์ชื่อรถเพื่อค้นหา', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    return FutureBuilder<List<CarSearchResult>>(
      future: _apiService.searchCars(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF795548)));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('ไม่พบผลลัพธ์สำหรับ "$query"',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) => _buildSearchResultItem(context, results[index]),
        );
      },
    );
  }

  Widget _buildSearchResultItem(BuildContext context, CarSearchResult result) {
    final color = _powertrainColor(result.powertrainType);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CarVariantDetailScreen(variantId: result.variantId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.directions_car, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${result.brandName} ${result.modelName}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3E2723)),
                  ),
                  Text(result.variantName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          result.powertrainType.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _formatPrice(result.priceBaht),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF795548), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
