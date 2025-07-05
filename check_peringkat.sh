#!/bin/bash

# Script to check and notify about PPDB rank changes
#
# This script fetches the current rank from the PPDB system, compares it with the
# previously stored rank, and sends a notification via Telegram if there's a change.
#
# Environment variables required in .env file:
# - AUTH_TOKEN: Bearer token for API authentication
# - PENGGUNA_ID: User ID for the student
# - BOT_TOKEN: Telegram bot token
# - CHAT_ID: Telegram chat ID to send notifications to
#
# Author: Perdana Hadi Sanjaya
# Date: July 2025

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# File to store the last seen value
LAST_VALUE_FILE="$SCRIPT_DIR/last_peringkat.txt"

# Load environment variables from .env file
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
else
  echo "Error: .env file not found at $SCRIPT_DIR/.env!"
  exit 1
fi

# Check if required variables are set
if [ -z "$AUTH_TOKEN" ] || [ -z "$PENGGUNA_ID" ] || [ -z "$BOT_TOKEN" ] || [ -z "$CHAT_ID" ]; then
  echo "Error: Missing required environment variables in $SCRIPT_DIR/.env!"
  echo "Required variables: AUTH_TOKEN, PENGGUNA_ID, BOT_TOKEN, CHAT_ID"
  exit 1
fi

# Fetch the JSON
JSON=$(curl -s 'https://spmb.bogorkab.go.id/v2/ppdb-service/pendaftaran/pendaftaranDaftarPilihanSekolah' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H "Authorization: Bearer ${AUTH_TOKEN}" \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://spmb.bogorkab.go.id' \
  -H 'Referer: https://spmb.bogorkab.go.id/' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36 CrKey/1.54.250320' \
  --data-raw "{\"pengguna_id\":\"${PENGGUNA_ID}\"}")

# Check if the API request was successful
if [ "$(echo "$JSON" | jq -r '.status_code')" != "200" ]; then
  echo "Error: API request failed with response: $JSON"
  exit 1
fi

# Extract peringkat
CURRENT_PERINGKAT=$(echo "$JSON" | jq -r '.data[0].peringkat')

# Extract kuota
CURRENT_KUOTA=$(echo "$JSON" | jq -r '.data[0].kuota')

# Read last value (if file doesn't exist, assume empty)
if [ -f "$LAST_VALUE_FILE" ]; then
  LAST_PERINGKAT=$(cat "$LAST_VALUE_FILE")
else
  LAST_PERINGKAT=""
fi

# Check if peringkat was successfully extracted
if [ -z "$CURRENT_PERINGKAT" ] || [ "$CURRENT_PERINGKAT" = "null" ]; then
  echo "Error: Could not extract peringkat from API response"
  exit 1
fi

# Compare current vs last
if [ "$CURRENT_PERINGKAT" != "$LAST_PERINGKAT" ]; then
  # Save new value
  echo "$CURRENT_PERINGKAT" > "$LAST_VALUE_FILE"

  # Log the change
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Rank changed from ${LAST_PERINGKAT:-N/A} to $CURRENT_PERINGKAT of $CURRENT_KUOTA" >> "$SCRIPT_DIR/rank_change_log.txt"

  # Create notification message
  MESSAGE="$NAMA_ANAK - rank changed to $CURRENT_PERINGKAT of $CURRENT_KUOTA"

  # Send Telegram notification
  TELEGRAM_RESPONSE=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${MESSAGE}")

  # Check if Telegram notification was sent successfully
  if [[ "$TELEGRAM_RESPONSE" != *"\"ok\":true"* ]]; then
    echo "Warning: Failed to send Telegram notification: $TELEGRAM_RESPONSE"
  fi
fi
