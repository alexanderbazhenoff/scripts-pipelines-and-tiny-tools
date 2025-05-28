# Send a Message via Telegram Bot

A parameterized script to send messages using a Telegram bot.

1. Register a Telegram bot, obtain the API token, add it to your chat, and retrieve the chat ID.  
   See: [Official Telegram Instructions](https://core.telegram.org/bots/tutorial).
2. Run the script with your API token and chat ID to send a message, for example:

   ```bash
   TELEGRAM_API_TOKEN="<API_TOKEN>" ./send_message_via_telegram_bot.py 'Your message' -c '<CHAT_ID>'
   ```

   Alternatively, you can pass the API token using the -o flag (not recommended but supported):

   ```bash
   ./send_message_via_telegram_bot.py 'Your message' -c '<CHAT ID>' -o '<API TOKEN>'
   ```

3. To view all available options, run:

   ```bash
   ./send_message_via_telegram_bot.py -h
   ```
