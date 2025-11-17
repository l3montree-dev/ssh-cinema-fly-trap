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


declare -A SESSION_USER

tail -F /var/log/auth/syslog.log | while read -r line; do

    if [[ "$line" =~ sftp-server\[([0-9]+)\]:\ session\ opened\ for\ local\ user\ ([^[:space:]]+) ]]; then
        SESSION_ID="${BASH_REMATCH[1]}"
        USERNAME="${BASH_REMATCH[2]}"
        SESSION_USER["$SESSION_ID"]="$USERNAME"
        continue
    fi

    if echo "$line" | grep -Eq 'sftp-server.*close.*bytes read [0-9]+ written [0-9]+'; then
        FILE_PATH=$(echo "$line" | sed -n 's/.*close "\(.*\)".*bytes.*/\1/p')
        SESSION_ID=$(echo "$line" | sed -n 's/sftp-server\[\([0-9]*\)\].*/\1/p')
        USERNAME="${SESSION_USER[$SESSION_ID]}"

        if [[ -z "$USERNAME" ]]; then
            USERNAME="unknown"
        fi

        TIMESTAMP=$(date -Iseconds)

        USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)
        if [[ -z "$USER_HOME" ]]; then
            USER_HOME="$HOME"  # Fallback
        fi

        if [[ "$FILE_PATH" == ./* ]]; then
            FILE_PATH="$USER_HOME/${FILE_PATH:2}"
        elif [[ "$FILE_PATH" != /* ]]; then
            FILE_PATH="$USER_HOME/$FILE_PATH"
        fi

        if [ -f "$FILE_PATH" ]; then
            FILE_SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || echo "unknown")
            FILE_NAME=$(basename "$FILE_PATH")
            SAFE_NAME="${SESSION_ID}_${TIMESTAMP//:/-}_${FILE_NAME}"
            COPY_PATH="$MALWARE_DIR/$SAFE_NAME"

            mkdir -p "$MALWARE_DIR"
            cp "$FILE_PATH" "$COPY_PATH" 2>/dev/null

            echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\",\"username\":\"$USERNAME\",\"file_path\":\"$FILE_PATH\",\"file_size\":\"$FILE_SIZE\",\"copy_path\":\"$COPY_PATH\"}" >> "$LOG_FILE"

            DESCRIPTION="**Datei:** $FILE_PATH\n**Größe:** $FILE_SIZE Bytes\n**Kopie gespeichert:** $COPY_PATH"
            send_alert "🚨 SFTP Upload erkannt" "$DESCRIPTION" 16711680
        fi
    fi

done