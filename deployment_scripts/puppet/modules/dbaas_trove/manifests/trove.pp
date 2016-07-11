#
# Copyright (C) 2016 AT&T Services, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# dbaas_trove::trove

class dbaas_trove::trove {

  notice('MODULAR: dbaas_trove/trove')

  $trove          = hiera_hash('fuel-plugin-dbaas-trove', undef)
  $trove_enabled  = pick($trove['metadata']['enabled'], false)

  prepare_network_config(hiera('network_scheme', {}))

  if ($trove_enabled) {

    $nova_hash                  = hiera_hash('nova', {})
    $neutron_config             = hiera_hash('neutron_config', {})
    $public_vip                 = hiera('public_vip')
    $database_vip               = hiera('database_vip')
    $management_vip             = hiera('management_vip')
    $region                     = hiera('region', 'RegionOne')
    $service_endpoint           = hiera('service_endpoint')
    $debug                      = hiera('debug', false)
    $verbose                    = hiera('verbose', true)
    $use_syslog                 = hiera('use_syslog', true)
    $use_stderr                 = hiera('use_stderr', false)
    $trove_amqp_port            = hiera('amqp_port')
    $trove_amqp_hosts           = hiera('trove_amqp_hosts')
    $public_ssl_hash            = hiera_hash('public_ssl', {})
    $ssl_hash                   = hiera_hash('use_ssl', {})
    $external_dns               = hiera_hash('external_dns', {})
    $external_lb                = hiera('external_lb', false)
    $api_bind_port              = hiera('trove_api_port')

    $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
    $internal_auth_address      = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_vip])
    $auth_url                   = "${internal_auth_protocol}://${internal_auth_address}:5000/v2.0/"

    $admin_auth_protocol        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
    $admin_auth_address         = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('keystone_endpoint', ''), $service_endpoint, $management_vip])
    $identity_uri               = "${admin_auth_protocol}://${admin_auth_address}:35357/"

    $neutron_protocol           = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'protocol', 'http')
    $neutron_address            = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'hostname', [$service_endpoint, $management_vip])
    $neutron_url                = "${neutron_protocol}://${neutron_address}:9696/"

    $cinder_protocol            = get_ssl_property($ssl_hash, {}, 'cinder', 'internal', 'protocol', 'http')
    $cinder_address             = get_ssl_property($ssl_hash, {}, 'cinder', 'internal', 'hostname', [$service_endpoint, $management_vip])
    $cinder_url                 = "${cinder_protocol}://${cinder_address}:8776/v1"

    $swift_protocol             = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'protocol', 'http')
    $swift_address              = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'hostname', [$service_endpoint, $management_vip])
    $swift_url                  = "${swift_protocol}://${swift_address}:8080/v1/AUTH_"

    $nova_protocol              = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'protocol', 'http')
    $nova_address               = get_ssl_property($ssl_hash, {}, 'nova', 'internal', 'hostname', [$service_endpoint, $management_vip])
    $nova_url                   = "${nova_protocol}://${nova_address}:8774/v2"

    $trove_public_ssl           = get_ssl_property($ssl_hash, $public_ssl_hash, 'trove', 'public', 'usage', false)
    $trove_public_protocol      = get_ssl_property($ssl_hash, $public_ssl_hash, 'trove', 'public', 'protocol', 'http')
    $trove_public_address       = get_ssl_property($ssl_hash, $public_ssl_hash, 'trove', 'public', 'hostname', [$public_vip])

    $api_bind_host    = get_network_role_property('trove/api', 'ipaddr')
    $tenant           = pick($trove['tenant'], 'services')
    $db_user          = pick($trove['db_user'], 'trove')
    $db_name          = pick($trove['db_name'], 'trove')
    $db_password      = $trove['db_password']
    $read_timeout     = '60'
    $sql_connection   = "mysql://${db_user}:${db_password}@${database_vip}/${db_name}?read_timeout=${read_timeout}"
    $sql_idle_timeout = pick($idle_timeout, '3600')

    $rabbit_password               = $trove['rabbit_password']
    $rabbit_userid                 = $trove['rabbit_user']
    $rabbit_use_ssl                = pick($trove['metadata']['rabbit_use_ssl'], true)
    $amqp_durable_queues           = pick($trove['amqp_durable_queues'], true)
    $rabbit_ha_queues              = pick($trove['rabbit_ha_queues'], true)
    $public_rabbit_hosts           = "$public_vip:$trove_amqp_port"

    if($trove_public_ssl and $rabbit_use_ssl) {
      $guest_rabbit_use_ssl = true
    } else {
      $guest_rabbit_use_ssl = false
    }

    $nova_proxy_admin_pass        = $nova_hash['user_password']
    $nova_proxy_admin_user        = $nova_hash['auth_name']
    $nova_proxy_admin_tenant_name = pick($nova_hash['tenant_name'], 'services')

    class { '::trove::client': }

    class { '::trove':
      database_connection          => $sql_connection,
      database_idle_timeout        => $sql_idle_timeout,
      rabbit_hosts                 => $trove_amqp_hosts,
      rabbit_password              => $trove['rabbit_password'],
      rabbit_userid                => $trove['rabbit_user'],
      rabbit_ha_queues             => $rabbit_ha_queues,
      amqp_durable_queues          => $amqp_durable_queues,
      os_region_name               => $region,
      nova_compute_url             => $nova_url,
      cinder_url                   => $cinder_url,
      swift_url                    => $swift_url,
      neutron_url                  => $neutron_url,
      nova_proxy_admin_pass        => $nova_hash['user_password'],
      nova_proxy_admin_user        => $nova_hash['auth_name'],
      nova_proxy_admin_tenant_name => pick($nova_hash['tenant_name'], 'services'),
    }

    class { '::trove::api':
      debug             => $debug,
      verbose           => $verbose,
      bind_host         => $api_bind_host,
      auth_url          => $auth_url,
      auth_host         => $service_endpoint,
      keystone_password => $trove['auth_password'],
      keystone_user     => $trove['auth_name'],
    }

    class { '::trove::conductor':
      debug    => $debug,
      verbose  => $verbose,
      auth_url => $auth_url,
    }

    class { '::trove::taskmanager':
      debug                   => $debug,
      verbose                 => $verbose,
      auth_url                => $auth_url,
      use_guestagent_template => false,
    }

    class { '::trove::guestagent':
      enabled        => false,
      manage_service => true,
      debug          => $debug,
      verbose        => $verbose,
      rabbit_hosts   => $public_rabbit_hosts,
      rabbit_host    => $public_vip,
      rabbit_port    => $trove_amqp_port,
      rabbit_use_ssl => $guest_rabbit_use_ssl,
      auth_url       => false,
      swift_url      => false,
    }

    class { '::trove::quota': }

    class { '::trove::config':
      trove_config            => {
        'DEFAULT/taskmanager_manager'          => { value        => 'trove.taskmanager.manager.Manager' },
        'DEFAULT/update_status_on_fail'        => { value        => 'True' },
        'DEFAULT/guest_config'                 => { value        => '/etc/trove/trove-guestagent.conf' },
        'DEFAULT/injected_config_location'     => { value        => '/etc/trove' },
        'DEFAULT/guest_info'                   => { value        => '/etc/guest_info' },
        'DEFAULT/volume_time_out'              => { value        => '240' },
        'DEFAULT/agent_call_high_timeout'      => { value        => '240' },
        'DEFAULT/agent_call_low_timeout'       => { value        => '20' },
      },
      trove_guestagent_config => {
        'mysql/replication_strategy'  => { value        => 'MysqlGTIDReplication' },
        'mysql/replication_namespace' => { value        => 'trove.guestagent.strategies.replication.mysql_gtid' },
      },
    }
  }
}
