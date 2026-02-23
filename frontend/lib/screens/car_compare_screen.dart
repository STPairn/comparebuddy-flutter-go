import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/car.dart';
import '../services/api_service.dart';

class CarCompareScreen extends StatefulWidget {
  final List<int> variantIds;

  const CarCompareScreen({Key? key, required this.variantIds}) : super(key: key);

  @override
  State<CarCompareScreen> createState() => _CarCompareScreenState();
}

class _CarCompareScreenState extends State<CarCompareScreen> {
  final ApiService _apiService = ApiService();
  List<CarVariant> _variants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    if (widget.variantIds.length >= 2) {
      final variants = await _apiService.compareCarVariants(widget.variantIds);
      setState(() {
        _variants = variants;
        _isLoading = false;
      });
    } else if (widget.variantIds.length == 1) {
      // Single variant — just load it
      final variant = await _apiService.getCarVariantById(widget.variantIds[0]);
      setState(() {
        if (variant != null) _variants = [variant];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // sync prefs ทันที — รับประกันว่า parent อ่านได้ถูกต้องเสมอ
  Future<void> _syncPendingPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_variants.isEmpty) {
      await prefs.remove('pending_comparison_ids');
      await prefs.remove('pending_comparison_labels');
      return;
    }
    final remainingIds = _variants.map((v) => v.id).toList();
    await prefs.setString('pending_comparison_ids', json.encode(remainingIds));
    final labelsJson = prefs.getString('pending_comparison_labels');
    if (labelsJson != null) {
      final raw = json.decode(labelsJson) as Map<String, dynamic>;
      final keepKeys = remainingIds.map((id) => id.toString()).toSet();
      raw.removeWhere((key, _) => !keepKeys.contains(key));
      await prefs.setString('pending_comparison_labels', json.encode(raw));
    }
  }

  Future<void> _removeVariant(int variantId) async {
    setState(() => _variants.removeWhere((v) => v.id == variantId));
    // รอ write prefs ให้เสร็จก่อน pop เสมอ
    await _syncPendingPrefs();
    if (_variants.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatPrice(double? price) {
    if (price == null) return '-';
    final formatter = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    return formatter.format(price);
  }

  String _boolText(bool? value) {
    if (value == null) return '-';
    return value ? 'มี' : 'ไม่มี';
  }

  String _numText(num? value, [String suffix = '']) {
    if (value == null) return '-';
    return '$value$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E2723),
        title: Text(
          'เปรียบเทียบ ${_variants.length} คัน',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF795548)))
          : _variants.isEmpty
              ? const Center(child: Text('ไม่พบข้อมูล'))
              : _buildCompareTable(),
    );
  }

