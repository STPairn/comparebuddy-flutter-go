package handlers

import (
	"comparebuddy-backend/config"
	"comparebuddy-backend/models"
	"strings"

	"github.com/gofiber/fiber/v2"
)

// GetCarBrands - GET /api/cars/brands
func GetCarBrands(c *fiber.Ctx) error {
	rows, err := config.DB.Query("SELECT id, name, name_th, country, logo_url FROM car_brands ORDER BY name")
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch car brands"})
	}
	defer rows.Close()

	var brands []models.CarBrand
	for rows.Next() {
		var b models.CarBrand
		rows.Scan(&b.ID, &b.Name, &b.NameTh, &b.Country, &b.LogoURL)
		brands = append(brands, b)
	}

	return c.JSON(brands)
}

// GetCarBrandByID - GET /api/cars/brands/:id
func GetCarBrandByID(c *fiber.Ctx) error {
	id := c.Params("id")

	var brand models.CarBrand
	err := config.DB.QueryRow("SELECT id, name, name_th, country, logo_url FROM car_brands WHERE id = ?", id).
		Scan(&brand.ID, &brand.Name, &brand.NameTh, &brand.Country, &brand.LogoURL)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Brand not found"})
	}

	rows, err := config.DB.Query(
		"SELECT id, brand_id, name, powertrain_type, body_type, segment, year_launched, status FROM car_models WHERE brand_id = ? ORDER BY name",
		id,
	)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch models"})
	}
	defer rows.Close()

	result := models.CarBrandWithModels{CarBrand: brand}
	for rows.Next() {
		var m models.CarModel
		rows.Scan(&m.ID, &m.BrandID, &m.Name, &m.PowertrainType, &m.BodyType, &m.Segment, &m.YearLaunched, &m.Status)
		result.Models = append(result.Models, m)
	}

	return c.JSON(result)
}

// GetCarModels - GET /api/cars/models?brand_id=&powertrain_type=&body_type=&segment=
func GetCarModels(c *fiber.Ctx) error {
	brandID := c.Query("brand_id")
	powertrainType := c.Query("powertrain_type")
	bodyType := c.Query("body_type")
	segment := c.Query("segment")

	query := "SELECT m.id, m.brand_id, m.name, m.powertrain_type, m.body_type, m.segment, m.year_launched, m.status, b.name FROM car_models m JOIN car_brands b ON m.brand_id = b.id WHERE 1=1"
	args := []interface{}{}

	if brandID != "" {
		query += " AND m.brand_id = ?"
		args = append(args, brandID)
	}
	if powertrainType != "" {
		query += " AND m.powertrain_type = ?"
		args = append(args, powertrainType)
	}
	if bodyType != "" {
		query += " AND m.body_type = ?"
		args = append(args, bodyType)
	}
	if segment != "" {
		query += " AND m.segment = ?"
		args = append(args, segment)
	}

	query += " ORDER BY b.name, m.name"

	rows, err := config.DB.Query(query, args...)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch car models"})
	}
	defer rows.Close()

	var carModels []models.CarModel
	for rows.Next() {
		var m models.CarModel
		rows.Scan(&m.ID, &m.BrandID, &m.Name, &m.PowertrainType, &m.BodyType, &m.Segment, &m.YearLaunched, &m.Status, &m.BrandName)
		carModels = append(carModels, m)
	}

	return c.JSON(carModels)
}

// GetCarModelByID - GET /api/cars/models/:id
func GetCarModelByID(c *fiber.Ctx) error {
	id := c.Params("id")

	var m models.CarModel
	err := config.DB.QueryRow(
		"SELECT m.id, m.brand_id, m.name, m.powertrain_type, m.body_type, m.segment, m.year_launched, m.status, b.name FROM car_models m JOIN car_brands b ON m.brand_id = b.id WHERE m.id = ?",
		id,
	).Scan(&m.ID, &m.BrandID, &m.Name, &m.PowertrainType, &m.BodyType, &m.Segment, &m.YearLaunched, &m.Status, &m.BrandName)
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Model not found"})
	}

	rows, err := config.DB.Query(
		"SELECT id, model_id, name, price_baht, status FROM car_variants WHERE model_id = ? ORDER BY price_baht",
		id,
	)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch variants"})
	}
	defer rows.Close()

	result := models.CarModelWithVariants{CarModel: m}
	for rows.Next() {
		var v models.CarVariantSummary
		rows.Scan(&v.ID, &v.ModelID, &v.Name, &v.PriceBaht, &v.Status)
		result.Variants = append(result.Variants, v)
	}

	return c.JSON(result)
}

