-- =============================================
-- CompareBuddy: Car Comparison Tables
-- =============================================

-- 1. car_brands
CREATE TABLE IF NOT EXISTS car_brands (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    name_th VARCHAR(100),
    country VARCHAR(50),
    logo_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. car_models
CREATE TABLE IF NOT EXISTS car_models (
    id INT AUTO_INCREMENT PRIMARY KEY,
    brand_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    powertrain_type ENUM('BEV','PHEV','HEV','MHEV','ICE') NOT NULL,
    body_type ENUM('sedan','suv','crossover','hatchback','mpv','pickup','coupe','wagon','van') NOT NULL,
    segment ENUM('a','b','c','d','e','s') NOT NULL,
    year_launched INT,
    status ENUM('on_sale','coming_soon','discontinued') DEFAULT 'on_sale',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (brand_id) REFERENCES car_brands(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. car_variants (wide table - main spec table)
CREATE TABLE IF NOT EXISTS car_variants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    model_id INT NOT NULL,
    name VARCHAR(200) NOT NULL,
    price_baht DECIMAL(12,2),
    status ENUM('on_sale','coming_soon','discontinued') DEFAULT 'on_sale',

    -- Electric / Battery
    battery_capacity_kwh DECIMAL(6,1),
    battery_type VARCHAR(50),
    motor_power_kw DECIMAL(6,1),
    motor_torque_nm DECIMAL(6,1),
    front_motor_kw DECIMAL(6,1),
    rear_motor_kw DECIMAL(6,1),
    range_km INT,
    range_standard VARCHAR(20),
    ac_charge_kw DECIMAL(5,1),
    dc_charge_kw DECIMAL(6,1),
    ac_charge_time_hrs DECIMAL(4,1),
    dc_charge_time_mins INT,
    charging_port VARCHAR(50),
    v2l BOOLEAN,
    v2g BOOLEAN,
    heat_pump BOOLEAN,
    battery_preconditioning BOOLEAN,

    -- Engine (ICE / Hybrid)
    displacement_cc INT,
    engine_type VARCHAR(100),
    horsepower INT,
    engine_torque_nm INT,
    fuel_type ENUM('gasoline_95','gasoline_91','diesel','e20','e85','lpg'),
    fuel_tank_liters DECIMAL(5,1),
    fuel_consumption_kml DECIMAL(4,1),
    turbo BOOLEAN,
    transmission VARCHAR(100),
    transmission_speeds INT,

    -- Combined (Hybrid)
    system_power_hp INT,
    system_torque_nm INT,
    ev_range_km INT,

    -- Performance
    top_speed_kmh INT,
    acceleration_0_100 DECIMAL(4,1),

    -- Dimensions
    length_mm INT,
    width_mm INT,
    height_mm INT,
    wheelbase_mm INT,
    ground_clearance_mm INT,
    curb_weight_kg INT,
    gross_weight_kg INT,
    trunk_capacity_liters INT,
    trunk_max_liters INT,
    frunk_capacity_liters INT,

    -- Drive
    drive_type ENUM('FWD','RWD','AWD','4WD'),
    front_suspension VARCHAR(100),
    rear_suspension VARCHAR(100),
    front_brakes VARCHAR(100),
    rear_brakes VARCHAR(100),
    tire_size_front VARCHAR(50),
    tire_size_rear VARCHAR(50),
    spare_tire VARCHAR(50),

    -- Safety
    airbags INT,
    abs BOOLEAN DEFAULT TRUE,
    esc BOOLEAN DEFAULT TRUE,
    traction_control BOOLEAN,
    hill_start_assist BOOLEAN,
    hill_descent_control BOOLEAN,
    tpms BOOLEAN,
    isofix BOOLEAN,
    parking_sensor_front BOOLEAN,
    parking_sensor_rear BOOLEAN,
    camera_rear BOOLEAN,
    camera_360 BOOLEAN,
    auto_parking BOOLEAN,

    -- ADAS
    aeb BOOLEAN,
    fcw BOOLEAN,
    lka BOOLEAN,
    ldw BOOLEAN,
    bsd BOOLEAN,
    rcta BOOLEAN,
    acc BOOLEAN,
    acc_stop_go BOOLEAN,
    driver_monitoring VARCHAR(50),
    traffic_sign_recognition BOOLEAN,
    night_vision BOOLEAN,
    adas_level VARCHAR(20),

    -- NCAP
    ncap_rating DECIMAL(2,1),
    ncap_body VARCHAR(30),
    ncap_year INT,

    -- Comfort
    seats INT,
    seat_material VARCHAR(50),
    driver_seat_electric BOOLEAN,
    passenger_seat_electric BOOLEAN,
    driver_seat_memory BOOLEAN,
    ventilated_seats_front BOOLEAN,
    ventilated_seats_rear BOOLEAN,
    heated_seats_front BOOLEAN,
    heated_seats_rear BOOLEAN,
    rear_seat_recline BOOLEAN,
    ac_zones INT,
    rear_ac_vents BOOLEAN,

    -- Infotainment
    screen_size_inch DECIMAL(3,1),
    screen_type VARCHAR(50),
    digital_cluster BOOLEAN,
    cluster_size_inch DECIMAL(3,1),
    hud BOOLEAN,
    speaker_brand VARCHAR(50),
    speaker_count INT,
    apple_carplay BOOLEAN,
    android_auto BOOLEAN,
    wireless_carplay BOOLEAN,
    wireless_android_auto BOOLEAN,
    wireless_phone_charging BOOLEAN,
    usb_c_ports INT,
    usb_a_ports INT,
    bluetooth VARCHAR(10),
    ota_update BOOLEAN,

    -- Exterior
    headlight_type VARCHAR(50),
    drl BOOLEAN,
    auto_headlights BOOLEAN,
    adaptive_headlights BOOLEAN,
    fog_lights BOOLEAN,
    sunroof ENUM('none','standard','panoramic','glass_roof') DEFAULT 'none',
    power_tailgate BOOLEAN,
    hands_free_tailgate BOOLEAN,
    keyless_entry BOOLEAN,
    push_start BOOLEAN,
    auto_folding_mirrors BOOLEAN,
    rain_sensing_wipers BOOLEAN,
    roof_rails BOOLEAN,

    -- Warranty
    warranty_years INT,
    warranty_km INT,
    battery_warranty_years INT,
    battery_warranty_km INT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (model_id) REFERENCES car_models(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. car_images
CREATE TABLE IF NOT EXISTS car_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    variant_id INT NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    image_type ENUM('exterior','interior','detail','color') DEFAULT 'exterior',
    sort_order INT DEFAULT 0,
    FOREIGN KEY (variant_id) REFERENCES car_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. car_colors
CREATE TABLE IF NOT EXISTS car_colors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    variant_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    hex_code VARCHAR(7),
    extra_cost DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (variant_id) REFERENCES car_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. user_car_favorites
CREATE TABLE IF NOT EXISTS user_car_favorites (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    variant_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_fav (user_id, variant_id),
    FOREIGN KEY (variant_id) REFERENCES car_variants(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. user_comparisons
CREATE TABLE IF NOT EXISTS user_comparisons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    variant_ids JSON NOT NULL,
    title VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- INDEXES
-- =============================================
CREATE INDEX idx_car_models_brand ON car_models(brand_id);
CREATE INDEX idx_car_models_powertrain ON car_models(powertrain_type);
CREATE INDEX idx_car_models_body ON car_models(body_type);
CREATE INDEX idx_car_models_status ON car_models(status);
CREATE INDEX idx_car_variants_model ON car_variants(model_id);
CREATE INDEX idx_car_variants_price ON car_variants(price_baht);
CREATE INDEX idx_car_variants_status ON car_variants(status);
