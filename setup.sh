#!/bin/bash

# PPDB Rank Checker Setup Script
# This script helps set up the PPDB Rank Checker by:
# 1. Creating the .env file
# 2. Installing dependencies
# 3. Setting up the cron job

echo "=== PPDB Rank Checker Setup ==="
echo "This script will help you set up the PPDB Rank Checker."

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check dependencies
echo -e "\nChecking dependencies..."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. This is required for JSON parsing."
    echo "To install jq:"
    echo "  - On Ubuntu/Debian: sudo apt-get install jq"
    echo "  - On CentOS/RHEL: sudo yum install jq"
    echo "  - On macOS: brew install jq"
    echo "Please install jq and run this script again."
    exit 1
else
    echo "✓ jq is installed."
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "curl is not installed. This is required for API requests."
    echo "To install curl:"
    echo "  - On Ubuntu/Debian: sudo apt-get install curl"
    echo "  - On CentOS/RHEL: sudo yum install curl"
    echo "  - On macOS: brew install curl"
    echo "Please install curl and run this script again."
    exit 1
else
    echo "✓ curl is installed."
fi

# Create .env file if it doesn't exist
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo -e "\n.env file already exists. Skipping creation."
else
    echo -e "\nCreating .env file..."

    # Get inputs from user
    read -p "Enter student name: " student_name
    read -p "Enter Telegram Bot Token: " bot_token
    read -p "Enter Telegram Chat ID: " chat_id
    read -p "Enter PPDB AUTH_TOKEN (sensitive - will be hidden): " -s auth_token
    echo ""
    read -p "Enter PPDB PENGGUNA_ID: " pengguna_id

    # Create .env file
    cat > "$SCRIPT_DIR/.env" << EOL
NAMA_ANAK="$student_name"
BOT_TOKEN="$bot_token"
CHAT_ID="$chat_id"
AUTH_TOKEN="$auth_token"
PENGGUNA_ID="$pengguna_id"
EOL

    echo ".env file created successfully."
fi

# Make the script executable
chmod +x "$SCRIPT_DIR/check_peringkat.sh"
echo -e "\nMade check_peringkat.sh executable."

# Test run the script
echo -e "\nTesting the script..."
"$SCRIPT_DIR/check_peringkat.sh"

# Set up cron job
echo -e "\nWould you like to set up a cron job to run the script automatically? (y/n)"
read setup_cron

if [[ "$setup_cron" == "y" || "$setup_cron" == "Y" ]]; then
    echo "How often would you like to check for rank changes?"
    echo "1) Every hour"
    echo "2) Every 6 hours"
    echo "3) Every 12 hours"
    echo "4) Once a day"
    echo "5) Custom"
    read cron_choice

    case $cron_choice in
        1) cron_schedule="0 * * * *" ;;
        2) cron_schedule="0 */6 * * *" ;;
        3) cron_schedule="0 */12 * * *" ;;
        4) cron_schedule="0 12 * * *" ;;
        5)
            echo "Enter custom cron schedule (in crontab format, e.g., '*/30 * * * *' for every 30 minutes):"
            read cron_schedule
            ;;
        *)
            echo "Invalid choice. Using hourly schedule."
            cron_schedule="0 * * * *"
            ;;
    esac

    # Add to crontab
    (crontab -l 2>/dev/null || echo "") | grep -v "check_peringkat.sh" > /tmp/crontab.tmp
    echo "$cron_schedule $SCRIPT_DIR/check_peringkat.sh" >> /tmp/crontab.tmp
    crontab /tmp/crontab.tmp
    rm /tmp/crontab.tmp

    echo "Cron job set up successfully. The script will run: $cron_schedule"
else
    echo "Skipping cron job setup."
    echo "To run the script manually: $SCRIPT_DIR/check_peringkat.sh"
fi

echo -e "\nSetup complete! The PPDB Rank Checker is now ready to use."
echo "If you want to see more information, check the README.md file."
