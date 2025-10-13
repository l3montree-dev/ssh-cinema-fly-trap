# 🍯 SSH Honeypot - Production-Ready

Ein manipulationssicherer SSH-Honeypot mit Echtzeit-Alerts und vollständiger Session-Aufzeichnung.

---

## 🎯 Features

### ✅ Kern-Funktionen
- **Manipulationssichere Aufzeichnung** - ForceCommand verhindert Umgehung
- **Echtzeit-Alerts** - Discord-Benachrichtigung bei jedem SSH-Login
- **Vollständige Session-Forensik** - Terminal-Recordings, Logs, Network-Traffic
- **Non-Interactive Support** - Auch `ssh user@host 'command'` wird aufgezeichnet
- **Persistente Logs** - Alle Daten auf Host gespeichert, nicht im Container

### 🛡️ Sicherheits-Features
- **Unumgehbar** - Auch erfahrene Angreifer können Monitoring nicht deaktivieren
- **Logs außerhalb Container** - Angreifer kann Aufzeichnungen nicht löschen
- **Session-Metadaten** - JSON mit IP, Port, Timestamp, User

### 🎭 Honeypot-Elemente
- Schwache Credentials (`user:password`, `root:root`)
- Fake-Daten (.env, db_backup.sql, .bash_history)
- Realistische Verzeichnisstruktur (webapp, documents, downloads)

---

## 📂 Projekt-Struktur

```
HONEYPOT_CONTAINER/
├── data/
│   └── fake_data/              # Fake-Daten für Angreifer
│       ├── db_backup.sql
│       ├── fake_bash.md
│       └── fake_env.md
├── docker/
│   ├── configs/                # Container-Konfiguration
│   │   ├── rsyslog.conf        # Log-Routing
│   │   └── sshd_config         # SSH mit ForceCommand
│   └── Dockerfiles Backups/
├── PCAP-Dateien/               # 📦 Volume: Network-Traffic
├── Systemlogs/                 # 📦 Volume: SSH & System Logs
├── Terminal-Recordings/        # 📦 Volume: asciinema Sessions
├── scripts/
│   ├── monitoring/
│   │   ├── alert.sh            # Discord-Webhook
│   │   └── session_wrapper.sh  # Session-Handler (ForceCommand)
│   └── startup/
│       └── startup-script      # Container-Start (rsyslog, tcpdump, sshd)
├── docker-compose.yml
├── Dockerfile
└── README.md
```

---

## 🚀 Quick Start

### 1. Discord Webhook einrichten
```bash
# In Discord: Server → Channel → Integrationen → Webhooks → Neuer Webhook
# URL kopieren und in scripts/monitoring/alert.sh einfügen:
WEBHOOK_URL="https://discord.com/api/webhooks/..."
```

### 2. Container starten
```bash
docker-compose up --build -d
```

### 3. Testen
```bash
# SSH-Login
ssh -p 2222 user@localhost
# Password: password

# Check Discord → Alert sollte erscheinen! 🚨
# Check Logs:
ls -la Terminal-Recordings/  # Session-Recordings
ls -la Systemlogs/           # auth.log
ls -la PCAP-Dateien/         # Network-Traffic
```

---

## 📊 Monitoring & Logs

### Terminal-Recordings
```bash
# Sessions abspielen
asciinema play Terminal-Recordings/session_20251013_131328_user_26.cast

# Alle Sessions auflisten
ls -lh Terminal-Recordings/*.cast
```

### System-Logs
```bash
# SSH-Logins anschauen
cat Systemlogs/auth.log

# Nach IP suchen
grep "185.125.190.39" Systemlogs/auth.log
```

### Network-Traffic
```bash
# PCAP analysieren
tcpdump -r PCAP-Dateien/traffic_20251013_101059.pcap

# In Wireshark öffnen
open PCAP-Dateien/traffic_*.pcap
```

### Session-Metadaten
```bash
# JSON-Metadaten pro Session
cat Terminal-Recordings/session_*.meta
```

---

## 🔧 Konfiguration