  Widget _buildCompareTable() {
    final labelWidth = 130.0;
    final colWidth = 150.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with car names — horizontally scrollable
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: labelWidth),
                ..._variants.map((v) => _buildCarHeader(
                      v,
                      colWidth,
                      canRemove: _variants.length > 1,
                      onRemove: () => _removeVariant(v.id),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          // Spec sections
          _buildCompareSection('ข้อมูลทั่วไป', Icons.info_outline, labelWidth, colWidth, [
            _CompareRow('ราคา', _variants.map((v) => _formatPrice(v.priceBaht)).toList(),
                highlightLowest: true, values: _variants.map((v) => v.priceBaht).toList()),
            _CompareRow('สถานะ', _variants.map((v) => v.status == 'active' ? 'จำหน่าย' : v.status).toList()),
            _CompareRow('ขุมพลัง', _variants.map((v) => v.powertrainType?.toUpperCase() ?? '-').toList()),
            _CompareRow('ตัวถัง', _variants.map((v) => v.bodyType ?? '-').toList()),
          ]),
          _buildCompareSection('ไฟฟ้า / แบตเตอรี่', Icons.battery_charging_full, labelWidth, colWidth, [
            _CompareRow('แบตเตอรี่', _variants.map((v) => _numText(v.batteryCapacityKwh, ' kWh')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.batteryCapacityKwh?.toDouble()).toList()),
            _CompareRow('ประเภทแบต', _variants.map((v) => v.batteryType ?? '-').toList(), highlightNotNone: true),
            _CompareRow('มอเตอร์', _variants.map((v) => _numText(v.motorPowerKw, ' kW')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.motorPowerKw?.toDouble()).toList()),
            _CompareRow('แรงบิดมอเตอร์', _variants.map((v) => _numText(v.motorTorqueNm, ' Nm')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.motorTorqueNm?.toDouble()).toList()),
            _CompareRow('ระยะวิ่ง', _variants.map((v) => _numText(v.rangeKm, ' km')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.rangeKm?.toDouble()).toList()),
            _CompareRow('ชาร์จ AC', _variants.map((v) => _numText(v.acChargeKw, ' kW')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.acChargeKw?.toDouble()).toList()),
            _CompareRow('ชาร์จ DC', _variants.map((v) => _numText(v.dcChargeKw, ' kW')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.dcChargeKw?.toDouble()).toList()),
            _CompareRow('เวลาชาร์จ DC', _variants.map((v) => _numText(v.dcChargeTimeMins, ' นาที')).toList(),
                highlightLowest: true, values: _variants.map((v) => v.dcChargeTimeMins?.toDouble()).toList()),
            _CompareRow('พอร์ตชาร์จ', _variants.map((v) => v.chargingPort ?? '-').toList(), highlightNotNone: true),
            _CompareRow('V2L', _variants.map((v) => _boolText(v.v2l)).toList(), highlightBool: true),
            _CompareRow('V2G', _variants.map((v) => _boolText(v.v2g)).toList(), highlightBool: true),
            _CompareRow('Heat Pump', _variants.map((v) => _boolText(v.heatPump)).toList(), highlightBool: true),
          ]),
          _buildCompareSection('เครื่องยนต์', Icons.local_gas_station, labelWidth, colWidth, [
            _CompareRow('ความจุ', _variants.map((v) => _numText(v.displacementCc, ' cc')).toList()),
            _CompareRow('แรงม้า', _variants.map((v) => _numText(v.horsepower, ' hp')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.horsepower?.toDouble()).toList()),
            _CompareRow('แรงบิด', _variants.map((v) => _numText(v.engineTorqueNm, ' Nm')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.engineTorqueNm?.toDouble()).toList()),
            _CompareRow('เชื้อเพลิง', _variants.map((v) => v.fuelType ?? '-').toList()),
            _CompareRow('อัตราสิ้นเปลือง', _variants.map((v) => _numText(v.fuelConsumptionKml, ' km/l')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.fuelConsumptionKml?.toDouble()).toList()),
            _CompareRow('เทอร์โบ', _variants.map((v) => _boolText(v.turbo)).toList(), highlightBool: true),
            _CompareRow('เกียร์', _variants.map((v) => v.transmission ?? '-').toList()),
          ]),
          _buildCompareSection('สมรรถนะ', Icons.speed, labelWidth, colWidth, [
            _CompareRow('ความเร็วสูงสุด', _variants.map((v) => _numText(v.topSpeedKmh, ' km/h')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.topSpeedKmh?.toDouble()).toList()),
            _CompareRow('0-100', _variants.map((v) => _numText(v.acceleration0100, ' วิ')).toList(),
                highlightLowest: true, values: _variants.map((v) => v.acceleration0100).toList()),
          ]),
          _buildCompareSection('ขนาด', Icons.straighten, labelWidth, colWidth, [
            _CompareRow('ยาว', _variants.map((v) => _numText(v.lengthMm, ' mm')).toList()),
            _CompareRow('กว้าง', _variants.map((v) => _numText(v.widthMm, ' mm')).toList()),
            _CompareRow('สูง', _variants.map((v) => _numText(v.heightMm, ' mm')).toList()),
            _CompareRow('ฐานล้อ', _variants.map((v) => _numText(v.wheelbaseMm, ' mm')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.wheelbaseMm?.toDouble()).toList()),
            _CompareRow('ความสูงจากพื้น', _variants.map((v) => _numText(v.groundClearanceMm, ' mm')).toList()),
            _CompareRow('น้ำหนัก', _variants.map((v) => _numText(v.curbWeightKg, ' kg')).toList(),
                highlightLowest: true, values: _variants.map((v) => v.curbWeightKg?.toDouble()).toList()),
            _CompareRow('สัมภาระ', _variants.map((v) => _numText(v.trunkCapacityLiters, ' L')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.trunkCapacityLiters?.toDouble()).toList()),
          ]),
          _buildCompareSection('ระบบขับเคลื่อน', Icons.settings, labelWidth, colWidth, [
            _CompareRow('ระบบขับเคลื่อน', _variants.map((v) => v.driveType ?? '-').toList()),
            _CompareRow('ช่วงล่างหน้า', _variants.map((v) => v.frontSuspension ?? '-').toList()),
            _CompareRow('ช่วงล่างหลัง', _variants.map((v) => v.rearSuspension ?? '-').toList()),
            _CompareRow('ยางหน้า', _variants.map((v) => v.tireSizeFront ?? '-').toList()),
            _CompareRow('ยางหลัง', _variants.map((v) => v.tireSizeRear ?? '-').toList()),
          ]),
          _buildCompareSection('ความปลอดภัย', Icons.shield, labelWidth, colWidth, [
            _CompareRow('ถุงลม', _variants.map((v) => _numText(v.airbags, ' ใบ')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.airbags?.toDouble()).toList()),
            _CompareRow('ABS', _variants.map((v) => _boolText(v.abs)).toList(), highlightBool: true),
            _CompareRow('ESC', _variants.map((v) => _boolText(v.esc)).toList(), highlightBool: true),
            _CompareRow('กล้อง 360', _variants.map((v) => _boolText(v.camera360)).toList(), highlightBool: true),
            _CompareRow('ช่วยจอด', _variants.map((v) => _boolText(v.autoParking)).toList(), highlightBool: true),
            _CompareRow('ISOFIX', _variants.map((v) => _boolText(v.isofix)).toList(), highlightBool: true),
            if (_variants.any((v) => v.ncapRating != null))
              _CompareRow('NCAP', _variants.map((v) => v.ncapRating != null ? '${v.ncapRating} ดาว' : '-').toList(),
                  highlightHighest: true, values: _variants.map((v) => v.ncapRating?.toDouble()).toList()),
          ]),
          _buildCompareSection('ADAS', Icons.remove_red_eye, labelWidth, colWidth, [
            _CompareRow('AEB', _variants.map((v) => _boolText(v.aeb)).toList(), highlightBool: true),
            _CompareRow('LKA', _variants.map((v) => _boolText(v.lka)).toList(), highlightBool: true),
            _CompareRow('BSD', _variants.map((v) => _boolText(v.bsd)).toList(), highlightBool: true),
            _CompareRow('ACC', _variants.map((v) => _boolText(v.acc)).toList(), highlightBool: true),
            _CompareRow('ACC Stop&Go', _variants.map((v) => _boolText(v.accStopGo)).toList(), highlightBool: true),
            _CompareRow('ADAS Level', _variants.map((v) => v.adasLevel ?? '-').toList(), highlightNotNone: true),
          ]),
          _buildCompareSection('ความสะดวก', Icons.airline_seat_recline_extra, labelWidth, colWidth, [
            _CompareRow('ที่นั่ง', _variants.map((v) => _numText(v.seats)).toList(),
                highlightHighest: true, values: _variants.map((v) => v.seats?.toDouble()).toList()),
            _CompareRow('วัสดุเบาะ', _variants.map((v) => v.seatMaterial ?? '-').toList(), highlightNotNone: true),
            _CompareRow('เบาะไฟฟ้าคนขับ', _variants.map((v) => _boolText(v.driverSeatElectric)).toList(), highlightBool: true),
            _CompareRow('เบาะระบายอากาศ', _variants.map((v) => _boolText(v.ventilatedSeatsFront)).toList(), highlightBool: true),
            _CompareRow('เบาะอุ่น', _variants.map((v) => _boolText(v.heatedSeatsFront)).toList(), highlightBool: true),
            _CompareRow('โซนแอร์', _variants.map((v) => _numText(v.acZones)).toList(),
                highlightHighest: true, values: _variants.map((v) => v.acZones?.toDouble()).toList()),
          ]),
          _buildCompareSection('มัลติมีเดีย', Icons.smart_display, labelWidth, colWidth, [
            _CompareRow('หน้าจอ', _variants.map((v) => _numText(v.screenSizeInch, '"')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.screenSizeInch?.toDouble()).toList()),
            _CompareRow('HUD', _variants.map((v) => _boolText(v.hud)).toList(), highlightBool: true),
            _CompareRow('ลำโพง', _variants.map((v) => v.speakerBrand ?? '-').toList(), highlightNotNone: true),
            _CompareRow('จำนวนลำโพง', _variants.map((v) => _numText(v.speakerCount)).toList(),
                highlightHighest: true, values: _variants.map((v) => v.speakerCount?.toDouble()).toList()),
            _CompareRow('CarPlay', _variants.map((v) => _boolText(v.appleCarplay)).toList(), highlightBool: true),
            _CompareRow('Android Auto', _variants.map((v) => _boolText(v.androidAuto)).toList(), highlightBool: true),
            _CompareRow('Wireless CarPlay', _variants.map((v) => _boolText(v.wirelessCarplay)).toList(), highlightBool: true),
            _CompareRow('ชาร์จไร้สาย', _variants.map((v) => _boolText(v.wirelessPhoneCharging)).toList(), highlightBool: true),
            _CompareRow('OTA', _variants.map((v) => _boolText(v.otaUpdate)).toList(), highlightBool: true),
          ]),
          _buildCompareSection('ภายนอก', Icons.wb_sunny, labelWidth, colWidth, [
            _CompareRow('ไฟหน้า', _variants.map((v) => v.headlightType ?? '-').toList(), highlightNotNone: true),
            _CompareRow('ซันรูฟ', _variants.map((v) => v.sunroof ?? '-').toList(), highlightNotNone: true),
            _CompareRow('ท้ายไฟฟ้า', _variants.map((v) => _boolText(v.powerTailgate)).toList(), highlightBool: true),
            _CompareRow('Keyless', _variants.map((v) => _boolText(v.keylessEntry)).toList(), highlightBool: true),
          ]),
          _buildCompareSection('การรับประกัน', Icons.verified_user, labelWidth, colWidth, [
            _CompareRow('รับประกัน', _variants.map((v) => _numText(v.warrantyYears, ' ปี')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.warrantyYears?.toDouble()).toList()),
            _CompareRow('ระยะทาง', _variants.map((v) => v.warrantyKm != null ? '${NumberFormat('#,###').format(v.warrantyKm)} km' : '-').toList(),
                highlightHighest: true, values: _variants.map((v) => v.warrantyKm?.toDouble()).toList()),
            _CompareRow('แบตเตอรี่', _variants.map((v) => _numText(v.batteryWarrantyYears, ' ปี')).toList(),
                highlightHighest: true, values: _variants.map((v) => v.batteryWarrantyYears?.toDouble()).toList()),
          ]),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCarHeader(
    CarVariant v,
    double width, {
    bool canRemove = true,
    Future<void> Function()? onRemove,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3E2723), Color(0xFF4E342E)],
        ),
      ),
      child: Column(
        children: [
          // Remove button row
          Align(
            alignment: Alignment.centerRight,
            child: canRemove
                ? GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 14),
                    ),
                  )
                : const SizedBox(height: 20),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            v.brandName ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          Text(
            '${v.modelName ?? ''}\n${v.name}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatPrice(v.priceBaht),
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompareSection(
      String title, IconData icon, double labelWidth, double colWidth, List<_CompareRow> rows) {
    // Filter out rows where all values are '-'
    final validRows = rows.where((r) => r.texts.any((t) => t != '-')).toList();
    if (validRows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFFAF6F3),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF795548)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3E2723),
                ),
              ),
            ],
          ),
        ),
        ...validRows.map((row) => _buildCompareRow(row, labelWidth, colWidth)),
      ],
    );
  }

  Widget _buildCompareRow(_CompareRow row, double labelWidth, double colWidth) {
    Set<int> highlightIndices = {};

    if (row.highlightBool) {
      // highlight "มี" เฉพาะเมื่อไม่ใช่ทุกคันเท่ากัน
      for (int i = 0; i < row.texts.length; i++) {
        if (row.texts[i] == 'มี') highlightIndices.add(i);
      }
    } else if (row.highlightNotNone) {
      // highlight ค่าที่ไม่ใช่ '-' เฉพาะเมื่อบางคันเป็น '-'
      for (int i = 0; i < row.texts.length; i++) {
        if (row.texts[i] != '-') highlightIndices.add(i);
      }
    } else if (row.values != null) {
      final numericValues = row.values!;
      if (row.highlightHighest) {
        double? best;
        for (final v in numericValues) {
          if (v != null && (best == null || v > best)) best = v;
        }
        if (best != null) {
          for (int i = 0; i < numericValues.length; i++) {
            if (numericValues[i] == best) highlightIndices.add(i);
          }
        }
      } else if (row.highlightLowest) {
        double? best;
        for (final v in numericValues) {
          if (v != null && (best == null || v < best)) best = v;
        }
        if (best != null) {
          for (int i = 0; i < numericValues.length; i++) {
            if (numericValues[i] == best) highlightIndices.add(i);
          }
        }
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Container(
              width: labelWidth,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                row.label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            ...List.generate(row.texts.length, (i) {
              final isHighlighted = highlightIndices.contains(i) && highlightIndices.length < row.texts.length;
              return Container(
                width: colWidth,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: isHighlighted ? const Color(0xFF4CAF50).withOpacity(0.08) : null,
                child: Text(
                  row.texts[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                    color: isHighlighted ? const Color(0xFF2E7D32) : const Color(0xFF3E2723),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CompareRow {
  final String label;
  final List<String> texts;
  final bool highlightHighest;
  final bool highlightLowest;
  final bool highlightBool;    // highlight "มี" เมื่อไม่เท่ากันทุกคัน
  final bool highlightNotNone; // highlight ค่าที่ไม่ใช่ '-' เมื่อบางคันไม่มีข้อมูล
  final List<double?>? values;

  _CompareRow(
    this.label,
    this.texts, {
    this.highlightHighest = false,
    this.highlightLowest = false,
    this.highlightBool = false,
    this.highlightNotNone = false,
    this.values,
  });
}
