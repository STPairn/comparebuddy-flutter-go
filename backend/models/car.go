package models

type CarBrand struct {
	ID      int     `json:"id"`
	Name    string  `json:"name"`
	NameTh  *string `json:"name_th"`
	Country *string `json:"country"`
	LogoURL *string `json:"logo_url"`
}

type CarBrandWithModels struct {
	CarBrand
	Models []CarModel `json:"models"`
}

type CarModel struct {
	ID             int    `json:"id"`
	BrandID        int    `json:"brand_id"`
	Name           string `json:"name"`
	PowertrainType string `json:"powertrain_type"`
	BodyType       string `json:"body_type"`
	Segment        string `json:"segment"`
	YearLaunched   *int   `json:"year_launched"`
	Status         string `json:"status"`
	// Joined fields
	BrandName *string `json:"brand_name,omitempty"`
}

type CarModelWithVariants struct {
	CarModel
	Variants []CarVariantSummary `json:"variants"`
}

type CarVariantSummary struct {
	ID        int      `json:"id"`
	ModelID   int      `json:"model_id"`
	Name      string   `json:"name"`
	PriceBaht *float64 `json:"price_baht"`
	Status    string   `json:"status"`
}

type CarVariant struct {
	ID        int      `json:"id"`
	ModelID   int      `json:"model_id"`
	Name      string   `json:"name"`
	PriceBaht *float64 `json:"price_baht"`
	Status    string   `json:"status"`

	// Joined fields
	BrandName      *string `json:"brand_name,omitempty"`
	ModelName      *string `json:"model_name,omitempty"`
	PowertrainType *string `json:"powertrain_type,omitempty"`
	BodyType       *string `json:"body_type,omitempty"`

	// Electric / Battery
	BatteryCapacityKwh    *float64 `json:"battery_capacity_kwh"`
	BatteryType           *string  `json:"battery_type"`
	MotorPowerKw          *float64 `json:"motor_power_kw"`
	MotorTorqueNm         *float64 `json:"motor_torque_nm"`
	FrontMotorKw          *float64 `json:"front_motor_kw"`
	RearMotorKw           *float64 `json:"rear_motor_kw"`
	RangeKm               *int     `json:"range_km"`
	RangeStandard         *string  `json:"range_standard"`
	AcChargeKw            *float64 `json:"ac_charge_kw"`
	DcChargeKw            *float64 `json:"dc_charge_kw"`
	AcChargeTimeHrs       *float64 `json:"ac_charge_time_hrs"`
	DcChargeTimeMins      *int     `json:"dc_charge_time_mins"`
	ChargingPort          *string  `json:"charging_port"`
	V2l                   *bool    `json:"v2l"`
	V2g                   *bool    `json:"v2g"`
	HeatPump              *bool    `json:"heat_pump"`
	BatteryPreconditioning *bool   `json:"battery_preconditioning"`

	// Engine (ICE / Hybrid)
	DisplacementCc     *int     `json:"displacement_cc"`
	EngineType         *string  `json:"engine_type"`
	Horsepower         *int     `json:"horsepower"`
	EngineTorqueNm     *int     `json:"engine_torque_nm"`
	FuelType           *string  `json:"fuel_type"`
	FuelTankLiters     *float64 `json:"fuel_tank_liters"`
	FuelConsumptionKml *float64 `json:"fuel_consumption_kml"`
	Turbo              *bool    `json:"turbo"`
	Transmission       *string  `json:"transmission"`
	TransmissionSpeeds *int     `json:"transmission_speeds"`

	// Combined (Hybrid)
	SystemPowerHp  *int `json:"system_power_hp"`
	SystemTorqueNm *int `json:"system_torque_nm"`
	EvRangeKm      *int `json:"ev_range_km"`

	// Performance
	TopSpeedKmh      *int     `json:"top_speed_kmh"`
	Acceleration0100 *float64 `json:"acceleration_0_100"`

	// Dimensions
	LengthMm            *int `json:"length_mm"`
	WidthMm              *int `json:"width_mm"`
	HeightMm             *int `json:"height_mm"`
	WheelbaseMm          *int `json:"wheelbase_mm"`
	GroundClearanceMm    *int `json:"ground_clearance_mm"`
	CurbWeightKg         *int `json:"curb_weight_kg"`
	GrossWeightKg        *int `json:"gross_weight_kg"`
	TrunkCapacityLiters  *int `json:"trunk_capacity_liters"`
	TrunkMaxLiters       *int `json:"trunk_max_liters"`
	FrunkCapacityLiters  *int `json:"frunk_capacity_liters"`

	// Drive
	DriveType       *string `json:"drive_type"`
	FrontSuspension *string `json:"front_suspension"`
	RearSuspension  *string `json:"rear_suspension"`
	FrontBrakes     *string `json:"front_brakes"`
	RearBrakes      *string `json:"rear_brakes"`
	TireSizeFront   *string `json:"tire_size_front"`
	TireSizeRear    *string `json:"tire_size_rear"`
	SpareTire       *string `json:"spare_tire"`

	// Safety
	Airbags            *int  `json:"airbags"`
	Abs                *bool `json:"abs"`
	Esc                *bool `json:"esc"`
	TractionControl    *bool `json:"traction_control"`
	HillStartAssist    *bool `json:"hill_start_assist"`
	HillDescentControl *bool `json:"hill_descent_control"`
	Tpms               *bool `json:"tpms"`
	Isofix             *bool `json:"isofix"`
	ParkingSensorFront *bool `json:"parking_sensor_front"`
	ParkingSensorRear  *bool `json:"parking_sensor_rear"`
	CameraRear         *bool `json:"camera_rear"`
	Camera360          *bool `json:"camera_360"`
	AutoParking        *bool `json:"auto_parking"`

	// ADAS
	Aeb                      *bool   `json:"aeb"`
	Fcw                      *bool   `json:"fcw"`
	Lka                      *bool   `json:"lka"`
	Ldw                      *bool   `json:"ldw"`
	Bsd                      *bool   `json:"bsd"`
	Rcta                     *bool   `json:"rcta"`
	Acc                      *bool   `json:"acc"`
	AccStopGo                *bool   `json:"acc_stop_go"`
	DriverMonitoring         *string `json:"driver_monitoring"`
	TrafficSignRecognition   *bool   `json:"traffic_sign_recognition"`
	NightVision              *bool   `json:"night_vision"`
	AdasLevel                *string `json:"adas_level"`

	// NCAP
	NcapRating *float64 `json:"ncap_rating"`
	NcapBody   *string  `json:"ncap_body"`
	NcapYear   *int     `json:"ncap_year"`

	// Comfort
	Seats                *int    `json:"seats"`
	SeatMaterial         *string `json:"seat_material"`
	DriverSeatElectric   *bool   `json:"driver_seat_electric"`
	PassengerSeatElectric *bool  `json:"passenger_seat_electric"`
	DriverSeatMemory     *bool   `json:"driver_seat_memory"`
	VentilatedSeatsFront *bool   `json:"ventilated_seats_front"`
	VentilatedSeatsRear  *bool   `json:"ventilated_seats_rear"`
	HeatedSeatsFront     *bool   `json:"heated_seats_front"`
	HeatedSeatsRear      *bool   `json:"heated_seats_rear"`
	RearSeatRecline      *bool   `json:"rear_seat_recline"`
	AcZones              *int    `json:"ac_zones"`
	RearAcVents          *bool   `json:"rear_ac_vents"`

	// Infotainment
	ScreenSizeInch       *float64 `json:"screen_size_inch"`
	ScreenType           *string  `json:"screen_type"`
	DigitalCluster       *bool    `json:"digital_cluster"`
	ClusterSizeInch      *float64 `json:"cluster_size_inch"`
	Hud                  *bool    `json:"hud"`
	SpeakerBrand         *string  `json:"speaker_brand"`
	SpeakerCount         *int     `json:"speaker_count"`
	AppleCarplay         *bool    `json:"apple_carplay"`
	AndroidAuto          *bool    `json:"android_auto"`
	WirelessCarplay      *bool    `json:"wireless_carplay"`
	WirelessAndroidAuto  *bool    `json:"wireless_android_auto"`
	WirelessPhoneCharging *bool   `json:"wireless_phone_charging"`
	UsbCPorts            *int     `json:"usb_c_ports"`
	UsbAPorts            *int     `json:"usb_a_ports"`
	Bluetooth            *string  `json:"bluetooth"`
	OtaUpdate            *bool    `json:"ota_update"`

	// Exterior
	HeadlightType      *string `json:"headlight_type"`
	Drl                *bool   `json:"drl"`
	AutoHeadlights     *bool   `json:"auto_headlights"`
	AdaptiveHeadlights *bool   `json:"adaptive_headlights"`
	FogLights          *bool   `json:"fog_lights"`
	Sunroof            *string `json:"sunroof"`
	PowerTailgate      *bool   `json:"power_tailgate"`
	HandsFreeTailgate  *bool   `json:"hands_free_tailgate"`
	KeylessEntry       *bool   `json:"keyless_entry"`
	PushStart          *bool   `json:"push_start"`
	AutoFoldingMirrors *bool   `json:"auto_folding_mirrors"`
	RainSensingWipers  *bool   `json:"rain_sensing_wipers"`
	RoofRails          *bool   `json:"roof_rails"`

	// Warranty
	WarrantyYears       *int `json:"warranty_years"`
	WarrantyKm          *int `json:"warranty_km"`
	BatteryWarrantyYears *int `json:"battery_warranty_years"`
	BatteryWarrantyKm   *int `json:"battery_warranty_km"`
}
