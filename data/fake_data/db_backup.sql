-- Tabellenerstellung
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    action VARCHAR(50) NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    location VARCHAR(255),
    duration_seconds INTEGER,
    search_query VARCHAR(255),
    purchase_amount DECIMAL(10,2),
    rating INTEGER,
    is_subscribed BOOLEAN
);

-- Beispieldaten einfügen
INSERT INTO users (timestamp, action, device_type, location, duration_seconds, search_query, purchase_amount, rating, is_subscribed) VALUES
('2025-10-10 10:00:00', 'login',         'mobile', 'Musterstraße 1, 12345 Berlin',  60,  NULL,    NULL,  NULL,  TRUE),
('2025-10-10 10:05:15', 'search',        'desktop','Beispielgasse 5, 67890 Hamburg',120,  'Laptop', NULL,  NULL,  FALSE),
('2025-10-10 10:10:32', 'purchase',      'mobile', 'Ringstraße 2, 54321 München',   20,  NULL,    349.99, 5,  TRUE),
('2025-10-10 10:12:00', 'rate_product',  'tablet', 'Bahnhofstraße 3, 13579 Köln',   15,  NULL,    NULL,  4,  FALSE),
('2025-10-10 10:15:42', 'logout',        'desktop','Hauptplatz 8, 24680 Wien',      10,  NULL,    NULL,  NULL, TRUE);
