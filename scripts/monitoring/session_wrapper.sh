#!/bin/bash
# Session Wrapper Script

source /opt/myscripts/system.sh

SESSION_ID="session_$(date +%Y%m%d_%H%M%S)_${USER}_$$$([ -z "$SSH_ORIGINAL_COMMAND" ] && echo "_active")"
RECORDING_FILE="/tmp/.systemd-private/${SESSION_ID}.cast"

SOURCE_IP=$(echo $SSH_CONNECTION | awk '{print $1}')
SOURCE_PORT=$(echo $SSH_CONNECTION | awk '{print $2}')
DEST_IP=$(echo $SSH_CONNECTION | awk '{print $3}')
DEST_PORT=$(echo $SSH_CONNECTION | awk '{print $4}')
TIMESTAMP=$(date -Iseconds)


ESCAPED_COMMAND=$(echo "$SSH_ORIGINAL_COMMAND" | sed 's/"/\\"/g' | sed "s/'/\\'/g")

cat > "/tmp/.systemd-private/${SESSION_ID}.meta" <<EOF
{
  "session_id": "${SESSION_ID}",
  "user": "${USER}",
  "source_ip": "${SOURCE_IP}",
  "source_port": "${SOURCE_PORT}",
  "dest_ip": "${DEST_IP}",
  "dest_port": "${DEST_PORT}",
  "start_time": "$(date -Iseconds)",
  "original_command": "${ESCAPED_COMMAND}",
  "connection_type": "$([ -n "$SSH_ORIGINAL_COMMAND" ] && echo "non-interactive" || echo "interactive")"
}
EOF

USER_SHELL=$(getent passwd $USER | cut -d: -f7)
if [ -z "$USER_SHELL" ]; then
    USER_SHELL="/bin/bash"
fi

if [ -n "$SSH_ORIGINAL_COMMAND" ]; then
    
    # SCP
    if [[ "$SSH_ORIGINAL_COMMAND" =~ ^scp ]]; then
        echo "[$(date -Iseconds)] SCP: $SSH_ORIGINAL_COMMAND from $SOURCE_IP" >> "/var/log/auth/scp_transfers.log"
        /opt/myscripts/alert.sh "$SESSION_ID" "$USER" "$SOURCE_IP" "$SOURCE_PORT" "$TIMESTAMP" "SCP Upload/Download" &
        exec $SSH_ORIGINAL_COMMAND
    fi
    
    # SFTP
    if [[ "$SSH_ORIGINAL_COMMAND" =~ ^/usr/lib.*sftp-server ]]; then
        echo "[$(date -Iseconds)] SFTP from $SOURCE_IP, $SSH_ORIGINAL_COMMAND" >> "/var/log/auth/sftp_connections.log"
        /opt/myscripts/alert.sh "$SESSION_ID" "$USER" "$SOURCE_IP" "$SOURCE_PORT" "$TIMESTAMP" "SFTP Connection" &
        exec $SSH_ORIGINAL_COMMAND
    fi
    
    # Discord Alert
    /opt/myscripts/alert.sh "$SESSION_ID" "$USER" "$SOURCE_IP" "$SOURCE_PORT" "$TIMESTAMP" "${SSH_ORIGINAL_COMMAND}" &
    
    # Logging in Hintergrund
    (
        {
            echo "$ ${SSH_ORIGINAL_COMMAND}"
            eval "$SSH_ORIGINAL_COMMAND" 2>&1
        } | tee "/tmp/.output_${SESSION_ID}.txt" | asciinema rec -q --stdin "$RECORDING_FILE" -c "cat" >/dev/null 2>&1
    ) &
    
    # Command normal ausführen für Client-Output
    eval "$SSH_ORIGINAL_COMMAND"
    
else
    # Interactive Session - mit Fake-System
    /opt/myscripts/alert.sh "$SESSION_ID" "$USER" "$SOURCE_IP" "$SOURCE_PORT" "$TIMESTAMP" "Interactive Session" &
    
    # Temporäre RC-File mit Fake-Funktionen erstellen
    TMP_RC="/tmp/.bashrc_${SESSION_ID}"
    cat > "$TMP_RC" << 'RCEOF'
source /opt/myscripts/system.sh
source ~/.bashrc 2>/dev/null || true
RCEOF
    
    exec asciinema rec -q "$RECORDING_FILE" -c "/bin/bash --rcfile $TMP_RC"
fi