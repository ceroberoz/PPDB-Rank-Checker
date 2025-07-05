# Setting up a Telegram Bot for PPDB Rank Notifications

This guide will walk you through the process of creating a Telegram bot and configuring it to work with the PPDB Rank Checker script.

## Step 1: Creating a Telegram Bot

1. Open Telegram and search for **@BotFather**
2. Start a chat with BotFather by clicking the "Start" button
3. Send the command `/newbot` to create a new bot
4. Follow the prompts:
   - Provide a name for your bot (e.g., "My PPDB Rank Checker")
   - Provide a username for your bot (must end with "bot", e.g., "my_ppdb_rank_bot")
5. BotFather will give you a token for your new bot. It looks something like:
   ```
   123456789:ABCDefGhIJKlmNoPQRsTUVwxyZ
   ```
6. **Important:** Keep this token secure! This is what you'll use in your `.env` file as the `BOT_TOKEN`.

## Step 2: Getting Your Chat ID

To send messages to yourself from the bot, you need to know your Telegram Chat ID:

1. Open Telegram and search for **@userinfobot**
2. Start a chat with this bot by clicking the "Start" button
3. The bot will automatically respond with your information, including your Chat ID
4. This numeric ID (e.g., `123456789`) is what you'll use in your `.env` file as the `CHAT_ID`

Alternatively, you can also:

1. Start a conversation with your newly created bot
2. Send any message to the bot
3. Visit the following URL in your browser (replace with your bot token):
   ```
   https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   ```
4. Look for the `"chat":{"id":123456789}` value in the response - this is your Chat ID

## Step 3: Configuring Your Bot (Optional)

You can customize your bot further with BotFather:

1. To set a profile picture for your bot: `/setuserpic`
2. To set a description: `/setdescription`
3. To set up commands that show in the menu: `/setcommands`

For a PPDB rank checking bot, you might set these commands:
```
status - Check current rank status
help - Get help with using the bot
about - About this bot
```

## Step 4: Testing Your Bot

1. Make sure your bot token and chat ID are correctly set in your `.env` file
2. Run the `check_peringkat.sh` script manually
3. You should receive a message from your bot with the current rank information

## Step 5: Security Considerations

- Never share your bot token publicly
- The bot you created can be messaged by anyone who finds it, but it will only send notifications to the chat ID you configured
- For additional security, you can use BotFather's `/setprivacy` command to enable privacy mode

## Troubleshooting

If you're not receiving messages from your bot:

1. Make sure you've started a conversation with your bot
2. Verify your bot token and chat ID are correct in the `.env` file
3. Check if your bot is blocked or the chat is muted
4. Run the script with full output (remove redirecting to `/dev/null`) to see any error messages

## Additional Features

Once your bot is working, you might want to enhance it:

- Create additional commands that the bot can respond to
- Set up interactive buttons for common actions
- Create a group chat and add your bot to notify multiple people

For more advanced features, you'll need to modify the script to handle incoming messages and commands from Telegram.