// variantColumns - all columns for car_variants full spec query
const variantColumns = `v.id, v.model_id, v.name, v.price_baht, v.status,
b.name, m.name, m.powertrain_type, m.body_type,
v.battery_capacity_kwh, v.battery_type, v.motor_power_kw, v.motor_torque_nm,
v.front_motor_kw, v.rear_motor_kw, v.range_km, v.range_standard,
v.ac_charge_kw, v.dc_charge_kw, v.ac_charge_time_hrs, v.dc_charge_time_mins,
v.charging_port, v.v2l, v.v2g, v.heat_pump, v.battery_preconditioning,
v.displacement_cc, v.engine_type, v.horsepower, v.engine_torque_nm,
v.fuel_type, v.fuel_tank_liters, v.fuel_consumption_kml, v.turbo,
v.transmission, v.transmission_speeds,
v.system_power_hp, v.system_torque_nm, v.ev_range_km,
v.top_speed_kmh, v.acceleration_0_100,
v.length_mm, v.width_mm, v.height_mm, v.wheelbase_mm, v.ground_clearance_mm,
v.curb_weight_kg, v.gross_weight_kg, v.trunk_capacity_liters, v.trunk_max_liters, v.frunk_capacity_liters,
v.drive_type, v.front_suspension, v.rear_suspension, v.front_brakes, v.rear_brakes,
v.tire_size_front, v.tire_size_rear, v.spare_tire,
v.airbags, v.abs, v.esc, v.traction_control, v.hill_start_assist, v.hill_descent_control,
v.tpms, v.isofix, v.parking_sensor_front, v.parking_sensor_rear,
v.camera_rear, v.camera_360, v.auto_parking,
v.aeb, v.fcw, v.lka, v.ldw, v.bsd, v.rcta, v.acc, v.acc_stop_go,
v.driver_monitoring, v.traffic_sign_recognition, v.night_vision, v.adas_level,
v.ncap_rating, v.ncap_body, v.ncap_year,
v.seats, v.seat_material, v.driver_seat_electric, v.passenger_seat_electric, v.driver_seat_memory,
v.ventilated_seats_front, v.ventilated_seats_rear, v.heated_seats_front, v.heated_seats_rear,
v.rear_seat_recline, v.ac_zones, v.rear_ac_vents,
v.screen_size_inch, v.screen_type, v.digital_cluster, v.cluster_size_inch, v.hud,
v.speaker_brand, v.speaker_count, v.apple_carplay, v.android_auto,
v.wireless_carplay, v.wireless_android_auto, v.wireless_phone_charging,
v.usb_c_ports, v.usb_a_ports, v.bluetooth, v.ota_update,
v.headlight_type, v.drl, v.auto_headlights, v.adaptive_headlights, v.fog_lights,
v.sunroof, v.power_tailgate, v.hands_free_tailgate,
v.keyless_entry, v.push_start, v.auto_folding_mirrors, v.rain_sensing_wipers, v.roof_rails,
v.warranty_years, v.warranty_km, v.battery_warranty_years, v.battery_warranty_km`

