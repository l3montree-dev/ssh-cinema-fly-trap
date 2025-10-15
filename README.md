# 🍯 SSH Cinema Fly Trap

Containerisierter SSH-Honeypot zur Analyse automatisierter Angriffe. 

Entwickelt im Rahmen eines Praktikumsprojekts an der Hochschule Bonn-Rhein-Sieg.

## 🎯 Funktionen

- **Session-Aufzeichnung** mit `asciinema`
- **Netzwerk-Analyse** mit `tcpdump`
- **Schwache Credentials** (`root:root`, `user:password`)
- **Fake Webapp** mit Köder-Dateien (.env, db_backup.sql)
- **Echtzeit-Alerts** bei verdächtigen Aktivitäten
- **Persistente Logs** in Docker Volumes
