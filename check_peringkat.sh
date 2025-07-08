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

# --- Script Best Practices ---
# Exit immediately if a command exits with a non-zero status.
set -o errexit
# Treat unset variables as an error when substituting.
set -o nounset
# Pipelines return the exit status of the last command to fail.
set -o pipefail

# --- Constants and Setup ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LAST_VALUE_FILE="$SCRIPT_DIR/last_peringkat.txt"
LOG_FILE="$SCRIPT_DIR/rank_change_log.txt"

# --- Functions ---

# Log messages to stdout with a timestamp.
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"
}

# Load environment variables from .env file.
load_env() {
  if [ -f "$SCRIPT_DIR/.env" ]; then
    set -o allexport
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/.env"
    set +o allexport
  else
    log "Error: .env file not found at $SCRIPT_DIR/.env!"
    exit 1
  fi

  # Check if required variables are set
  if [ -z "${AUTH_TOKEN:-}" ] || [ -z "${PENGGUNA_ID:-}" ] || [ -z "${BOT_TOKEN:-}" ] || [ -z "${CHAT_ID:-}" ]; then
    log "Error: Missing required environment variables in $SCRIPT_DIR/.env!"
    log "Required variables: AUTH_TOKEN, PENGGUNA_ID, BOT_TOKEN, CHAT_ID"
    exit 1
  fi
}

# Fetch rank data from the PPDB API.
fetch_rank_data() {
  local response
  response=$(curl -s 'https://spmb.bogorkab.go.id/v2/ppdb-service/pendaftaran/pendaftaranDaftarPilihanSekolah' \
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

  if [ -z "$response" ]; then
    log "Error: API request failed. Received empty response from server."
    exit 1
  fi

  # Check if the API request was successful
  if [ "$(echo "$response" | jq -r '.status_code')" != "200" ]; then
    log "Error: API request failed with response: $response"
    # Check for common token expiration error
    if echo "$response" | jq -e '.message == "Token is Expired"' > /dev/null; then
        log "Hint: The AUTH_TOKEN may have expired. Please update it in the .env file."
    fi
    exit 1
  fi

  echo "$response"
}

# Send a notification message via Telegram.
send_telegram_notification() {
  local message="$1"
  
  local response
  response=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=${message}")

  # Check if Telegram notification was sent successfully using jq
  if ! echo "$response" | jq -e '.ok == true' > /dev/null; then
    log "Warning: Failed to send Telegram notification. Response: $response"
  else
    log "Telegram notification sent successfully."
  fi
}

# --- Main Logic ---

main() {
  load_env

  log "Fetching current rank..."
  local json_data
  json_data=$(fetch_rank_data)

  # Extract peringkat and kuota
  local current_peringkat
  current_peringkat=$(echo "$json_data" | jq -r '.data[0].peringkat')
  local current_kuota
  current_kuota=$(echo "$json_data" | jq -r '.data[0].kuota')

  # Check if peringkat was successfully extracted
  if [ -z "$current_peringkat" ] || [ "$current_peringkat" = "null" ]; then
    log "Error: Could not extract 'peringkat' from API response. Response: $json_data"
    exit 1
  fi

  # Read last value (if file doesn't exist, assume empty)
  local last_peringkat
  last_peringkat=$(cat "$LAST_VALUE_FILE" 2>/dev/null || echo "")

  log "Current rank: $current_peringkat of $current_kuota. Last seen rank: ${last_peringkat:-N/A}."

  # Compare current vs last
  if [ "$current_peringkat" != "$last_peringkat" ]; then
    log "Rank changed from ${last_peringkat:-N/A} to $current_peringkat of $current_kuota. Notifying..."

    # Save new value
    echo "$current_peringkat" > "$LAST_VALUE_FILE"

    # Log the change to the dedicated log file
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Rank changed from ${last_peringkat:-N/A} to $current_peringkat of $current_kuota" >> "$LOG_FILE"

    # Create notification message
    local message
    message="${NAMA_ANAK:-Student} - rank changed to $current_peringkat of $current_kuota"

    # Send Telegram notification
    send_telegram_notification "$message"
  else
    log "No rank change detected."
  fi
}

# Run the main function
main