func scanVariant(scanner interface{ Scan(...interface{}) error }) (models.CarVariant, error) {
	var v models.CarVariant
	err := scanner.Scan(
		&v.ID, &v.ModelID, &v.Name, &v.PriceBaht, &v.Status,
		&v.BrandName, &v.ModelName, &v.PowertrainType, &v.BodyType,
		&v.BatteryCapacityKwh, &v.BatteryType, &v.MotorPowerKw, &v.MotorTorqueNm,
		&v.FrontMotorKw, &v.RearMotorKw, &v.RangeKm, &v.RangeStandard,
		&v.AcChargeKw, &v.DcChargeKw, &v.AcChargeTimeHrs, &v.DcChargeTimeMins,
		&v.ChargingPort, &v.V2l, &v.V2g, &v.HeatPump, &v.BatteryPreconditioning,
		&v.DisplacementCc, &v.EngineType, &v.Horsepower, &v.EngineTorqueNm,
		&v.FuelType, &v.FuelTankLiters, &v.FuelConsumptionKml, &v.Turbo,
		&v.Transmission, &v.TransmissionSpeeds,
		&v.SystemPowerHp, &v.SystemTorqueNm, &v.EvRangeKm,
		&v.TopSpeedKmh, &v.Acceleration0100,
		&v.LengthMm, &v.WidthMm, &v.HeightMm, &v.WheelbaseMm, &v.GroundClearanceMm,
		&v.CurbWeightKg, &v.GrossWeightKg, &v.TrunkCapacityLiters, &v.TrunkMaxLiters, &v.FrunkCapacityLiters,
		&v.DriveType, &v.FrontSuspension, &v.RearSuspension, &v.FrontBrakes, &v.RearBrakes,
		&v.TireSizeFront, &v.TireSizeRear, &v.SpareTire,
		&v.Airbags, &v.Abs, &v.Esc, &v.TractionControl, &v.HillStartAssist, &v.HillDescentControl,
		&v.Tpms, &v.Isofix, &v.ParkingSensorFront, &v.ParkingSensorRear,
		&v.CameraRear, &v.Camera360, &v.AutoParking,
		&v.Aeb, &v.Fcw, &v.Lka, &v.Ldw, &v.Bsd, &v.Rcta, &v.Acc, &v.AccStopGo,
		&v.DriverMonitoring, &v.TrafficSignRecognition, &v.NightVision, &v.AdasLevel,
		&v.NcapRating, &v.NcapBody, &v.NcapYear,
		&v.Seats, &v.SeatMaterial, &v.DriverSeatElectric, &v.PassengerSeatElectric, &v.DriverSeatMemory,
		&v.VentilatedSeatsFront, &v.VentilatedSeatsRear, &v.HeatedSeatsFront, &v.HeatedSeatsRear,
		&v.RearSeatRecline, &v.AcZones, &v.RearAcVents,
		&v.ScreenSizeInch, &v.ScreenType, &v.DigitalCluster, &v.ClusterSizeInch, &v.Hud,
		&v.SpeakerBrand, &v.SpeakerCount, &v.AppleCarplay, &v.AndroidAuto,
		&v.WirelessCarplay, &v.WirelessAndroidAuto, &v.WirelessPhoneCharging,
		&v.UsbCPorts, &v.UsbAPorts, &v.Bluetooth, &v.OtaUpdate,
		&v.HeadlightType, &v.Drl, &v.AutoHeadlights, &v.AdaptiveHeadlights, &v.FogLights,
		&v.Sunroof, &v.PowerTailgate, &v.HandsFreeTailgate,
		&v.KeylessEntry, &v.PushStart, &v.AutoFoldingMirrors, &v.RainSensingWipers, &v.RoofRails,
		&v.WarrantyYears, &v.WarrantyKm, &v.BatteryWarrantyYears, &v.BatteryWarrantyKm,
	)
	return v, err
}

// GetCarVariantByID - GET /api/cars/variants/:id
func GetCarVariantByID(c *fiber.Ctx) error {
	id := c.Params("id")

	query := "SELECT " + variantColumns + " FROM car_variants v JOIN car_models m ON v.model_id = m.id JOIN car_brands b ON m.brand_id = b.id WHERE v.id = ?"

	v, err := scanVariant(config.DB.QueryRow(query, id))
	if err != nil {
		return c.Status(404).JSON(fiber.Map{"error": "Variant not found"})
	}

	return c.JSON(v)
}

// CompareCarVariants - GET /api/cars/compare?ids=1,3,6
func CompareCarVariants(c *fiber.Ctx) error {
	idsParam := c.Query("ids")
	if idsParam == "" {
		return c.Status(400).JSON(fiber.Map{"error": "ids parameter is required (e.g. ?ids=1,3,6)"})
	}

	ids := strings.Split(idsParam, ",")
	if len(ids) < 2 || len(ids) > 4 {
		return c.Status(400).JSON(fiber.Map{"error": "Compare 2-4 variants (e.g. ?ids=1,3)"})
	}

	placeholders := strings.Repeat("?,", len(ids))
	placeholders = placeholders[:len(placeholders)-1]

	query := "SELECT " + variantColumns + " FROM car_variants v JOIN car_models m ON v.model_id = m.id JOIN car_brands b ON m.brand_id = b.id WHERE v.id IN (" + placeholders + ")"

	args := make([]interface{}, len(ids))
	for i, id := range ids {
		args[i] = strings.TrimSpace(id)
	}

	rows, err := config.DB.Query(query, args...)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Failed to fetch variants for comparison"})
	}
	defer rows.Close()

	var variants []models.CarVariant
	for rows.Next() {
		v, err := scanVariant(rows)
		if err != nil {
			continue
		}
		variants = append(variants, v)
	}

	if len(variants) == 0 {
		return c.Status(404).JSON(fiber.Map{"error": "No variants found"})
	}

	return c.JSON(fiber.Map{
		"count":    len(variants),
		"variants": variants,
	})
}

