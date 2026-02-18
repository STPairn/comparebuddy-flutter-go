class CarBrand {
  final int id;
  final String name;
  final String? nameTh;
  final String? country;
  final String? logoUrl;

  CarBrand({
    required this.id,
    required this.name,
    this.nameTh,
    this.country,
    this.logoUrl,
  });

  factory CarBrand.fromJson(Map<String, dynamic> json) {
    return CarBrand(
      id: json['id'],
      name: json['name'],
      nameTh: json['name_th'],
      country: json['country'],
      logoUrl: json['logo_url'],
    );
  }
}

class CarModel {
  final int id;
  final int brandId;
  final String name;
  final String powertrainType;
  final String bodyType;
  final String segment;
  final int? yearLaunched;
  final String status;
  final String? brandName;

  CarModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.powertrainType,
    required this.bodyType,
    required this.segment,
    this.yearLaunched,
    required this.status,
    this.brandName,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'],
      brandId: json['brand_id'],
      name: json['name'],
      powertrainType: json['powertrain_type'],
      bodyType: json['body_type'],
      segment: json['segment'],
      yearLaunched: json['year_launched'],
      status: json['status'],
      brandName: json['brand_name'],
    );
  }
}

class CarVariantSummary {
  final int id;
  final int modelId;
  final String name;
  final double? priceBaht;
  final String status;

  CarVariantSummary({
    required this.id,
    required this.modelId,
    required this.name,
    this.priceBaht,
    required this.status,
  });

  factory CarVariantSummary.fromJson(Map<String, dynamic> json) {
    return CarVariantSummary(
      id: json['id'],
      modelId: json['model_id'],
      name: json['name'],
      priceBaht: (json['price_baht'] as num?)?.toDouble(),
      status: json['status'],
    );
  }
}

class CarVariant {
  // Basic Info
  final int id;
  final int modelId;
  final String name;
  final double? priceBaht;
  final String status;

  // Joined fields
  final String? brandName;
  final String? modelName;
  final String? powertrainType;
  final String? bodyType;

  // Electric / Battery
  final double? batteryCapacityKwh;
  final String? batteryType;
  final double? motorPowerKw;
  final double? motorTorqueNm;
  final double? frontMotorKw;
  final double? rearMotorKw;
  final int? rangeKm;
  final String? rangeStandard;
  final double? acChargeKw;
  final double? dcChargeKw;
  final double? acChargeTimeHrs;
  final int? dcChargeTimeMins;
  final String? chargingPort;
  final bool? v2l;
  final bool? v2g;
  final bool? heatPump;
  final bool? batteryPreconditioning;

  // Engine (ICE / Hybrid)
  final int? displacementCc;
  final String? engineType;
  final int? horsepower;
  final int? engineTorqueNm;
  final String? fuelType;
  final double? fuelTankLiters;
  final double? fuelConsumptionKml;
  final bool? turbo;
  final String? transmission;
  final int? transmissionSpeeds;

  // Combined (Hybrid)
  final int? systemPowerHp;
  final int? systemTorqueNm;
  final int? evRangeKm;

  // Performance
  final int? topSpeedKmh;
  final double? acceleration0100;

  // Dimensions
  final int? lengthMm;
  final int? widthMm;
  final int? heightMm;
  final int? wheelbaseMm;
  final int? groundClearanceMm;
  final int? curbWeightKg;
  final int? grossWeightKg;
  final int? trunkCapacityLiters;
  final int? trunkMaxLiters;
  final int? frunkCapacityLiters;

  // Drive
  final String? driveType;
  final String? frontSuspension;
  final String? rearSuspension;
  final String? frontBrakes;
  final String? rearBrakes;
  final String? tireSizeFront;
  final String? tireSizeRear;
  final String? spareTire;

  // Safety
  final int? airbags;
  final bool? abs;
  final bool? esc;
  final bool? tractionControl;
  final bool? hillStartAssist;
  final bool? hillDescentControl;
  final bool? tpms;
  final bool? isofix;
  final bool? parkingSensorFront;
  final bool? parkingSensorRear;
  final bool? cameraRear;
  final bool? camera360;
  final bool? autoParking;

  // ADAS
  final bool? aeb;
  final bool? fcw;
  final bool? lka;
  final bool? ldw;
  final bool? bsd;
  final bool? rcta;
  final bool? acc;
  final bool? accStopGo;
  final String? driverMonitoring;
  final bool? trafficSignRecognition;
  final bool? nightVision;
  final String? adasLevel;

