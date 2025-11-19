#!/bin/bash

MALWARE_DIR="/var/log/.uploads/inotify_malware"
WATCH_DIRS="/home/admin /root /home/user"

mkdir -p "$MALWARE_DIR"

inotifywait -m -r $WATCH_DIRS \
  -e close_write \
  --exclude '\.ssh|\.bash_history|\.bashrc' \
  --format '%w%f|%T' \
  --timefmt '%Y-%m-%d_%H-%M-%S' |
while IFS='|' read filepath timestamp; do
    if [ -f "$filepath" ]; then
        USERNAME=$(stat -c '%U' "$filepath" 2>/dev/null || echo "unknown")
        FILENAME=$(basename "$filepath")
        FILE_SIZE=$(stat -c%s "$filepath" 2>/dev/null || echo "0")
        
        SAFE_NAME="${timestamp}_${USERNAME}_${FILENAME}"
        COPY_PATH="$MALWARE_DIR/$SAFE_NAME"

        cp "$filepath" "$COPY_PATH" 2>/dev/null
    fi
done