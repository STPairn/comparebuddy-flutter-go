import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/car.dart';
import '../services/api_service.dart';
import '../widgets/car_brand_card.dart';
import '../widgets/car_model_card.dart';
import '../widgets/car_variant_card.dart';
import 'car_variant_detail_screen.dart';
import 'car_compare_screen.dart';

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
  String? _selectedPowertrain;
  final Set<int> _selectedVariantIds = {};

  final List<String> _powertrainFilters = ['BEV', 'PHEV', 'HEV', 'ICE'];

  // Price range filter
  RangeValues _priceRange = const RangeValues(0, 5000000);
  List<CarSearchResult> _priceFilterResults = [];
  bool _isLoadingPriceFilter = false;
  bool _priceFilterActive = false;

  // Range / Fuel efficiency filters
  double _minRange = 0; // km (0 = ไม่กรอง)
  double _minFuelEfficiency = 0; // km/L (0 = ไม่กรอง)

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoadingBrands = true);
    final brands = await _apiService.getCarBrands();
    setState(() {
      _brands = brands;
      _isLoadingBrands = false;
    });
  }

  Future<void> _selectBrand(int brandId) async {
    setState(() {
      _selectedBrandId = brandId;
      _selectedModelId = null;
      _variants = [];
      _isLoadingModels = true;
    });

    final data = await _apiService.getCarBrandById(brandId);
    if (data != null && data['models'] != null) {
      List<dynamic> modelsJson = data['models'];
      final models = modelsJson.map((m) => CarModel.fromJson(m)).toList();

      // Apply powertrain filter if selected
      final filtered = _selectedPowertrain != null
          ? models.where((m) => m.powertrainType.toUpperCase() == _selectedPowertrain).toList()
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
      List<dynamic> variantsJson = data['variants'];
      setState(() {
        _variants = variantsJson.map((v) => CarVariantSummary.fromJson(v)).toList();
        _isLoadingVariants = false;
      });
    } else {
      setState(() {
        _variants = [];
        _isLoadingVariants = false;
      });
    }
  }

  void _togglePowertrain(String type) {
    setState(() {
      if (_selectedPowertrain == type) {
        _selectedPowertrain = null;
      } else {
        _selectedPowertrain = type;
      }
      // Reload models if brand is selected
      if (_selectedBrandId != null) {
        _selectBrand(_selectedBrandId!);
      }
      // Reload price filter if active
      if (_priceFilterActive) {
        _loadByPrice();
      }
    });
  }

  Future<void> _loadByPrice() async {
    setState(() => _isLoadingPriceFilter = true);
    final results = await _apiService.browseCarsByPrice(
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      powertrainType: _selectedPowertrain,
      minRange: _minRange > 0 ? _minRange.toInt() : null,
      minFuelEfficiency: _minFuelEfficiency > 0 ? _minFuelEfficiency : null,
    );
    setState(() {
      _priceFilterResults = results;
      _isLoadingPriceFilter = false;
      _priceFilterActive = true;
    });
  }

  void _toggleVariantSelection(int variantId) {
    setState(() {
      if (_selectedVariantIds.contains(variantId)) {
        _selectedVariantIds.remove(variantId);
      } else if (_selectedVariantIds.length < 4) {
        _selectedVariantIds.add(variantId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เลือกได้สูงสุด 4 คัน'),
            backgroundColor: Color(0xFF795548),
          ),
        );
      }
    });
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
    );
  }

  void _openSearch() {
    showSearch(context: context, delegate: _CarSearchDelegate(_apiService));
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _openSearch,
          ),
        ],
      ),
      body: _isLoadingBrands
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF795548)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Powertrain filter chips
                  _buildSectionHeader('ประเภทขุมพลัง', Icons.bolt),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _powertrainFilters.map((type) {
                      final isSelected = _selectedPowertrain == type;
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (_) => _togglePowertrain(type),
                        selectedColor: const Color(0xFF795548),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF3E2723),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: isSelected ? const Color(0xFF795548) : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Price range filter
                  _buildSectionHeader('ช่วงราคา', Icons.attach_money),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0).format(_priceRange.start)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3E2723)),
                            ),
                            Text(
                              '${NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0).format(_priceRange.end)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3E2723)),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF795548),
                            inactiveTrackColor: Colors.grey.shade300,
                            thumbColor: const Color(0xFF795548),
                            overlayColor: const Color(0xFF795548).withOpacity(0.2),
                            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 5000000,
                            divisions: 50,
                            onChanged: (values) {
                              setState(() => _priceRange = values);
                            },
                            onChangeEnd: (_) => _loadByPrice(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loadByPrice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF795548),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('ค้นหาตามช่วงราคา', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Range filter (EV)
                  _buildSectionHeader('ระยะทาง EV ขั้นต่ำ', Icons.electric_car),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _minRange > 0 ? '>= ${_minRange.toInt()} km' : 'ไม่กรอง',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3E2723)),
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF4CAF50),
                            inactiveTrackColor: Colors.grey.shade300,
                            thumbColor: const Color(0xFF4CAF50),
                            overlayColor: const Color(0xFF4CAF50).withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _minRange,
                            min: 0,
                            max: 700,
                            divisions: 14,
                            label: _minRange > 0 ? '${_minRange.toInt()} km' : 'ไม่กรอง',
                            onChanged: (value) {
                              setState(() => _minRange = value);
                            },
                            onChangeEnd: (_) {
                              if (_priceFilterActive) _loadByPrice();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Fuel efficiency filter
                  _buildSectionHeader('อัตราสิ้นเปลือง ขั้นต่ำ', Icons.local_gas_station),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _minFuelEfficiency > 0 ? '>= ${_minFuelEfficiency.toInt()} km/L' : 'ไม่กรอง',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3E2723)),
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF795548),
                            inactiveTrackColor: Colors.grey.shade300,
                            thumbColor: const Color(0xFF795548),
                            overlayColor: const Color(0xFF795548).withOpacity(0.2),
                          ),
                          child: Slider(
                            value: _minFuelEfficiency,
                            min: 0,
                            max: 30,
                            divisions: 30,
                            label: _minFuelEfficiency > 0 ? '${_minFuelEfficiency.toInt()} km/L' : 'ไม่กรอง',
                            onChanged: (value) {
                              setState(() => _minFuelEfficiency = value);
                            },
                            onChangeEnd: (_) {
                              if (_priceFilterActive) _loadByPrice();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Price filter results
                  if (_priceFilterActive) ...[
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      'ผลลัพธ์ (${_priceFilterResults.length} คัน)',
                      Icons.list_alt,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingPriceFilter)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: Color(0xFF795548)),
                        ),
                      )
                    else if (_priceFilterResults.isEmpty)
                      _buildEmptyState('ไม่พบรถในช่วงราคานี้')
                    else
                      ..._priceFilterResults.map((result) => _buildPriceResultItem(result)),
                  ],

                  const SizedBox(height: 20),

                  // Brand grid
                  _buildSectionHeader('เลือกแบรนด์', Icons.business),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _brands.length,
                    itemBuilder: (context, index) {
                      final brand = _brands[index];
                      return CarBrandCard(
                        brand: brand,
                        isSelected: _selectedBrandId == brand.id,
                        onTap: () => _selectBrand(brand.id),
                      );
                    },
                  ),

                  // Models section
                  if (_selectedBrandId != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      'รุ่นรถ${_brands.where((b) => b.id == _selectedBrandId).isNotEmpty ? ' - ${_brands.firstWhere((b) => b.id == _selectedBrandId).name}' : ''}',
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

                  // Variants section
                  if (_selectedModelId != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader('รุ่นย่อย (กดเพื่อดูรายละเอียด / กดค้างเพื่อเลือกเปรียบเทียบ)', Icons.list_alt),
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
                      ..._variants.map((variant) => CarVariantCard(
                            variant: variant,
                            isSelected: _selectedVariantIds.contains(variant.id),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CarVariantDetailScreen(variantId: variant.id),
                                ),
                              );
                            },
                            onLongPress: () => _toggleVariantSelection(variant.id),
                          )),
                  ],

                  // Bottom padding for FAB
                  if (_selectedVariantIds.isNotEmpty) const SizedBox(height: 80),
                ],
              ),
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

  String _formatPrice(double? price) {
    if (price == null) return 'ไม่ระบุราคา';
    final formatter = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    return formatter.format(price);
  }

  Color _powertrainColor(String type) {
    switch (type.toLowerCase()) {
      case 'bev':
        return const Color(0xFF4CAF50);
      case 'phev':
        return const Color(0xFF2196F3);
      case 'hev':
        return const Color(0xFF009688);
      case 'ice':
        return const Color(0xFF795548);
      default:
        return Colors.grey;
    }
  }

  Widget _buildPriceResultItem(CarSearchResult result) {
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  Text(
                    result.variantName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
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
                      if (result.rangeKm != null && (result.powertrainType.toUpperCase() == 'BEV' || result.powertrainType.toUpperCase() == 'PHEV'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '\u26A1 ${result.rangeKm} km',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (result.fuelConsumptionKml != null && (result.powertrainType.toUpperCase() == 'ICE' || result.powertrainType.toUpperCase() == 'HEV'))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF795548).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '\u26FD ${result.fuelConsumptionKml!.toStringAsFixed(1)} km/L',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF795548), fontWeight: FontWeight.w600),
                          ),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF795548)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF3E2723),
              fontWeight: FontWeight.w600,
            ),
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

// Search delegate
class _CarSearchDelegate extends SearchDelegate<int?> {
  final ApiService _apiService;

  _CarSearchDelegate(this._apiService)
      : super(
          searchFieldLabel: 'ค้นหารถยนต์...',
          searchFieldStyle: const TextStyle(fontSize: 16),
        );

  String _formatPrice(double? price) {
    if (price == null) return 'ไม่ระบุราคา';
    final formatter = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    return formatter.format(price);
  }

  Color _powertrainColor(String type) {
    switch (type.toLowerCase()) {
      case 'bev':
        return const Color(0xFF4CAF50);
      case 'phev':
        return const Color(0xFF2196F3);
      case 'hev':
        return const Color(0xFF009688);
      case 'ice':
        return const Color(0xFF795548);
      default:
        return Colors.grey;
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
  Widget buildResults(BuildContext context) {
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
    return FutureBuilder<List<CarSearchResult>>(
      future: _apiService.searchCars(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF795548)));
        }
        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Text('ไม่พบผลลัพธ์', style: TextStyle(color: Colors.grey.shade400)),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                  Text(
                    result.variantName,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
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