  // NCAP
  final double? ncapRating;
  final String? ncapBody;
  final int? ncapYear;

  // Comfort
  final int? seats;
  final String? seatMaterial;
  final bool? driverSeatElectric;
  final bool? passengerSeatElectric;
  final bool? driverSeatMemory;
  final bool? ventilatedSeatsFront;
  final bool? ventilatedSeatsRear;
  final bool? heatedSeatsFront;
  final bool? heatedSeatsRear;
  final bool? rearSeatRecline;
  final int? acZones;
  final bool? rearAcVents;

  // Infotainment
  final double? screenSizeInch;
  final String? screenType;
  final bool? digitalCluster;
  final double? clusterSizeInch;
  final bool? hud;
  final String? speakerBrand;
  final int? speakerCount;
  final bool? appleCarplay;
  final bool? androidAuto;
  final bool? wirelessCarplay;
  final bool? wirelessAndroidAuto;
  final bool? wirelessPhoneCharging;
  final int? usbCPorts;
  final int? usbAPorts;
  final String? bluetooth;
  final bool? otaUpdate;

  // Exterior
  final String? headlightType;
  final bool? drl;
  final bool? autoHeadlights;
  final bool? adaptiveHeadlights;
  final bool? fogLights;
  final String? sunroof;
  final bool? powerTailgate;
  final bool? handsFreeTailgate;
  final bool? keylessEntry;
  final bool? pushStart;
  final bool? autoFoldingMirrors;
  final bool? rainSensingWipers;
  final bool? roofRails;

  // Warranty
  final int? warrantyYears;
  final int? warrantyKm;
  final int? batteryWarrantyYears;
  final int? batteryWarrantyKm;

  CarVariant({
    required this.id,
    required this.modelId,
    required this.name,
    this.priceBaht,
    required this.status,
    this.brandName,
    this.modelName,
    this.powertrainType,
    this.bodyType,
    this.batteryCapacityKwh,
    this.batteryType,
    this.motorPowerKw,
    this.motorTorqueNm,
    this.frontMotorKw,
    this.rearMotorKw,
    this.rangeKm,
    this.rangeStandard,
    this.acChargeKw,
    this.dcChargeKw,
    this.acChargeTimeHrs,
    this.dcChargeTimeMins,
    this.chargingPort,
    this.v2l,
    this.v2g,
    this.heatPump,
    this.batteryPreconditioning,
    this.displacementCc,
    this.engineType,
    this.horsepower,
    this.engineTorqueNm,
    this.fuelType,
    this.fuelTankLiters,
    this.fuelConsumptionKml,
    this.turbo,
    this.transmission,
    this.transmissionSpeeds,
    this.systemPowerHp,
    this.systemTorqueNm,
    this.evRangeKm,
    this.topSpeedKmh,
    this.acceleration0100,
    this.lengthMm,
    this.widthMm,
    this.heightMm,
    this.wheelbaseMm,
    this.groundClearanceMm,
    this.curbWeightKg,
    this.grossWeightKg,
    this.trunkCapacityLiters,
    this.trunkMaxLiters,
    this.frunkCapacityLiters,
    this.driveType,
    this.frontSuspension,
    this.rearSuspension,
    this.frontBrakes,
    this.rearBrakes,
    this.tireSizeFront,
    this.tireSizeRear,
    this.spareTire,
    this.airbags,
    this.abs,
    this.esc,
    this.tractionControl,
    this.hillStartAssist,
    this.hillDescentControl,
    this.tpms,
    this.isofix,
    this.parkingSensorFront,
    this.parkingSensorRear,
    this.cameraRear,
    this.camera360,
    this.autoParking,
    this.aeb,
    this.fcw,
    this.lka,
    this.ldw,
    this.bsd,
    this.rcta,
    this.acc,
    this.accStopGo,
    this.driverMonitoring,
    this.trafficSignRecognition,
    this.nightVision,
    this.adasLevel,
    this.ncapRating,
    this.ncapBody,
    this.ncapYear,
    this.seats,
    this.seatMaterial,
    this.driverSeatElectric,
    this.passengerSeatElectric,
    this.driverSeatMemory,
    this.ventilatedSeatsFront,
    this.ventilatedSeatsRear,
    this.heatedSeatsFront,
    this.heatedSeatsRear,
    this.rearSeatRecline,
    this.acZones,
    this.rearAcVents,
    this.screenSizeInch,
    this.screenType,
    this.digitalCluster,
    this.clusterSizeInch,
    this.hud,
    this.speakerBrand,
    this.speakerCount,
    this.appleCarplay,
    this.androidAuto,
    this.wirelessCarplay,
    this.wirelessAndroidAuto,
    this.wirelessPhoneCharging,
    this.usbCPorts,
    this.usbAPorts,
    this.bluetooth,
    this.otaUpdate,
    this.headlightType,
    this.drl,
    this.autoHeadlights,
    this.adaptiveHeadlights,
    this.fogLights,
    this.sunroof,
    this.powerTailgate,
    this.handsFreeTailgate,
    this.keylessEntry,
    this.pushStart,
    this.autoFoldingMirrors,
    this.rainSensingWipers,
    this.roofRails,
    this.warrantyYears,
    this.warrantyKm,
    this.batteryWarrantyYears,
    this.batteryWarrantyKm,
  });

