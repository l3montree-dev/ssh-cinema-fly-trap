#!/bin/bash
# Discord Alert für SSH-Logins

WEBHOOK_URL="https://discord.com/api/webhooks/1427282005497876520/RfJcCopb2FvcwlnBbI6URzQQX2VkhYRsK62Sg2ZuCdTRXD67UXZju4TY6QW3F_iXck0m"

# Parameter vom Wrapper-Script
SESSION_ID="$1"
USER="$2"
SOURCE_IP="$3"
SOURCE_PORT="$4"
TIMESTAMP="$5"

# Formatierung
curl -X POST "$WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d "{
    \"embeds\": [{
      \"title\": \"🚨 SSH Login auf Honeypot!\",
      \"color\": 15158332,
      \"fields\": [
        {
          \"name\": \"👤 User\",
          \"value\": \"\`$USER\`\",
          \"inline\": false
        },
        {
          \"name\": \"🌍 IP\",
          \"value\": \"\`$SOURCE_IP\`\",
          \"inline\": false
        },
        {
          \"name\": \"🔌 Port\",
          \"value\": \"\`$SOURCE_PORT\`\",
          \"inline\": false
        },
        {
          \"name\": \"⏰ Zeit\",
          \"value\": \"$TIMESTAMP\",
          \"inline\": false
        },
        {
          \"name\": \"🆔 Session\",
          \"value\": \"\`$SESSION_ID\`\",
          \"inline\": false
        }
      ],
      \"timestamp\": \"$TIMESTAMP\"
    }]
  }" > /dev/null 2>&1