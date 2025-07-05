# PPDB Rank Checker

A simple automated system to monitor and notify about changes in PPDB (Penerimaan Peserta Didik Baru - Student Admission) ranking for the Bogor Regency school admission system.

## Overview

This tool periodically checks a student's current rank in the PPDB system and sends a notification via Telegram when the rank changes. It's particularly useful during the school admission period when rankings can change frequently due to other students joining or leaving the admission process.

## Features

- Automatically fetches the latest ranking from the PPDB Bogor Regency system
- Compares with previously recorded rank
- Sends notifications via Telegram when changes are detected
- Stores the latest rank for future comparison
- Includes the total number of available slots in notifications

## Limitation

- Due to AUTH_TOKEN expiration time, the tool may not function correctly after the token expires (~ 24 hours). Therefore, it is recommended to regularly update the AUTH_TOKEN to ensure the tool's functionality.

## Requirements

- Bash environment
- `curl` for API requests
- `jq` for JSON parsing
- Telegram Bot token and Chat ID

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/ceroberoz/ppdb-rank-checker.git
   cd ppdb-rank-checker
   ```

2. Create a `.env` file with the following variables:
   ```
   NAMA_ANAK="Student Name"
   BOT_TOKEN="your_telegram_bot_token"
   CHAT_ID="your_telegram_chat_id"
   AUTH_TOKEN="your_ppdb_auth_token"
   PENGGUNA_ID="your_ppdb_user_id"
   ```

3. Make the script executable:
   ```bash
   chmod +x check_peringkat.sh
   ```

4. Test run the script:
   ```bash
   ./check_peringkat.sh
   ```

## Setting up as a Cron Job

To automatically check for rank changes, set up a cron job to run the script at regular intervals.

1. Open your crontab file:
   ```bash
   crontab -e
   ```

2. Add a line to run the script every hour (or adjust as needed):
   ```
   0 * * * * /path/to/ppdb-rank-checker/check_peringkat.sh
   ```

## Security Note

- The `.env` file contains sensitive information and is included in `.gitignore` to prevent accidental exposure
- Never commit the `.env` file or the `last_peringkat.txt` file to your repository
- The AUTH_TOKEN is sensitive and should be kept secure

## Obtaining Required Values

### Getting a Telegram Bot Token:
1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Follow the instructions to create a new bot
3. Save the provided token

### Finding Your Telegram Chat ID:
1. Message [@userinfobot](https://t.me/userinfobot) on Telegram
2. It will reply with your chat ID

### PPDB Auth Token and User ID:
These values must be obtained from the PPDB Bogor Regency system:
1. Log in to the PPDB system
2. Use browser developer tools to inspect network requests
3. Find the API request containing your authentication token and user ID

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This tool is not officially affiliated with the PPDB Bogor Regency system. It is a personal utility created to help monitor student rankings during the admission process.