  factory CarVariant.fromJson(Map<String, dynamic> json) {
    return CarVariant(
      id: json['id'],
      modelId: json['model_id'],
      name: json['name'],
      priceBaht: (json['price_baht'] as num?)?.toDouble(),
      status: json['status'],
      brandName: json['brand_name'],
      modelName: json['model_name'],
      powertrainType: json['powertrain_type'],
      bodyType: json['body_type'],
      batteryCapacityKwh: (json['battery_capacity_kwh'] as num?)?.toDouble(),
      batteryType: json['battery_type'],
      motorPowerKw: (json['motor_power_kw'] as num?)?.toDouble(),
      motorTorqueNm: (json['motor_torque_nm'] as num?)?.toDouble(),
      frontMotorKw: (json['front_motor_kw'] as num?)?.toDouble(),
      rearMotorKw: (json['rear_motor_kw'] as num?)?.toDouble(),
      rangeKm: json['range_km'],
      rangeStandard: json['range_standard'],
      acChargeKw: (json['ac_charge_kw'] as num?)?.toDouble(),
      dcChargeKw: (json['dc_charge_kw'] as num?)?.toDouble(),
      acChargeTimeHrs: (json['ac_charge_time_hrs'] as num?)?.toDouble(),
      dcChargeTimeMins: json['dc_charge_time_mins'],
      chargingPort: json['charging_port'],
      v2l: json['v2l'],
      v2g: json['v2g'],
      heatPump: json['heat_pump'],
      batteryPreconditioning: json['battery_preconditioning'],
      displacementCc: json['displacement_cc'],
      engineType: json['engine_type'],
      horsepower: json['horsepower'],
      engineTorqueNm: json['engine_torque_nm'],
      fuelType: json['fuel_type'],
      fuelTankLiters: (json['fuel_tank_liters'] as num?)?.toDouble(),
      fuelConsumptionKml: (json['fuel_consumption_kml'] as num?)?.toDouble(),
      turbo: json['turbo'],
      transmission: json['transmission'],
      transmissionSpeeds: json['transmission_speeds'],
      systemPowerHp: json['system_power_hp'],
      systemTorqueNm: json['system_torque_nm'],
      evRangeKm: json['ev_range_km'],
      topSpeedKmh: json['top_speed_kmh'],
      acceleration0100: (json['acceleration_0_100'] as num?)?.toDouble(),
      lengthMm: json['length_mm'],
      widthMm: json['width_mm'],
      heightMm: json['height_mm'],
      wheelbaseMm: json['wheelbase_mm'],
      groundClearanceMm: json['ground_clearance_mm'],
      curbWeightKg: json['curb_weight_kg'],
      grossWeightKg: json['gross_weight_kg'],
      trunkCapacityLiters: json['trunk_capacity_liters'],
      trunkMaxLiters: json['trunk_max_liters'],
      frunkCapacityLiters: json['frunk_capacity_liters'],
      driveType: json['drive_type'],
      frontSuspension: json['front_suspension'],
      rearSuspension: json['rear_suspension'],
      frontBrakes: json['front_brakes'],
      rearBrakes: json['rear_brakes'],
      tireSizeFront: json['tire_size_front'],
      tireSizeRear: json['tire_size_rear'],
      spareTire: json['spare_tire'],
      airbags: json['airbags'],
      abs: json['abs'],
      esc: json['esc'],
      tractionControl: json['traction_control'],
      hillStartAssist: json['hill_start_assist'],
      hillDescentControl: json['hill_descent_control'],
      tpms: json['tpms'],
      isofix: json['isofix'],
      parkingSensorFront: json['parking_sensor_front'],
      parkingSensorRear: json['parking_sensor_rear'],
      cameraRear: json['camera_rear'],
      camera360: json['camera_360'],
      autoParking: json['auto_parking'],
      aeb: json['aeb'],
      fcw: json['fcw'],
      lka: json['lka'],
      ldw: json['ldw'],
      bsd: json['bsd'],
      rcta: json['rcta'],
      acc: json['acc'],
      accStopGo: json['acc_stop_go'],
      driverMonitoring: json['driver_monitoring'],
      trafficSignRecognition: json['traffic_sign_recognition'],
      nightVision: json['night_vision'],
      adasLevel: json['adas_level'],
      ncapRating: (json['ncap_rating'] as num?)?.toDouble(),
      ncapBody: json['ncap_body'],
      ncapYear: json['ncap_year'],
      seats: json['seats'],
      seatMaterial: json['seat_material'],
      driverSeatElectric: json['driver_seat_electric'],
      passengerSeatElectric: json['passenger_seat_electric'],
      driverSeatMemory: json['driver_seat_memory'],
      ventilatedSeatsFront: json['ventilated_seats_front'],
      ventilatedSeatsRear: json['ventilated_seats_rear'],
      heatedSeatsFront: json['heated_seats_front'],
      heatedSeatsRear: json['heated_seats_rear'],
      rearSeatRecline: json['rear_seat_recline'],
      acZones: json['ac_zones'],
      rearAcVents: json['rear_ac_vents'],
      screenSizeInch: (json['screen_size_inch'] as num?)?.toDouble(),
      screenType: json['screen_type'],
      digitalCluster: json['digital_cluster'],
      clusterSizeInch: (json['cluster_size_inch'] as num?)?.toDouble(),
      hud: json['hud'],
      speakerBrand: json['speaker_brand'],
      speakerCount: json['speaker_count'],
      appleCarplay: json['apple_carplay'],
      androidAuto: json['android_auto'],
      wirelessCarplay: json['wireless_carplay'],
      wirelessAndroidAuto: json['wireless_android_auto'],
      wirelessPhoneCharging: json['wireless_phone_charging'],
      usbCPorts: json['usb_c_ports'],
      usbAPorts: json['usb_a_ports'],
      bluetooth: json['bluetooth'],
      otaUpdate: json['ota_update'],
      headlightType: json['headlight_type'],
      drl: json['drl'],
      autoHeadlights: json['auto_headlights'],
      adaptiveHeadlights: json['adaptive_headlights'],
      fogLights: json['fog_lights'],
      sunroof: json['sunroof'],
      powerTailgate: json['power_tailgate'],
      handsFreeTailgate: json['hands_free_tailgate'],
      keylessEntry: json['keyless_entry'],
      pushStart: json['push_start'],
      autoFoldingMirrors: json['auto_folding_mirrors'],
      rainSensingWipers: json['rain_sensing_wipers'],
      roofRails: json['roof_rails'],
      warrantyYears: json['warranty_years'],
      warrantyKm: json['warranty_km'],
      batteryWarrantyYears: json['battery_warranty_years'],
      batteryWarrantyKm: json['battery_warranty_km'],
    );
  }

  String get fullName => '${brandName ?? ''} ${modelName ?? ''} $name'.trim();
}

class CarSearchResult {
  final int variantId;
  final int modelId;
  final String variantName;
  final double? priceBaht;
  final String status;
  final String brandName;
  final String modelName;
  final String powertrainType;
  final int? rangeKm;
  final double? fuelConsumptionKml;

  CarSearchResult({
    required this.variantId,
    required this.modelId,
    required this.variantName,
    this.priceBaht,
    required this.status,
    required this.brandName,
    required this.modelName,
    required this.powertrainType,
    this.rangeKm,
    this.fuelConsumptionKml,
  });

  factory CarSearchResult.fromJson(Map<String, dynamic> json) {
    return CarSearchResult(
      variantId: json['variant_id'],
      modelId: json['model_id'],
      variantName: json['variant_name'],
      priceBaht: (json['price_baht'] as num?)?.toDouble(),
      status: json['status'],
      brandName: json['brand_name'],
      modelName: json['model_name'],
      powertrainType: json['powertrain_type'],
      rangeKm: json['range_km'],
      fuelConsumptionKml: (json['fuel_consumption_kml'] as num?)?.toDouble(),
    );
  }
}
