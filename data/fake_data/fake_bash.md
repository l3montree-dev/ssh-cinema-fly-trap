# Datenbank-Backup erstellen
pg_dump -U postgres -d userdb > db_backup.sql

# In die Datenbank einloggen
psql -U postgres -d userdb

# Tabelle anzeigen
\dt

# Tabellenstruktur anzeigen
\d users

# Ein paar Dummy-User einfügen
psql -U postgres -d userdb -c "INSERT INTO users (timestamp, action, device_type, location, duration_seconds, search_query, purchase_amount, rating, is_subscribed) VALUES ('2025-10-10 10:20:01', 'login', 'desktop', 'Testweg 7, 12345 Berlin', 45, NULL, NULL, NULL, TRUE);"

# Abfrage aller User mit Kauf
psql -U postgres -d userdb -c "SELECT * FROM users WHERE action='purchase';"

# Export als CSV
psql -U postgres -d userdb -c "COPY users TO '/tmp/users.csv' DELIMITER ',' CSV HEADER;"

# Abfrage nach Nutzer mit Subscription
psql -U postgres -d userdb -c "SELECT user_id, location FROM users WHERE is_subscribed=true;"

# Letzte Aktionen prüfen
psql -U postgres -d userdb -c "SELECT * FROM users ORDER BY timestamp DESC LIMIT 5;"

# Dump einspielen zum Test
psql -U postgres -d userdb < db_backup.sql
