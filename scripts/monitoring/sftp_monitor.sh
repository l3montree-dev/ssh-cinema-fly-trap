#!/bin/bash
# SFTP Upload Monitor für Honeypot

WEBHOOK_URL="https://discord.com/api/webhooks/1427282005497876520/RfJcCopb2FvcwlnBbI6URzQQX2VkhYRsK62Sg2ZuCdTRXD67UXZju4TY6QW3F_iXck0m"

LOG_FILE="/var/log/.uploads/uploads.log"
MALWARE_DIR="/var/log/.uploads/files"

# Stelle sicher, dass Verzeichnisse existieren
mkdir -p "$MALWARE_DIR"

# Funktion zum Senden von Discord-Alerts
send_alert() {
    local title="$1"
    local description="$2"
    local color="$3"

    curl -X POST "$WEBHOOK_URL" \
      -H "Content-Type: application/json" \
      -d "{
        \"embeds\": [{
          \"title\": \"$title\",
          \"description\": \"$description\",
          \"color\": $color,
          \"timestamp\": \"$(date -Iseconds)\",
          \"footer\": {
            \"text\": \"SFTP Upload Monitor\"
          }
        }]
      }" > /dev/null 2>&1
}

# Überwache syslog für SFTP-Uploads
tail -f /var/log/auth/syslog.log | while read line; do
    # Suche nach SFTP open mit WRITE (Upload)
    if echo "$line" | grep -q "sftp-server.*open.*WRITE"; then
        # Extrahiere Pfad: z.B. open "/home/user/file" flags WRITE...
        FILE_PATH=$(echo "$line" | sed -n 's/.*open "\([^"]*\)".*WRITE.*/\1/p')
        if [ -n "$FILE_PATH" ]; then
            TIMESTAMP=$(date -Iseconds)
            SESSION_ID=$(echo "$line" | grep -o 'sftp-server\[[0-9]*\]' | sed 's/sftp-server\[\([0-9]*\)\]/\1/')

            # Warte kurz, bis Upload fertig (close kommt danach)
            sleep 1

            if [ -f "$FILE_PATH" ]; then
                FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || echo "unknown")
                FILE_NAME=$(basename "$FILE_PATH")
                SAFE_NAME="${SESSION_ID}_${TIMESTAMP//:/-}_${FILE_NAME}"
                COPY_PATH="$MALWARE_DIR/$SAFE_NAME"

                # Kopiere Datei
                cp "$FILE_PATH" "$COPY_PATH" 2>/dev/null

                # Log in JSON
                echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\",\"file_path\":\"$FILE_PATH\",\"file_size\":\"$FILE_SIZE\",\"copy_path\":\"$COPY_PATH\"}" >> "$LOG_FILE"

                # Discord Alert
                DESCRIPTION="**Datei:** $FILE_PATH\n**Größe:** $FILE_SIZE Bytes\n**Kopie gespeichert:** $COPY_PATH"
                send_alert "🚨 SFTP Upload erkannt" "$DESCRIPTION" 16711680
            fi
        fi
    fi
done
