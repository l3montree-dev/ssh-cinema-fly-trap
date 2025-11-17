#!/bin/bash
# SFTP Upload Monitor für Honeypot

WEBHOOK_URL="https://discord.com/api/webhooks/1427282005497876520/RfJcCopb2FvcwlnBbI6URzQQX2VkhYRsK62Sg2ZuCdTRXD67UXZju4TY6QW3F_iXck0m"

LOG_FILE="/var/log/.uploads/uploads.log"
MALWARE_DIR="/var/log/.uploads/files"


mkdir -p "$MALWARE_DIR"


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


tail -f /var/log/auth/syslog.log | while read line; do
    if echo "$line" | grep -q "sftp-server.*close.*bytes.*written"; then
        FILE_PATH=$(echo "$line" | sed -n 's/.*close "\([^"]*\)".*bytes.*/\1/p')
        if [ -n "$FILE_PATH" ]; then
            TIMESTAMP=$(date -Iseconds)
            SESSION_ID=$(echo "$line" | sed -n 's/sftp-server\[\([0-9]*\)\].*/\1/p')

            if [ -f "$FILE_PATH" ]; then
                FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || echo "unknown")
                FILE_NAME=$(basename "$FILE_PATH")
                SAFE_NAME="${SESSION_ID}_${TIMESTAMP//:/-}_${FILE_NAME}"
                COPY_PATH="$MALWARE_DIR/$SAFE_NAME"

                cp "$FILE_PATH" "$COPY_PATH" 2>/dev/null

                echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\",\"file_path\":\"$FILE_PATH\",\"file_size\":\"$FILE_SIZE\",\"copy_path\":\"$COPY_PATH\"}" >> "$LOG_FILE"

                DESCRIPTION="**Datei:** $FILE_PATH\n**Größe:** $FILE_SIZE Bytes\n**Kopie gespeichert:** $COPY_PATH"
                send_alert "🚨 SFTP Upload erkannt" "$DESCRIPTION" 16711680
            fi
        fi
    fi
done