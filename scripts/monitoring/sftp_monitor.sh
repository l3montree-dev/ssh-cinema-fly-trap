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


tail -F /var/log/auth/auth.log /var/log/auth/syslog.log | while read line; do

    if echo "$line" | grep -q "sftp-server.*close.*bytes.*written"; then

        FILE_PATH=$(echo "$line" | sed -n 's/.*close "\([^"]*\)".*/\1/p')
        PID=$(echo "$line" | sed -n 's/.*sftp-server\[\([0-9]*\)\].*/\1/p')
        CHROOT=$(readlink "/proc/$PID/cwd" 2>/dev/null)

        if [ -z "$CHROOT" ]; then
            echo "[WARN] Konnte CHROOT nicht bestimmen für PID $PID"
            continue
        fi

        REAL_PATH="$CHROOT/${FILE_PATH#./}"
        TIMESTAMP=$(date -Iseconds)
        FILE_NAME=$(basename "$REAL_PATH")
        SAFE_NAME="${PID}_${TIMESTAMP//:/-}_${FILE_NAME}"
        COPY_PATH="$MALWARE_DIR/$SAFE_NAME"
        FILE_SIZE=$(stat -c%s "$REAL_PATH" 2>/dev/null || echo "unknown")

        if [ -f "$REAL_PATH" ]; then
            cp "$REAL_PATH" "$COPY_PATH"
        fi

        echo "{\"timestamp\":\"$TIMESTAMP\",\"pid\":\"$PID\",\"real_path\":\"$REAL_PATH\",\"file_size\":\"$FILE_SIZE\",\"copy\":\"$COPY_PATH\"}" >> "$LOG_FILE"

        DESCRIPTION="**Datei:** \`$REAL_PATH\`\n**Größe:** $FILE_SIZE Bytes\n**Kopie:** \`$COPY_PATH\`"
        send_alert "🚨 SFTP Upload erkannt" "$DESCRIPTION" 16711680

        echo "[INFO] Upload erkannt: $REAL_PATH"
    fi

done