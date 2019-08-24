import requests, json, socket, netifaces, ipaddress
from requests.auth import HTTPBasicAuth


zabbix_server = u'172.31.31.254'
zabbix_api_admin_name = u'Admin'
zabbix_api_admin_password = u'zabbix'
zabbix_hostgroup = u'CloudHosts'
zabbix_template = u'Template App Zabbix Agent'


def post(request):
    """Send POST request to Zabbix Server"""
    headers = {'content-type': 'application/json'}
    return requests.post(
        'http://' + zabbix_server + '/api_jsonrpc.php',
        data=json.dumps(request),
        headers=headers,
        auth=HTTPBasicAuth(zabbix_api_admin_name, zabbix_api_admin_password)
    )


auth_token = post({
    'jsonrpc': '2.0',
    'method': 'user.login',
    'params': {
        'user': zabbix_api_admin_name,
        'password': zabbix_api_admin_password
    },
    'auth': None,
    'id': 0
}).json()['result']


def is_existed_hostgroup(hostgroup):
    """Check the group exists or not"""
    result = post({
            'jsonrpc': '2.0',
            'method': 'hostgroup.get',
            'params': {
                'output': 'extend',
                'filter': {
                    'name': [
                        hostgroup
                    ]
                }
            },
            'auth': auth_token,
            'id': 1
        }).json()['result']

    if result:
        return True
    else:
        return False


def create_hostgroup(hostgroup):
    """Create the group 'group'"""
    post({
        'jsonrpc': '2.0',
        'method': 'hostgroup.create',
        'params': {
            'name': hostgroup
        },
        'auth': auth_token,
        'id': 1
    })


def get_group_id(hostgroup):
    """Return group id"""
    result = post({
        'jsonrpc': '2.0',
        'method': 'hostgroup.get',
        'params': {
            'output': 'extend',
            'filter': {
                'name': [
                    hostgroup
                ]
            }
        },
        'auth': auth_token,
        'id': 1
    }).json()['result']

    if result:
        return result[0]['groupid']
    else:
        return None


def get_ip_address_from_server_network(server_address):
    for interface in netifaces.interfaces():
        try:
            local_address = ipaddress.IPv4Address(
                    unicode(netifaces.ifaddresses(interface)[netifaces.AF_INET][0]['addr'])
            )
            mask = ipaddress.IPv4Address(
                unicode(netifaces.ifaddresses(interface)[netifaces.AF_INET][0]['netmask'])
            )

            if int(local_address) & int(mask) == int(ipaddress.IPv4Address(server_address)) & int(mask):
                break
        except KeyError:
            pass
    else:
        return None

    return str(local_address)


def get_template_id(template):
    """Return template id"""
    result = post({
        'jsonrpc': '2.0',
        'method': 'template.get',
        'params': {
            'output': 'extend',
            'filter': {
                'host': [
                    template
                ]
            }
        },
        'auth': auth_token,
        'id': 1
    }).json()['result']

    if result:
        return result[0]['templateid']
    else:
        return None


def is_existed_host(host):
    result = post({
        'jsonrpc': '2.0',
        'method': 'host.get',
        'params': {
            'filter': {
                'host': [
                    host
                ]
            }
        },
        'auth': auth_token,
        'id': 1
    }).json()['result']

    if result:
        return True
    else:
        return False


def create_host():
    """Create Zabbix Host"""
    hostname = socket.gethostname()

    ip_address = get_ip_address_from_server_network(zabbix_server)
    if ip_address is None:
        print 'Host is not added! There is no Zabbix server in %s networks!'.format(hostname)
        exit(1)

    if not is_existed_hostgroup(zabbix_hostgroup):
        create_hostgroup(zabbix_hostgroup)

    group_id = get_group_id(zabbix_hostgroup)

    template_id = get_template_id(zabbix_template)
    if template_id is None:
        print 'Host is not added! Zabbix server has not {} template!'.format(zabbix_template)
        exit(1)

    post({
        'jsonrpc': '2.0',
        'method': 'host.create',
        'params': {
            'host': hostname,
            'templates': [{
                'templateid': template_id
            }],
            'interfaces': [{
                'type': 1,
                'main': 1,
                'useip': 1,
                'ip': ip_address,
                'dns': '',
                'port': '10050'
            }],
            'groups': [{
                'groupid': group_id
            }]
        },
        'auth': auth_token,
        'id': 1
    })


if not is_existed_host(socket.gethostname()):
    create_host()
else:
    print 'Error! Host {} exists!'.format(socket.gethostname())