### Docker-Compose
```yaml
ports:
  - "2222:22"        # SSH-Port (extern:intern)

volumes:
  - ./Terminal-Recordings:/tmp/.systemd-private
  - ./Systemlogs:/var/log/auth
  - ./PCAP-Dateien:/var/log/.journal

resources:
  limits:
    cpus: '0.50'     # Max 50% CPU
    memory: 512M     # Max 512MB RAM
```

### Credentials
```bash
# Im Container (absichtlich schwach):
user:password
root:root
```

---

## 🛡️ Wie es funktioniert

### 1. Container-Start
```
startup-script startet:
├─ rsyslog    → SSH-Logs sammeln
├─ tcpdump    → Network-Traffic capturen
└─ sshd       → SSH-Server
```

### 2. SSH-Login
```
Angreifer verbindet sich
    ↓
sshd_config: ForceCommand /opt/myscripts/session_wrapper.sh
    ↓
session_wrapper.sh:
  1. Session-ID generieren
  2. Metadaten sammeln (IP, Port, User, Zeit)
  3. Discord-Alert senden (alert.sh)
  4. asciinema starten
  5. User-Shell starten
    ↓
Alles wird aufgezeichnet!
```

### 3. Bei Exit
```
Shell schließt
    ↓
asciinema stoppt
    ↓
.cast Datei wird auf Host gespeichert
    ↓
Session-Metadaten in .meta JSON
```

---

## 🎭 Angriffs-Szenarien (alle werden aufgezeichnet!)

| Angriff | Umgehbar? | Aufgezeichnet? |
|---------|-----------|----------------|
| Normaler Login | ❌ | ✅ |
| `bash --norc` | ❌ | ✅ |
| `ssh user@host 'ls'` | ❌ | ✅ |
| `sh` statt bash | ❌ | ✅ |
| `.bashrc` löschen | ❌ | ✅ |
| `killall asciinema` | ❌ | ✅ (beendet SSH) |

---

## 📱 Discord-Alerts

Bei jedem SSH-Login erscheint:

```
🚨 SSH Login auf Honeypot!

👤 User
   user

🌍 IP
   185.125.190.39

🔌 Port
   58281

⏰ Zeit
   2025-10-13T12:56:24+00:00

🆔 Session
   session_20251013_125624_user_141
```

---

## 🔍 Troubleshooting

### Container läuft nicht?
```bash
docker logs lemon_webapp
```

### Keine Discord-Alerts?
```bash
# Webhook-URL checken
docker exec lemon_webapp cat /opt/myscripts/alert.sh | grep WEBHOOK_URL

# Manuell testen
docker exec lemon_webapp /opt/myscripts/alert.sh "test" "user" "1.2.3.4" "12345" "$(date -Iseconds)"
```

### Keine Aufzeichnungen?
```bash
# Prozesse checken
docker exec lemon_webapp ps aux | grep -E "asciinema|tcpdump|rsyslog"

# Logs checken
ls -la Terminal-Recordings/
ls -la Systemlogs/
```

---

## 🚧 Erweiterte Nutzung

### Weitere Alerts hinzufügen
```bash
# In session_wrapper.sh erweitern:
# - sudo-Nutzung
# - wget/curl Downloads
# - Backdoor-Versuche
```

### Automatische Analyse
```bash
# Sessions automatisch auswerten
for cast in Terminal-Recordings/*.cast; do
  echo "=== $cast ==="
  asciinema cat "$cast" | grep -E "wget|curl|nc|nmap"
done
```

### Geolocation hinzufügen
```bash
# In alert.sh IP-Lookup einbauen:
COUNTRY=$(curl -s "https://ipapi.co/$SOURCE_IP/country_name/")
```

---

## 📈 Statistiken

```bash
# Anzahl Sessions
ls Terminal-Recordings/*.cast | wc -l

# Unique IPs
grep "Accepted password" Systemlogs/auth.log | awk '{print $11}' | sort -u

# Top Angreifer
grep "Accepted password" Systemlogs/auth.log | awk '{print $11}' | sort | uniq -c | sort -rn | head -10
```