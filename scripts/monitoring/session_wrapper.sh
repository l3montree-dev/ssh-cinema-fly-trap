#!/bin/bash
# Session Wrapper für manipulationssichere Aufzeichnung

# Session-ID generieren
SESSION_ID="session_$(date +%Y%m%d_%H%M%S)_${USER}_$$"
RECORDING_FILE="/tmp/.systemd-private/${SESSION_ID}.cast"

# Session-Metadaten sammeln
SOURCE_IP=$(echo $SSH_CONNECTION | awk '{print $1}')
SOURCE_PORT=$(echo $SSH_CONNECTION | awk '{print $2}')
DEST_IP=$(echo $SSH_CONNECTION | awk '{print $3}')
DEST_PORT=$(echo $SSH_CONNECTION | awk '{print $4}')
TIMESTAMP=$(date -Iseconds)

# Metadaten-File erstellen (für spätere Analyse)
cat > "/tmp/.systemd-private/${SESSION_ID}.meta" <<EOF
{
  "session_id": "${SESSION_ID}",
  "user": "${USER}",
  "source_ip": "${SOURCE_IP}",
  "source_port": "${SOURCE_PORT}",
  "dest_ip": "${DEST_IP}",
  "dest_port": "${DEST_PORT}",
  "start_time": "$(date -Iseconds)",
  "original_command": "${SSH_ORIGINAL_COMMAND}"
}
EOF

# 🚨 DISCORD ALERT SENDEN
/opt/myscripts/alert.sh "$SESSION_ID" "$USER" "$SOURCE_IP" "$SOURCE_PORT" "$TIMESTAMP" &

# User's Shell herausfinden
USER_SHELL=$(getent passwd $USER | cut -d: -f7)
if [ -z "$USER_SHELL" ]; then
    USER_SHELL="/bin/bash"
fi

# Wenn non-interactive SSH:
if [ -n "$SSH_ORIGINAL_COMMAND" ]; then
    # Command direkt ausführen, aber durch asciinema recorden
    exec asciinema rec -q --stdin -c "$SSH_ORIGINAL_COMMAND" "$RECORDING_FILE"
else
    # Interactive Session: Shell starten mit asciinema
    exec asciinema rec -q "$RECORDING_FILE" -c "$USER_SHELL"
fi