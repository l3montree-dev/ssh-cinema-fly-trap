#!/bin/bash
# Discord Alert - VERBESSERT

WEBHOOK_URL="https://discord.com"

SESSION_ID="$1"
USER="$2"
SOURCE_IP="$3"
SOURCE_PORT="$4"
TIMESTAMP="$5"
COMMAND="${6:-Interactive Session}"

# Icon + Titel basierend auf Command-Typ
if [ "$COMMAND" = "Interactive Session" ]; then
    EMOJI="🖥️"
    TITLE="SSH Interactive Login"
    COLOR=3447003
elif [[ "$COMMAND" =~ ^SCP ]]; then
    EMOJI="📤"
    TITLE="SCP File Transfer"
    COLOR=15844367
elif [[ "$COMMAND" =~ ^SFTP ]]; then
    EMOJI="📁"
    TITLE="SFTP Connection"
    COLOR=10181046
else
    EMOJI="⚡"
    TITLE="SSH Command Execution"
    COLOR=15158332
fi

curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"embeds\": [{
      \"title\": \"$EMOJI $TITLE\",
      \"color\": $COLOR,
      \"fields\": [
        {
          \"name\": \"👤 User\",
          \"value\": \"\`$USER\`\",
          \"inline\": true
        },
        {
          \"name\": \"🌍 Source IP\",
          \"value\": \"\`$SOURCE_IP:$SOURCE_PORT\`\",
          \"inline\": true
        },
        {
          \"name\": \"💻 Command\",
          \"value\": \"\`\`\`bash\n$COMMAND\n\`\`\`\",
          \"inline\": false
        },
        {
          \"name\": \"🆔 Session ID\",
          \"value\": \"\`$SESSION_ID\`\",
          \"inline\": false
        }
      ],
      \"timestamp\": \"$TIMESTAMP\",
      \"footer\": {
        \"text\": \"SSH Honeypot Monitor\"
      }
    }]
  }" > /dev/null 2>&1
