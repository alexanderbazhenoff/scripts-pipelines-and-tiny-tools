# Send message via Telegram Bot

Parameterized script to send a message via Telegram bot.

1. Register Telegram bot, get API TOKEN, add them to your chat and get CHAT ID.
See: [official Telegram instruction](https://core.telegram.org/bots/tutorial)
2. Run it with your API TOKEN and CHAT ID to send a MESSAGE, e.g.:

   ```bash
   TELEGRAM_API_TOKEN="<API TOKEN>" ./send_message_via_telegram_bot.py 'Your message' -c '<CHAT ID>'"
   ```

   or pass your API TOKEN via `-o` key (not recommended, but also possible):

   ```bash
   ./send_message_via_telegram_bot.py 'Your message' -c '<CHAT ID>' -o '<API TOKEN>'
   ```

3. To get info about other possible options:

   ```bash
   ./send_message_via_telegram_bot.py -h
   ```
