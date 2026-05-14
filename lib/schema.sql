-- Carbon Footprint Tracker Table
CREATE TABLE carbon_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL,
    activity_type TEXT NOT NULL,
    value REAL NOT NULL,
    co2_emitted_kg REAL NOT NULL,
    notes TEXT
);

-- Waste Reduction Tracker Table
CREATE TABLE waste_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL,
    material_type TEXT NOT NULL,
    weight_kg REAL NOT NULL,
    action_taken TEXT NOT NULL,
    notes TEXT
);
