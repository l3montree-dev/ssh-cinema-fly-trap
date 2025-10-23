#!/bin/bash
# Session Wrapper - FIXED

SESSION_ID="session_$(date +%Y%m%d_%H%M%S)_${USER}_$$"
RECORDING_FILE="/tmp/.systemd-private/${SESSION_ID}.cast"

SOURCE_IP=$(echo $SSH_CONNECTION | awk '{print $1}')
SOURCE_PORT=$(echo $SSH_CONNECTION | awk '{print $2}')
DEST_IP=$(echo $SSH_CONNECTION | awk '{print $3}')
DEST_PORT=$(echo $SSH_CONNECTION | awk '{print $4}')
TIMESTAMP=$(date -Iseconds)

cat > "/tmp/.systemd-private/${SESSION_ID}.meta" <<EOF
{
  "session_id": "${SESSION_ID}",
  "user": "${USER}",
  "source_ip": "${SOURCE_IP}",
  "source_port": "${SOURCE_PORT}",
  "dest_ip": "${DEST_IP}",
  "dest_port": "${DEST_PORT}",
  "start_time": "$(date -Iseconds)",
  "original_command": "${SSH_ORIGINAL_COMMAND}",
  "connection_type": "$([ -n "$SSH_ORIGINAL_COMMAND" ] && echo "non-interactive" || echo "interactive")"
}
EOF

USER_SHELL=$(getent passwd $USER | cut -d: -f7)
if [ -z "$USER_SHELL" ]; then
    USER_SHELL="/bin/bash"
fi

if [ -n "$SSH_ORIGINAL_COMMAND" ]; then
    
    # SCP - KEIN asciinema, nur loggen
    if [[ "$SSH_ORIGINAL_COMMAND" =~ ^scp ]]; then
        echo "[$(date -Iseconds)] SCP: $SSH_ORIGINAL_COMMAND from $SOURCE_IP" >> "/var/log/auth/scp_transfers.log"
        /opt/myscripts/alert.sh "$SESSION_ID" "$USER" "$SOURCE_IP" "$SOURCE_PORT" "$TIMESTAMP" "SCP Upload/Download" &
        exec $SSH_ORIGINAL_COMMAND
    fi
    
    # SFTP - KEIN asciinema, nur loggen
    if [[ "$SSH_ORIGINAL_COMMAND" =~ ^/usr/lib.*sftp-server ]]; then
        echo "[$(date -Iseconds)] SFTP from $SOURCE_IP" >> "/var/log/auth/sftp_connections.log"
        /opt/myscripts/alert.sh "$SESSION_ID" "$USER" "$SOURCE_IP" "$SOURCE_PORT" "$TIMESTAMP" "SFTP Connection" &
        exec $SSH_ORIGINAL_COMMAND
    fi
    
    # Normale Commands - NUR EINE Discord-Nachricht
    /opt/myscripts/alert.sh "$SESSION_ID" "$USER" "$SOURCE_IP" "$SOURCE_PORT" "$TIMESTAMP" "${SSH_ORIGINAL_COMMAND}" &
    
    TEMP_SCRIPT="/tmp/.cmd_${SESSION_ID}.sh"
    cat > "$TEMP_SCRIPT" <<'SCRIPT_EOF'
#!/bin/bash
echo "$ $SSH_ORIGINAL_COMMAND"
eval "$SSH_ORIGINAL_COMMAND"
SCRIPT_EOF
    
    chmod +x "$TEMP_SCRIPT"
    export SSH_ORIGINAL_COMMAND
    exec asciinema rec -q "$RECORDING_FILE" -c "$TEMP_SCRIPT"
    
else
    # Interactive - NUR EINE Discord-Nachricht
    /opt/myscripts/alert.sh "$SESSION_ID" "$USER" "$SOURCE_IP" "$SOURCE_PORT" "$TIMESTAMP" "Interactive Session" &
    exec asciinema rec -q "$RECORDING_FILE" -c "$USER_SHELL"
fi