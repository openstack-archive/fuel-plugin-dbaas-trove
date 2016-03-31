notice('MODULAR: trove/haproxy.pp')

$network_metadata = hiera_hash('network_metadata')
$trove_hash    = hiera_hash('fuel-plugin-dbaas-trove', {})
# enabled by default
$use_trove = pick($trove_hash['metadata']['enabled'], true)
$public_ssl_hash = hiera('public_ssl')

$troves_address_map = get_node_to_ipaddr_map_by_network_role(get_nodes_hash_by_roles($network_metadata, ['trove']), 'trove/api')

if ($use_trove) {
  $server_names        = hiera_array('trove_names', keys($troves_address_map))
  $ipaddresses         = hiera_array('trove_ipaddresses', values($troves_address_map))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure trove ha proxy
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }

  openstack::ha::haproxy_service { 'trove-api':
    order               => '210',
    listen_port         => 8779,
    internal            => true,
    public              => true,
  }

  openstack::ha::haproxy_service { 'trove-rabbitmq':
    order                  => '211',
    listen_port            => 55671,
    define_backups         => true,
    internal               => true,
    public                 => true,
    haproxy_config_options => {
      'option'         => ['tcpka'],
      'timeout client' => '48h',
      'timeout server' => '48h',
      'balance'        => 'roundrobin',
      'mode'           => 'tcp'
    },
    balancermember_options => 'check inter 5000 rise 2 fall 3',
  }
}