// BrowseCarVariants - GET /api/cars/browse?min_price=500000&max_price=1500000&powertrain_type=BEV
func BrowseCarVariants(c *fiber.Ctx) error {
	minPrice := c.Query("min_price")
	maxPrice := c.Query("max_price")
	powertrainType := c.Query("powertrain_type")

	minRange := c.Query("min_range")
	minFuelEfficiency := c.Query("min_fuel_efficiency")

	query := `SELECT v.id, v.model_id, v.name, v.price_baht, v.status, b.name, m.name, m.powertrain_type, v.range_km, v.fuel_consumption_kml
		FROM car_variants v
		JOIN car_models m ON v.model_id = m.id
		JOIN car_brands b ON m.brand_id = b.id
		WHERE v.price_baht IS NOT NULL`
	args := []interface{}{}

	if minPrice != "" {
		query += " AND v.price_baht >= ?"
		args = append(args, minPrice)
	}
	if maxPrice != "" {
		query += " AND v.price_baht <= ?"
		args = append(args, maxPrice)
	}
	if powertrainType != "" {
		query += " AND m.powertrain_type = ?"
		args = append(args, powertrainType)
	}
	if minRange != "" {
		query += " AND v.range_km >= ?"
		args = append(args, minRange)
	}
	if minFuelEfficiency != "" {
		query += " AND v.fuel_consumption_kml >= ?"
		args = append(args, minFuelEfficiency)
	}

	query += " ORDER BY v.price_baht LIMIT 50"

	rows, err := config.DB.Query(query, args...)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Browse failed"})
	}
	defer rows.Close()

	type SearchResult struct {
		VariantID          int      `json:"variant_id"`
		ModelID            int      `json:"model_id"`
		VariantName        string   `json:"variant_name"`
		PriceBaht          *float64 `json:"price_baht"`
		Status             string   `json:"status"`
		BrandName          string   `json:"brand_name"`
		ModelName          string   `json:"model_name"`
		PowertrainType     string   `json:"powertrain_type"`
		RangeKm            *int     `json:"range_km"`
		FuelConsumptionKml *float64 `json:"fuel_consumption_kml"`
	}

	var results []SearchResult
	for rows.Next() {
		var r SearchResult
		rows.Scan(&r.VariantID, &r.ModelID, &r.VariantName, &r.PriceBaht, &r.Status, &r.BrandName, &r.ModelName, &r.PowertrainType, &r.RangeKm, &r.FuelConsumptionKml)
		results = append(results, r)
	}

	return c.JSON(results)
}

// SearchCars - GET /api/cars/search?q=atto
func SearchCars(c *fiber.Ctx) error {
	q := c.Query("q")
	if q == "" {
		return c.Status(400).JSON(fiber.Map{"error": "q parameter is required"})
	}

	query := `SELECT v.id, v.model_id, v.name, v.price_baht, v.status, b.name, m.name, m.powertrain_type
		FROM car_variants v
		JOIN car_models m ON v.model_id = m.id
		JOIN car_brands b ON m.brand_id = b.id
		WHERE b.name LIKE ? OR m.name LIKE ? OR v.name LIKE ?
		ORDER BY b.name, m.name, v.price_baht
		LIMIT 20`

	searchTerm := "%" + q + "%"
	rows, err := config.DB.Query(query, searchTerm, searchTerm, searchTerm)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"error": "Search failed"})
	}
	defer rows.Close()

	type SearchResult struct {
		VariantID      int      `json:"variant_id"`
		ModelID        int      `json:"model_id"`
		VariantName    string   `json:"variant_name"`
		PriceBaht      *float64 `json:"price_baht"`
		Status         string   `json:"status"`
		BrandName      string   `json:"brand_name"`
		ModelName      string   `json:"model_name"`
		PowertrainType string   `json:"powertrain_type"`
	}

	var results []SearchResult
	for rows.Next() {
		var r SearchResult
		rows.Scan(&r.VariantID, &r.ModelID, &r.VariantName, &r.PriceBaht, &r.Status, &r.BrandName, &r.ModelName, &r.PowertrainType)
		results = append(results, r)
	}

	return c.JSON(results)
}
