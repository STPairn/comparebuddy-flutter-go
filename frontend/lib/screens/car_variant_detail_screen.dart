import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/car.dart';
import '../services/api_service.dart';
import 'car_compare_screen.dart';

class CarVariantDetailScreen extends StatefulWidget {
  final int variantId;

  const CarVariantDetailScreen({Key? key, required this.variantId}) : super(key: key);

  @override
  State<CarVariantDetailScreen> createState() => _CarVariantDetailScreenState();
}

class _CarVariantDetailScreenState extends State<CarVariantDetailScreen> {
  final ApiService _apiService = ApiService();
  CarVariant? _variant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVariant();
  }

  Future<void> _loadVariant() async {
    final variant = await _apiService.getCarVariantById(widget.variantId);
    setState(() {
      _variant = variant;
      _isLoading = false;
    });
  }

  String _formatPrice(double? price) {
    if (price == null) return 'ไม่ระบุราคา';
    final formatter = NumberFormat.currency(locale: 'th_TH', symbol: '฿', decimalDigits: 0);
    return formatter.format(price);
  }

  String _boolText(bool? value) {
    if (value == null) return '-';
    return value ? 'มี' : 'ไม่มี';
  }

  Color _powertrainColor(String? type) {
    switch (type?.toLowerCase()) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E2723),
        title: Text(
          _variant?.fullName ?? 'รายละเอียดรถ',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF795548)))
          : _variant == null
              ? const Center(child: Text('ไม่พบข้อมูล'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildGeneralSection(),
                            if (_isElectric || _isHybrid) _buildElectricSection(),
                            if (_isICE || _isHybrid) _buildEngineSection(),
                            if (_isHybrid) _buildHybridSection(),
                            _buildPerformanceSection(),
                            _buildDimensionsSection(),
                            _buildDriveSection(),
                            _buildSafetySection(),
                            _buildAdasSection(),
                            _buildComfortSection(),
                            _buildInfotainmentSection(),
                            _buildExteriorSection(),
                            _buildWarrantySection(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _variant != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CarCompareScreen(variantIds: [widget.variantId]),
                      ),
                    );
                  },
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('เพิ่มเข้าเปรียบเทียบ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF795548),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  bool get _isElectric => _variant?.powertrainType?.toLowerCase() == 'bev';
  bool get _isHybrid {
    final pt = _variant?.powertrainType?.toLowerCase();
    return pt == 'phev' || pt == 'hev';
  }
  bool get _isICE => _variant?.powertrainType?.toLowerCase() == 'ice';

  Widget _buildHeader() {
    final v = _variant!;
    final color = _powertrainColor(v.powertrainType);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3E2723), Color(0xFF4E342E)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${v.brandName ?? ''} ${v.modelName ?? ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            v.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatPrice(v.priceBaht),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  v.powertrainType?.toUpperCase() ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (v.bodyType != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    v.bodyType!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<_SpecRow> specs) {
    // Filter out rows with null values
    final validSpecs = specs.where((s) => s.value != '-' && s.value.isNotEmpty).toList();
    if (validSpecs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(icon, size: 20, color: const Color(0xFF795548)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3E2723),
          ),
        ),
        children: validSpecs.map((spec) => _buildSpecRow(spec)).toList(),
      ),
    );
  }

  Widget _buildSpecRow(_SpecRow spec) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              spec.label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              spec.value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF3E2723)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    final v = _variant!;
    return _buildSection('ข้อมูลทั่วไป', Icons.info_outline, [
      _SpecRow('ราคา', _formatPrice(v.priceBaht)),
      _SpecRow('สถานะ', v.status == 'active' ? 'จำหน่ายอยู่' : v.status),
      _SpecRow('ประเภทขุมพลัง', v.powertrainType?.toUpperCase() ?? '-'),
      _SpecRow('ประเภทตัวถัง', v.bodyType ?? '-'),
    ]);
  }

  Widget _buildElectricSection() {
    final v = _variant!;
    return _buildSection('ไฟฟ้า / แบตเตอรี่', Icons.battery_charging_full, [
      _SpecRow('ความจุแบตเตอรี่', v.batteryCapacityKwh != null ? '${v.batteryCapacityKwh} kWh' : '-'),
      _SpecRow('ประเภทแบตเตอรี่', v.batteryType ?? '-'),
      _SpecRow('กำลังมอเตอร์', v.motorPowerKw != null ? '${v.motorPowerKw} kW' : '-'),
      _SpecRow('แรงบิดมอเตอร์', v.motorTorqueNm != null ? '${v.motorTorqueNm} Nm' : '-'),
      _SpecRow('มอเตอร์หน้า', v.frontMotorKw != null ? '${v.frontMotorKw} kW' : '-'),
      _SpecRow('มอเตอร์หลัง', v.rearMotorKw != null ? '${v.rearMotorKw} kW' : '-'),
      _SpecRow('ระยะวิ่ง', v.rangeKm != null ? '${v.rangeKm} km' : '-'),
      _SpecRow('มาตรฐานระยะวิ่ง', v.rangeStandard ?? '-'),
      _SpecRow('ชาร์จ AC', v.acChargeKw != null ? '${v.acChargeKw} kW' : '-'),
      _SpecRow('ชาร์จ DC', v.dcChargeKw != null ? '${v.dcChargeKw} kW' : '-'),
      _SpecRow('เวลาชาร์จ AC', v.acChargeTimeHrs != null ? '${v.acChargeTimeHrs} ชม.' : '-'),
      _SpecRow('เวลาชาร์จ DC', v.dcChargeTimeMins != null ? '${v.dcChargeTimeMins} นาที' : '-'),
      _SpecRow('พอร์ตชาร์จ', v.chargingPort ?? '-'),
      _SpecRow('V2L', _boolText(v.v2l)),
      _SpecRow('V2G', _boolText(v.v2g)),
      _SpecRow('Heat Pump', _boolText(v.heatPump)),
      _SpecRow('Battery Preconditioning', _boolText(v.batteryPreconditioning)),
    ]);
  }

  Widget _buildEngineSection() {
    final v = _variant!;
    return _buildSection('เครื่องยนต์', Icons.local_gas_station, [
      _SpecRow('ความจุเครื่องยนต์', v.displacementCc != null ? '${v.displacementCc} cc' : '-'),
      _SpecRow('ประเภทเครื่องยนต์', v.engineType ?? '-'),
      _SpecRow('แรงม้า', v.horsepower != null ? '${v.horsepower} hp' : '-'),
      _SpecRow('แรงบิด', v.engineTorqueNm != null ? '${v.engineTorqueNm} Nm' : '-'),
      _SpecRow('เชื้อเพลิง', v.fuelType ?? '-'),
      _SpecRow('ถังเชื้อเพลิง', v.fuelTankLiters != null ? '${v.fuelTankLiters} ลิตร' : '-'),
      _SpecRow('อัตราสิ้นเปลือง', v.fuelConsumptionKml != null ? '${v.fuelConsumptionKml} km/l' : '-'),
      _SpecRow('เทอร์โบ', _boolText(v.turbo)),
      _SpecRow('เกียร์', v.transmission ?? '-'),
      _SpecRow('จำนวนเกียร์', v.transmissionSpeeds != null ? '${v.transmissionSpeeds} สปีด' : '-'),
    ]);
  }

  Widget _buildHybridSection() {
    final v = _variant!;
    return _buildSection('ระบบไฮบริด', Icons.electrical_services, [
      _SpecRow('กำลังรวมระบบ', v.systemPowerHp != null ? '${v.systemPowerHp} hp' : '-'),
      _SpecRow('แรงบิดรวมระบบ', v.systemTorqueNm != null ? '${v.systemTorqueNm} Nm' : '-'),
      _SpecRow('ระยะวิ่ง EV', v.evRangeKm != null ? '${v.evRangeKm} km' : '-'),
    ]);
  }

  Widget _buildPerformanceSection() {
    final v = _variant!;
    return _buildSection('สมรรถนะ', Icons.speed, [
      _SpecRow('ความเร็วสูงสุด', v.topSpeedKmh != null ? '${v.topSpeedKmh} km/h' : '-'),
      _SpecRow('0-100 km/h', v.acceleration0100 != null ? '${v.acceleration0100} วินาที' : '-'),
    ]);
  }

  Widget _buildDimensionsSection() {
    final v = _variant!;
    return _buildSection('ขนาดตัวถัง', Icons.straighten, [
      _SpecRow('ยาว', v.lengthMm != null ? '${v.lengthMm} mm' : '-'),
      _SpecRow('กว้าง', v.widthMm != null ? '${v.widthMm} mm' : '-'),
      _SpecRow('สูง', v.heightMm != null ? '${v.heightMm} mm' : '-'),
      _SpecRow('ฐานล้อ', v.wheelbaseMm != null ? '${v.wheelbaseMm} mm' : '-'),
      _SpecRow('ความสูงจากพื้น', v.groundClearanceMm != null ? '${v.groundClearanceMm} mm' : '-'),
      _SpecRow('น้ำหนักรถเปล่า', v.curbWeightKg != null ? '${v.curbWeightKg} kg' : '-'),
      _SpecRow('น้ำหนักรวม', v.grossWeightKg != null ? '${v.grossWeightKg} kg' : '-'),
      _SpecRow('ห้องสัมภาระ', v.trunkCapacityLiters != null ? '${v.trunkCapacityLiters} ลิตร' : '-'),
      _SpecRow('ห้องสัมภาระ (สูงสุด)', v.trunkMaxLiters != null ? '${v.trunkMaxLiters} ลิตร' : '-'),
      _SpecRow('Frunk', v.frunkCapacityLiters != null ? '${v.frunkCapacityLiters} ลิตร' : '-'),
    ]);
  }

  Widget _buildDriveSection() {
    final v = _variant!;
    return _buildSection('ระบบขับเคลื่อน', Icons.settings, [
      _SpecRow('ระบบขับเคลื่อน', v.driveType ?? '-'),
      _SpecRow('ช่วงล่างหน้า', v.frontSuspension ?? '-'),
      _SpecRow('ช่วงล่างหลัง', v.rearSuspension ?? '-'),
      _SpecRow('เบรคหน้า', v.frontBrakes ?? '-'),
      _SpecRow('เบรคหลัง', v.rearBrakes ?? '-'),
      _SpecRow('ยางหน้า', v.tireSizeFront ?? '-'),
      _SpecRow('ยางหลัง', v.tireSizeRear ?? '-'),
      _SpecRow('ยางอะไหล่', v.spareTire ?? '-'),
    ]);
  }

  Widget _buildSafetySection() {
    final v = _variant!;
    return _buildSection('ความปลอดภัย', Icons.shield, [
      _SpecRow('ถุงลมนิรภัย', v.airbags != null ? '${v.airbags} ใบ' : '-'),
      _SpecRow('ABS', _boolText(v.abs)),
      _SpecRow('ESC', _boolText(v.esc)),
      _SpecRow('Traction Control', _boolText(v.tractionControl)),
      _SpecRow('Hill Start Assist', _boolText(v.hillStartAssist)),
      _SpecRow('Hill Descent Control', _boolText(v.hillDescentControl)),
      _SpecRow('TPMS', _boolText(v.tpms)),
      _SpecRow('ISOFIX', _boolText(v.isofix)),
      _SpecRow('เซ็นเซอร์จอดรถหน้า', _boolText(v.parkingSensorFront)),
      _SpecRow('เซ็นเซอร์จอดรถหลัง', _boolText(v.parkingSensorRear)),
      _SpecRow('กล้องถอยหลัง', _boolText(v.cameraRear)),
      _SpecRow('กล้อง 360 องศา', _boolText(v.camera360)),
      _SpecRow('ระบบช่วยจอด', _boolText(v.autoParking)),
      if (v.ncapRating != null) _SpecRow('NCAP Rating', '${v.ncapRating} ดาว'),
      _SpecRow('NCAP Body', v.ncapBody ?? '-'),
      if (v.ncapYear != null) _SpecRow('NCAP Year', '${v.ncapYear}'),
    ]);
  }

  Widget _buildAdasSection() {
    final v = _variant!;
    return _buildSection('ADAS', Icons.remove_red_eye, [
      _SpecRow('AEB (เบรคอัตโนมัติ)', _boolText(v.aeb)),
      _SpecRow('FCW (เตือนชนด้านหน้า)', _boolText(v.fcw)),
      _SpecRow('LKA (ช่วยคุมเลน)', _boolText(v.lka)),
      _SpecRow('LDW (เตือนออกเลน)', _boolText(v.ldw)),
      _SpecRow('BSD (เตือนจุดบอด)', _boolText(v.bsd)),
      _SpecRow('RCTA (เตือนรถตัดถอยหลัง)', _boolText(v.rcta)),
      _SpecRow('ACC (ครูซคอนโทรล)', _boolText(v.acc)),
      _SpecRow('ACC Stop & Go', _boolText(v.accStopGo)),
      _SpecRow('Driver Monitoring', v.driverMonitoring ?? '-'),
      _SpecRow('จดจำป้ายจราจร', _boolText(v.trafficSignRecognition)),
      _SpecRow('Night Vision', _boolText(v.nightVision)),
      _SpecRow('ระดับ ADAS', v.adasLevel ?? '-'),
    ]);
  }

  Widget _buildComfortSection() {
    final v = _variant!;
    return _buildSection('ความสะดวกสบาย', Icons.airline_seat_recline_extra, [
      _SpecRow('จำนวนที่นั่ง', v.seats != null ? '${v.seats} ที่นั่ง' : '-'),
      _SpecRow('วัสดุเบาะ', v.seatMaterial ?? '-'),
      _SpecRow('เบาะคนขับไฟฟ้า', _boolText(v.driverSeatElectric)),
      _SpecRow('เบาะผู้โดยสารไฟฟ้า', _boolText(v.passengerSeatElectric)),
      _SpecRow('Memory เบาะคนขับ', _boolText(v.driverSeatMemory)),
      _SpecRow('เบาะหน้าระบายอากาศ', _boolText(v.ventilatedSeatsFront)),
      _SpecRow('เบาะหลังระบายอากาศ', _boolText(v.ventilatedSeatsRear)),
      _SpecRow('เบาะหน้าอุ่น', _boolText(v.heatedSeatsFront)),
      _SpecRow('เบาะหลังอุ่น', _boolText(v.heatedSeatsRear)),
      _SpecRow('เบาะหลังปรับเอน', _boolText(v.rearSeatRecline)),
      _SpecRow('โซนแอร์', v.acZones != null ? '${v.acZones} โซน' : '-'),
      _SpecRow('ช่องแอร์หลัง', _boolText(v.rearAcVents)),
    ]);
  }

  Widget _buildInfotainmentSection() {
    final v = _variant!;
    return _buildSection('ระบบมัลติมีเดีย', Icons.smart_display, [
      _SpecRow('หน้าจอ', v.screenSizeInch != null ? '${v.screenSizeInch} นิ้ว' : '-'),
      _SpecRow('ประเภทจอ', v.screenType ?? '-'),
      _SpecRow('Digital Cluster', _boolText(v.digitalCluster)),
      _SpecRow('Cluster', v.clusterSizeInch != null ? '${v.clusterSizeInch} นิ้ว' : '-'),
      _SpecRow('HUD', _boolText(v.hud)),
      _SpecRow('ลำโพง', v.speakerBrand ?? '-'),
      _SpecRow('จำนวนลำโพง', v.speakerCount != null ? '${v.speakerCount} ตัว' : '-'),
      _SpecRow('Apple CarPlay', _boolText(v.appleCarplay)),
      _SpecRow('Android Auto', _boolText(v.androidAuto)),
      _SpecRow('Wireless CarPlay', _boolText(v.wirelessCarplay)),
      _SpecRow('Wireless Android Auto', _boolText(v.wirelessAndroidAuto)),
      _SpecRow('ชาร์จไร้สาย', _boolText(v.wirelessPhoneCharging)),
      _SpecRow('USB-C', v.usbCPorts != null ? '${v.usbCPorts} พอร์ต' : '-'),
      _SpecRow('USB-A', v.usbAPorts != null ? '${v.usbAPorts} พอร์ต' : '-'),
      _SpecRow('Bluetooth', v.bluetooth ?? '-'),
      _SpecRow('OTA Update', _boolText(v.otaUpdate)),
    ]);
  }

  Widget _buildExteriorSection() {
    final v = _variant!;
    return _buildSection('ภายนอก', Icons.wb_sunny, [
      _SpecRow('ไฟหน้า', v.headlightType ?? '-'),
      _SpecRow('DRL', _boolText(v.drl)),
      _SpecRow('ไฟหน้าอัตโนมัติ', _boolText(v.autoHeadlights)),
      _SpecRow('Adaptive Headlights', _boolText(v.adaptiveHeadlights)),
      _SpecRow('ไฟตัดหมอก', _boolText(v.fogLights)),
      _SpecRow('ซันรูฟ', v.sunroof ?? '-'),
      _SpecRow('ท้ายเปิดไฟฟ้า', _boolText(v.powerTailgate)),
      _SpecRow('Hands-free Tailgate', _boolText(v.handsFreeTailgate)),
      _SpecRow('Keyless Entry', _boolText(v.keylessEntry)),
      _SpecRow('Push Start', _boolText(v.pushStart)),
      _SpecRow('กระจกพับอัตโนมัติ', _boolText(v.autoFoldingMirrors)),
      _SpecRow('ที่ปัดน้ำฝนอัตโนมัติ', _boolText(v.rainSensingWipers)),
      _SpecRow('ราวหลังคา', _boolText(v.roofRails)),
    ]);
  }

  Widget _buildWarrantySection() {
    final v = _variant!;
    return _buildSection('การรับประกัน', Icons.verified_user, [
      _SpecRow('รับประกันตัวรถ', v.warrantyYears != null ? '${v.warrantyYears} ปี' : '-'),
      _SpecRow('รับประกันระยะทาง', v.warrantyKm != null ? '${NumberFormat('#,###').format(v.warrantyKm)} km' : '-'),
      _SpecRow('รับประกันแบตเตอรี่', v.batteryWarrantyYears != null ? '${v.batteryWarrantyYears} ปี' : '-'),
      _SpecRow('รับประกันแบตฯ ระยะทาง', v.batteryWarrantyKm != null ? '${NumberFormat('#,###').format(v.batteryWarrantyKm)} km' : '-'),
    ]);
  }
}

class _SpecRow {
  final String label;
  final String value;
  _SpecRow(this.label, this.value);
}
