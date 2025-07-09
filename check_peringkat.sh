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

# --- Configuration ---
# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Pipelines return the exit status of the last command to exit with a non-zero status.
set -o pipefail

# --- Constants and Setup ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LAST_VALUE_FILE="$SCRIPT_DIR/last_peringkat.txt"
ACTIVITY_LOG_FILE="$SCRIPT_DIR/activity.log"

# --- Functions ---

# Log messages to a file and stdout.
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$ACTIVITY_LOG_FILE"
}

# Load environment variables from .env file.
load_env() {
  if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
  else
    log "Error: .env file not found at $SCRIPT_DIR/.env!"
    exit 1
  fi

  # Check for required variables
  if [ -z "${AUTH_TOKEN-}" ] || [ -z "${PENGGUNA_ID-}" ] || [ -z "${BOT_TOKEN-}" ] || [ -z "${CHAT_ID-}" ]; then
    log "Error: Missing required environment variables in .env!"
    log "Required: AUTH_TOKEN, PENGGUNA_ID, BOT_TOKEN, CHAT_ID"
    exit 1
  fi
}

# Fetch rank data from the API.
fetch_rank_data() {
  curl -s 'https://spmb.bogorkab.go.id/v2/ppdb-service/pendaftaran/pendaftaranDaftarPilihanSekolah' \
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
    --data-raw "{\"pengguna_id\":\"${PENGGUNA_ID}\"}"
}

# Send a notification message via Telegram.
send_telegram_notification() {
  local message="$1"
  local response
  response=$(curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -d "chat_id=${CHAT_ID}" \
    -d "text=${message}")

  if [[ "$response" != *"\"ok\":true"* ]]; then
    log "Warning: Failed to send Telegram notification: $response"
  else
    log "Telegram notification sent successfully."
  fi
}

# --- Main Logic ---

main() {
  # Ensure data and log files exist
  touch "$LAST_VALUE_FILE" "$ACTIVITY_LOG_FILE" 2>/dev/null

  load_env

  log "Fetching current rank..."
  local json_response
  json_response=$(fetch_rank_data)

  # Validate API response
  if ! echo "$json_response" | jq -e '.status_code == 200' > /dev/null; then
    log "Error: API request failed. Response: $json_response"
    send_telegram_notification "Error: PPDB rank check API request failed."
    exit 1
  fi

  # Extract data
  local current_peringkat
  current_peringkat=$(echo "$json_response" | jq -r '.data[0].peringkat')
  local current_kuota
  current_kuota=$(echo "$json_response" | jq -r '.data[0].kuota')

  # Validate extracted data
  if [ -z "$current_peringkat" ] || [ "$current_peringkat" = "null" ]; then
    log "Error: Could not extract rank from API response. It might be expired token"
    send_telegram_notification "Error: Could not extract rank. The auth token may have expired."
    exit 1
  fi

  log "Successfully fetched rank: $current_peringkat of $current_kuota"

  # Read last known rank
  local last_peringkat=""
  if [ -f "$LAST_VALUE_FILE" ]; then
    last_peringkat=$(cat "$LAST_VALUE_FILE")
  fi

  # Compare and notify if changed
  if [ "$current_peringkat" != "$last_peringkat" ]; then
    log "Rank changed from ${last_peringkat:-N/A} to $current_peringkat of $current_kuota"

    # Save new value
    echo "$current_peringkat" > "$LAST_VALUE_FILE"

    # The change is already recorded by the main log function.

    # Create notification message
    local message
    message="${NAMA_ANAK:-Student} - Rank changed to $current_peringkat of $current_kuota"

    send_telegram_notification "$message"
  else
    log "Rank remains unchanged at $current_peringkat of $current_kuota. No notification sent."
  fi
}

# --- Script Execution ---
main "$@"
