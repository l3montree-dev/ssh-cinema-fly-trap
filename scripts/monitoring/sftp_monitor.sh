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

declare -A SESSION_USERS

tail -f /var/log/auth/syslog.log | while read line; do

    if echo "$line" | grep -q "sftp-server.*opened.*"; then
        USERNAME=$(echo "$line" | sed -n 's/.*opened for local user \([^ ]*\) from.*/\1/p')
        SESSION_ID=$(echo "$line" | grep -oP 'sftp-server\[\K[0-9]+(?=\])')
        SESSION_USERS[$SESSION_ID]="$USERNAME"
    fi

    if echo "$line" | grep -q "sftp-server.*close.*bytes.*written"; then
        RELATIVE_PATH=$(echo "$line" | sed -n 's/.*close "\([^"]*\)".*bytes.*/\1/p')

        if [ -n "$RELATIVE_PATH" ]; then
            TIMESTAMP=$(date -Iseconds)
            SESSION_ID=$(echo "$line" | grep -oP 'sftp-server\[\K[0-9]+(?=\])')
            USERNAME="${SESSION_USERS[$SESSION_ID]:-unknown}"
            
            if [[ "$RELATIVE_PATH" == /* ]]; then
                FULL_PATH="$RELATIVE_PATH"
            else
                if [ "$USERNAME" == "root" ]; then
                    FULL_PATH="/root/$RELATIVE_PATH"
                else
                    FULL_PATH="/home/$USERNAME/$RELATIVE_PATH"
                fi
            fi

            if [ -f "$FULL_PATH" ]; then
                FILE_SIZE=$(stat -c%s "$FULL_PATH" 2>/dev/null || echo "unknown")
                SAFE_RELATIVE=$(echo "$RELATIVE_PATH" | tr '/' '_')
                SAFE_NAME="${SESSION_ID}_${TIMESTAMP//:/-}_${SAFE_RELATIVE}"
                COPY_PATH="$MALWARE_DIR/$SAFE_NAME"

                cp "$FULL_PATH" "$COPY_PATH" 2>/dev/null

                echo "{\"timestamp\":\"$TIMESTAMP\",\"session_id\":\"$SESSION_ID\",\"file_path\":\"$FULL_PATH\",\"file_size\":\"$FILE_SIZE\",\"copy_path\":\"$COPY_PATH\"}" >> "$LOG_FILE"

                DESCRIPTION="**Datei:** $FULL_PATH\n**Größe:** $FILE_SIZE Bytes\n**Kopie gespeichert:** $COPY_PATH"
                send_alert "🚨 SFTP Upload erkannt" "$DESCRIPTION" 16711680
            fi
        fi
    fi
    if echo "$line" | grep -q "sftp-server.*session closed"; then
        SESSION_ID=$(echo "$line" | grep -oP 'sftp-server\[\K[0-9]+(?=\])')
        unset SESSION_USERS[$SESSION_ID]
    fi
done