#!/usr/bin/env python3

import bisect
import datetime


def parse_timestamp(raw_str):
    tokens = raw_str.split()

    if len(tokens) == 1:
        if tokens[0].lower() == 'never':
            return 'never'

        else:
            raise Exception('Parse error in timestamp')

    elif len(tokens) == 3:
        return datetime.datetime.strptime(' '.join(tokens[1:]),
                                          '%Y/%m/%d %H:%M:%S')

    else:
        raise Exception('Parse error in timestamp')


def timestamp_is_ge(t1, t2):
    if t1 == 'never':
        return True

    elif t2 == 'never':
        return False

    else:
        return t1 >= t2


def timestamp_is_lt(t1, t2):
    if t1 == 'never':
        return False

    elif t2 == 'never':
        return t1 != 'never'

    else:
        return t1 < t2


def timestamp_is_between(t, t_start, tend):
    return (not t_start or timestamp_is_ge(t, t_start)) and timestamp_is_lt(t, tend)


def parse_hardware(raw_str):
    tokens = raw_str.split()

    if len(tokens) == 2:
        return tokens[1]

    else:
        raise Exception('Parse error in hardware')


def strip_end_quotes(raw_str):
    return raw_str.strip('"')


def identity(raw_str):
    return raw_str


def parse_binding_state(raw_str):
    tokens = raw_str.split()

    if len(tokens) == 2:
        return tokens[1]

    else:
        raise Exception('Parse error in binding state')


def parse_next_binding_state(raw_str):
    tokens = raw_str.split()

    if len(tokens) == 3:
        return tokens[2]

    else:
        raise Exception('Parse error in next binding state')


def parse_rewind_binding_state(raw_str):
    tokens = raw_str.split()

    if len(tokens) == 3:
        return tokens[2]

    else:
        raise Exception('Parse error in next binding state')


def parse_leases_file(leases_file):
    valid_keys = {
        'starts': parse_timestamp,
        'ends': parse_timestamp,
        'tstp': parse_timestamp,
        'tsfp': parse_timestamp,
        'atsfp': parse_timestamp,
        'cltt': parse_timestamp,
        'hardware': parse_hardware,
        'binding': parse_binding_state,
        'next': parse_next_binding_state,
        'rewind': parse_rewind_binding_state,
        'uid': strip_end_quotes,
        'client-hostname': strip_end_quotes,
        'option': identity,
        'set': identity,
        'on': identity,
        'abandoned': None,
        'bootp': None,
        'reserved': None,
        'dynamic-bootp;': None,
    }

    leases_db = {}

    lease_rec = {}
    in_lease = False
    in_failover = False

    for line in leases_file:
        if line.lstrip().startswith('#'):
            continue

        tokens = line.split()

        if len(tokens) == 0:
            continue

        key = tokens[0].lower()

        if key == 'lease':
            if not in_lease:
                ip_address = tokens[1]

                lease_rec = {'ip_address': ip_address}
                in_lease = True

            else:
                raise Exception('Parse error in leases file')

        elif key == 'failover':
            in_failover = True
        elif key == '}':
            if in_lease:
                for k in valid_keys:
                    if callable(valid_keys[k]):
                        lease_rec[k] = lease_rec.get(k, '')
                    else:
                        lease_rec[k] = False

                ip_address = lease_rec['ip_address']

                if ip_address in leases_db:
                    leases_db[ip_address].insert(0, lease_rec)

                else:
                    leases_db[ip_address] = [lease_rec]

                lease_rec = {}
                in_lease = False

            elif in_failover:
                in_failover = False
                continue
            else:
                raise Exception('Parse error in leases file')

        elif key in valid_keys:
            if in_lease:
                value = line[(line.index(key) + len(key)):]
                value = value.strip().rstrip(';').rstrip()

                if callable(valid_keys[key]):
                    lease_rec[key] = valid_keys[key](value)
                else:
                    lease_rec[key] = True

            else:
                raise Exception('Parse error in leases file')

        else:
            if in_lease:
                raise Exception('Parse error in leases file')

    if in_lease:
        raise Exception('Parse error in leases file')

    return leases_db


def round_timedelta(t_delta):
    return datetime.timedelta(t_delta.days,
                              t_delta.seconds + (0 if t_delta.microseconds < 500000 else 1))


def timestamp_now():
    n = datetime.datetime.utcnow()
    if n.microsecond >= 500000:
        n += datetime.timedelta(seconds=1)
    return datetime.datetime(n.year, n.month, n.day, n.hour, n.minute, n.second)


def lease_is_active(lease_rec, as_of_ts):
    return timestamp_is_between(as_of_ts, lease_rec['starts'],
                                lease_rec['ends'])


def ipv4_to_int(ipv4_addr):
    parts = ipv4_addr.split('.')
    return (int(parts[0]) << 24) + (int(parts[1]) << 16) + \
        (int(parts[2]) << 8) + int(parts[3])


def select_active_leases(leases_db, as_of_ts, vendor_db=None):
    ret_array = []
    sort_ed_array = []

    for ip_address in leases_db:
        lease_rec = leases_db[ip_address][0]

        if lease_is_active(lease_rec, as_of_ts):
            if vendor_db and lease_rec.get('hardware'):
                vendor_id = lease_rec['hardware'][:8].upper()
                lease_rec['vendor'] = vendor_db.get(vendor_id, '')
            else:
                lease_rec['vendor'] = ''
            ip_as_int = ipv4_to_int(ip_address)
            insertpos = bisect.bisect(sort_ed_array, ip_as_int)
            sort_ed_array.insert(insertpos, ip_as_int)
            ret_array.insert(insertpos, lease_rec)

    return ret_array


def parse_vendors_file(file):
    result = {}
    for line in file:
        if '(hex)' in line:
            prefix, _, manufacturer = line.split(maxsplit=2)
            result[prefix.replace('-', ':')] = manufacturer.strip()
    return result


##############################################################################


my_lease_file = open('/var/lib/dhcp/dhcpd.leases', 'r')
leases = parse_leases_file(my_lease_file)
my_lease_file.close()

vendors_file = open('/usr/local/etc/oui.txt', 'r')
vendors = parse_vendors_file(vendors_file)
vendors_file.close()

now = timestamp_now()
report_dataset = select_active_leases(leases, now, vendors)

print('+---------------------------------------------------------------------------------------')
print('| DHCPD ACTIVE LEASES REPORT')
print('+-----------------+-------------------+----------------------+-----------------+--------')
print('| IP Address      | MAC Address       | Expires (days,H:M:S) | Client Hostname | Vendor')
print('+-----------------+-------------------+----------------------+-----------------+--------')

for lease in report_dataset:
    print('| ' + format(lease['ip_address'], '<15') + ' | ' + \
          format(lease['hardware'], '<17') + ' | ' + \
          format(str((lease['ends'] - now) if lease['ends'] != 'never' else 'never'), '>20') + ' | ' + \
          format(lease['client-hostname'], '<15') + ' | ' + lease['vendor'])

print('+-----------------+-------------------+----------------------+-----------------+--------')
print('| Total Active Leases: ' + str(len(report_dataset)))
print('| Report generated (UTC): ' + str(now))
print('+---------------------------------------------------------------------------------------')
