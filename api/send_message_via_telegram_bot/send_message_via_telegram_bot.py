#!/usr/bin/env python3

"""
Send a message via Telegram Bot.
Writen by Aleksandr Bazhenov, 2023.

Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""

import argparse
import logging
import os
import sys

import requests

API_TOKEN = None
API_URL = "https://api.telegram.org/bot"
HELP_URL = "https://core.telegram.org/bots"


def parse_arguments():
    """Command-line arguments parser"""

    def pretty_formatter(prog):
        return argparse.HelpFormatter(prog)

    parser = argparse.ArgumentParser(formatter_class=pretty_formatter)
    parser.add_argument("message", metavar="MESSAGE", help="Message to send.")
    parser.add_argument(
        "-c",
        "--chat_id",
        type=str,
        help=f"Chat ID. See: {HELP_URL}",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--token",
        type=str,
        default=os.getenv("TELEGRAM_API_TOKEN", None),
        help="Bot Token (to override TELEGRAM_API_TOKEN environment variable).",
    )
    parser.add_argument(
        "-T",
        "--message_thread_id",
        type=int,
        default=0,
        help=(
            "Message thread ID. Unique identifier for the target message "
            "thread (topic) of the forum; for forum supergroups only."
        ),
    )
    parser.add_argument(
        "-p",
        "--parse_mode",
        type=str,
        nargs="?",
        default="markdown",
        choices=["markdown", "html"],
        help="Parse mode (default: markdown).",
    )
    parser.add_argument(
        "-t",
        "--timeout",
        type=int,
        default=5,
        help="Timeout in seconds to message send (default: 5).",
    )
    parser.add_argument(
        "-n",
        "--disable_notification",
        type=bool,
        default=False,
        help=(
            "Sends the message silently (default: False). "
            "Users will receive a notification with no sound."
        ),
    )
    parser.add_argument(
        "-P",
        "--protect_content",
        type=bool,
        default=False,
        help=(
            "Protects the contents of the sent message from forwarding and saving (default: False)."
        ),
    )
    parser.add_argument(
        "-l",
        "--link_preview_options",
        type=str,
        default="",
        help=(
            f'Link preview generation options for the message (default: ""). '
            f"See: {HELP_URL}/api#linkpreviewoptions"
        ),
    )
    parser.add_argument(
        "-r",
        "--reply_parameters",
        type=str,
        default="",
        help=(
            f'Description of the message to reply to (Default: ""). '
            f"See: {HELP_URL}/api#replyparameters"
        ),
    )
    args = parser.parse_args()
    if not args.token:
        raise log_value_error(
            "API token required. Please specify them via 'TELEGRAM_API_TOKEN' "
            "environment variable or '-o' ('--token') argument."
        )
    return args


def log_value_error(msg):
    """Logging value error function wrapper."""

    logging.critical(msg)
    return ValueError


def send_message(request_url, args):
    """Send a message to a telegram channel"""

    try:
        response = requests.post(
            request_url,
            json={
                "chat_id": args.chat_id,
                "text": args.message,
                "message_thread_id": args.message_thread_id,
                "parse_mode": args.parse_mode,
                "disable_notification": args.disable_notification,
                "protect_content": args.protect_content,
                "link_preview_options": args.link_preview_options,
                "reply_parameters": args.reply_parameters,
            },
            timeout=args.timeout,
        )
        response.raise_for_status()
        logging.info("Message sent, response: %s", response.text)
    except Exception as err:  # pylint: disable=broad-exception-caught
        logging.error("Error sending request:", exc_info=err)


if __name__ == "__main__":
    ar = parse_arguments()
    logging.basicConfig(
        stream=sys.stdout,
        level=logging.INFO,
        format="%(asctime)s.%(msecs)03d %(module)s %(levelname)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    REQUEST_URL = f"{API_URL}{ar.token}/sendMessage"
    send_message(REQUEST_URL, ar)
