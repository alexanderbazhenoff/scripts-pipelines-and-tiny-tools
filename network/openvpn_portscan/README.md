# Openvpn ports scan

Simple scanner for remote openvpn port by specified ports range (or single port) with time options.

## Info

- Required [python 3.2 or above](https://docs.python.org/3/library/concurrent.futures.html).
- These scripts open a socket, send `"\x38\x01\x00\x00\x00\x00\x00\x00\x00"` data and print a reply to console stdout.
Actually, the result is not 100% (read [this](https://www.usenix.org/system/files/sec22-xue-diwen.pdf)), but it's better
than nothing to detect possible ports.
- Check [this script](https://github.com/liquidat/nagios-icinga-openvpn) if you wish to use more complex openvpn
monitoring (with possible authentication).
- Before you start, you probably need to execute:

  ```bash
  sudo sysctl -w net.ipv4.ping_group_range="0 2147483647"
  sudo setcap cap_net_raw+p /bin/ping
  ulimit -n 50000
  ```

## Usage

```bash
$ ./openvpn_portscan.py -h
usage: ./openvpn_portscan.py [-h] [-t TIMEOUT] [-j TIMEOUT_JITTER] [-p PAUSE_JITTER] [-r] HOST PORT [PORT ...]

positional arguments:
  HOST                  IP or DNS of the server
  PORT                  Single port or space separated range

optional arguments:
  -h, --help            show this help message and exit
  -t TIMEOUT, --timeout TIMEOUT
                        Minimum socket timeout in seconds (default: 4).
  -j TIMEOUT_JITTER, --timeout-jitter TIMEOUT_JITTER
                        Socket timeout jitter in seconds (default: 2).
  -p PAUSE_JITTER, --pause-jitter PAUSE_JITTER
                        Pause jitter in seconds (default: 0).
  -T THREADS, --threads THREADS
                        Number of parallel threads (default: 1500).
  -r, --random          Random sorted range.

```

For example, you can try to scan port 1194 on 1.2.3.4 server:

```bash
$ ./openvpn_portscan.py 1.2.3.4 1194
```

On the port that replied to scanner, you'll see something like:

```text
Port 1194 reply: b'@\xbc(Z+\xf20x\xfd\x00\x00\x00\x00\x00' (hex: 40 bc 28 5a 2b f2 30 78 fd 00 00 00 00 00)
```

## Examples

If you have a good connection and want to scan 1.2.3.4 IP address from 1190 to 1194 ports in a random sequence. You also
have python 3.x, which linked to `python` and no `python3` on the system:

```bash
$ python openvpn_portscan.py 1.2.3.4 1190 1194 -t 3 -p 3 -j 0 -T 3000 -r
```

If you have noticed that the waiting of socket reply for 1 second is not enough, increase them to 2 or 3 seconds.
'Jitters' are to perform socket connections more human alike. So if you bother about analyzing traffic by firewalls,
set socket connection timeout jitter (`-j2`) and jitter for pause between connections to the maximum as you can wait.
The next example will perform a slow scan of all ports with console output redirection to `logfile`:

```bash
$ python openvpn_portscan.py 1.2.3.4 1 65535 -t 5 -p 55 -j 60 -r | tee -a logfile
```

To scan all possible ports on given IP address with specified number of threads use `-T` key. The next example shows how
to scan all ports on the host with maximum possible speed and threads (but still strong to discover) in quiet mode (with
no output on closed port to decrease logs size):

```bash
$ python openvpn_portscan.py 1.2.3.4 1 65535 -t 3 -p 3 -j 0 -r -T 3000 -q
```

Further increase the number of threads depends on your CPU and system tuning (max open files, network connections), but
decreasing of time parameters is not recommended. Please keep in mind most of the CPU resources spent on logging to
console. You need to decrease the number of threads adding option `-q`, but `-q` option brings some randomizing to pause
and timeout jitters.