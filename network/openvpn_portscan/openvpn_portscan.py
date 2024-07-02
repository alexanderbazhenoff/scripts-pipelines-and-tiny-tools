#!/usr/bin/env python3

"""
Scanning remote openvpn ports in parallel by specified ports range.
Writen by Aleksandr Bazhenov, 2024.


Usage: openvpn_portscan.py [-h] [-t TIMEOUT] HOST PORT [PORT ...]
 E.g.: openvpn_portscan.py -t 5 1.2.3.4 1190 1194


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
import ctypes
import logging
import random
import socket
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta

SEND_DATA = "\x38\x01\x00\x00\x00\x00\x00\x00\x00"


def parse_arguments():
    """Command-line arguments parser."""

    def pretty_formatter(prog):
        return argparse.HelpFormatter(prog)

    # base arguments
    parser = argparse.ArgumentParser(formatter_class=pretty_formatter)
    parser.add_argument("host", metavar="HOST", help="IP or DNS of the server")
    parser.add_argument(
        "port",
        type=int,
        metavar="PORT",
        nargs="+",
        help="Single port or space separated range.",
    )

    # optional arguments
    parser.add_argument(
        "-t",
        "--timeout",
        type=int,
        default=4,
        help="Minimum socket timeout in seconds (default: 4).",
    )
    parser.add_argument(
        "-j",
        "--timeout-jitter",
        type=int,
        default=2,
        help="Socket timeout jitter in seconds (default: 2).",
    )
    parser.add_argument(
        "-p",
        "--pause-jitter",
        type=int,
        default=0,
        help="Pause jitter in seconds (default: 0).",
    )
    parser.add_argument(
        "-T",
        "--threads",
        type=int,
        default=1500,
        help="Number of parallel threads (default: 1500).",
    )
    parser.add_argument(
        "-r",
        "--random",
        action="store_true",
        help="Random sorted range.",
        default=False,
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Do not log closed ports.",
        default=False,
    )

    args = parser.parse_args()
    if len(args.port) > 2:
        raise log_value_error("Please provide space separated range of ports: FROM TO")
    args.from_port = args.port[0]
    args.to_port = args.port[0] + 1 if len(args.port) == 1 else args.port[1] + 1
    if args.from_port > args.to_port:
        raise log_value_error("Start port number should be less the end.")
    return args


def log_value_error(msg):
    """Logging value error function wrapper."""

    logging.critical(msg)
    return ValueError


# check_port,
# ar.host,
# n,
# ar.timeout,
# ar.timeout_jitter,
# random.uniform(0, ar.pause_jitter),
# def check_port(host, port, timeout, timeout_jitter, sleep)


def check_port(port, args):
    """Check the specified port on remote host and sleep before socket close.

    :param port: Port to scan.
    :param args: Arguments that pass from a script start:
                 args.host: IP address or DNS of the host.
                 args.port: Port of the host.
                 args.timeout: Minimum timeout before closes the socket (seconds).
                 args.timeout_jitter: Timeout jitter before closes the socket (seconds).
                 args.sleep: Sleep jitter between scans (seconds).
    """

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(args.timeout + random.uniform(0, args.timeout_jitter))  # nosec B311
    sock.connect((args.host, port))
    sock.send(SEND_DATA.encode())
    res = 0
    try:
        received_data = sock.recv(16)
        reply_info = f"Port {args.port} reply: {received_data} (hex: {received_data.hex(' ', -1)}"
        logging.info(reply_info)
        res = port
    except:  # noqa e722 pylint: disable=W0702
        if not args.quiet:
            logging.error("Port %s is not responding", port)
    time.sleep(random.uniform(0, args.pause_jitter))  # nosec B311
    sock.close()
    return res


if __name__ == "__main__":
    logging.basicConfig(
        stream=sys.stdout,
        level=logging.INFO,
        format="%(asctime)s.%(msecs)03d %(module)s %(levelname)s: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    start = time.perf_counter()
    libgcc_s = ctypes.CDLL("libgcc_s.so.1")
    ar = parse_arguments()
    RANDOM_MSG = " at random" if ar.random else ""
    START_MSG = (
        f"Starting parallel ports {ar.from_port}..{ar.to_port}{RANDOM_MSG} "
        f"check on {ar.host} with {ar.threads} parallel workers, socket "
        f"timeout of {ar.timeout}..{ar.timeout + ar.timeout_jitter} seconds "
        f"and pause jitter of 0..{ar.pause_jitter} seconds..."
    )
    logging.info(START_MSG)
    port_range_len = len(range(ar.from_port, ar.to_port))
    port_sequence = (
        random.sample(range(ar.from_port, ar.to_port), port_range_len)
        if ar.random
        else range(ar.from_port, ar.to_port)
    )

    with ThreadPoolExecutor(max_workers=ar.threads) as executor:
        futures = [executor.submit(check_port, n, ar) for n in port_sequence]
    replied_ports = []
    for future in futures:
        result = future.result()
        if result > 0:
            replied_ports.append(result)
    END_MSG = (
        f"Scanning {ar.host} finished in {timedelta(seconds=time.perf_counter()-start)}."
        f" Possible ports: {replied_ports if len(replied_ports) > 0 else 'None'}."
    )
    logging.info(END_MSG)
