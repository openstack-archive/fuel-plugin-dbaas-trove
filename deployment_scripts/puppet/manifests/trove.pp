notice('MODULAR: trove/trove.pp')

prepare_network_config(hiera('network_scheme', {}))

$trove_hash                 = hiera_hash('fuel-plugin-dbaas-trove', {})
$nova_hash                  = hiera_hash('nova_hash', {})
$neutron_config             = hiera_hash('neutron_config', {})
$node_role                  = hiera('node_role')
$public_ip                  = hiera('public_vip')
$database_ip                = hiera('database_vip')
$management_ip              = hiera('management_vip')
$region                     = hiera('region', 'RegionOne')
$service_endpoint           = hiera('service_endpoint')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$use_stderr                 = hiera('use_stderr', false)
$rabbit_ha_queues           = hiera('rabbit_ha_queues')
$amqp_port                  = hiera('amqp_port')
$amqp_hosts                 = hiera('amqp_hosts')
$public_ssl                 = hiera_hash('public_ssl', {})

#################################################################

if $trove_hash['metadata']['enabled'] {
  $public_protocol = pick($public_ssl['services'], false) ? {
    true    => 'https',
    default => 'http',
  }

  $public_address = pick($public_ssl['services'], false) ? {
    true    => pick($public_ssl['hostname']),
    default => $public_ip,
  }

  $firewall_rule  = '210 trove-api'

  $api_bind_port  = '8779'
  $api_bind_host  = get_network_role_property('trove/api', 'ipaddr')

  $trove_user    = pick($trove_hash['metadata']['user'], 'trove')
  $tenant         = pick($trove_hash['metadata']['tenant'], 'services')
  $internal_url   = "http://${api_bind_host}:${api_bind_port}"
  $db_user        = pick($trove_hash['metadata']['db_user'], 'trove')
  $db_name        = pick($trove_hash['metadata']['db_name'], 'trove')
  $db_password    = pick($trove_hash['metadata']['db_password'], 's3cr3t')
  $db_host        = pick($trove_hash['metadata']['db_host'], $database_ip)
  $read_timeout   = '60'
  $sql_connection = "mysql://${db_user}:${db_password}@${db_host}/${db_name}?read_timeout=${read_timeout}"

 
  class { '::trove::client': }

  class { '::trove':
    database_connection   => $sql_connection,
    rabbit_host           => $management_ip,
    rabbit_password       => $trove_hash['metadata']['rabbit_password'],
    rabbit_port           => '55671',
    rabbit_userid         => $trove_hash['metadata']['rabbit_user'],
    rabbit_use_ssl        => false,
    nova_proxy_admin_pass => $nova_hash['user_password'],
	nova_proxy_admin_user => 'nova',
    nova_proxy_admin_tenant_name => pick($nova_hash['tenant_name'], 'services'),
  }

  class { '::trove::api':
    debug             => true,
    verbose           => true,
    bind_host         => $api_bind_host,
    auth_url          => "http://${service_endpoint}:5000/v2.0/",
    keystone_password => $trove_hash['metadata']['user_password'],
  }

  class { '::trove::conductor':
    debug             => true,
    verbose           => true,
    auth_url          => "http://${service_endpoint}:5000/v2.0/",
  }

  class { '::trove::taskmanager':
    debug             => true,
    verbose           => true,
    auth_url          => "http://${service_endpoint}:5000/v2.0/",
  }
  
  firewall { $firewall_rule :
    dport  => $api_bind_port,
    proto  => 'tcp',
    action => 'accept',
  }

}