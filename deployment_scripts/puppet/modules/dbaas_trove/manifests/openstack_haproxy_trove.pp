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
# dbaas_trove::openstack_haproxy_trove

class dbaas_trove::openstack_haproxy_trove {

  notice('MODULAR: dbaas_trove/openstack_haproxy_trove.pp')

  $trove              = hiera_hash('fuel-plugin-dbaas-trove', undef)
  $trove_enabled      = pick($trove['metadata']['enabled'], false)

  if ($trove_enabled) {

    $network_metadata   = hiera_hash('network_metadata', {})

    $public_ssl_hash    = hiera_hash('public_ssl', {})
    $ssl_hash           = hiera_hash('use_ssl', {})

    $public_ssl         = get_ssl_property($ssl_hash, $public_ssl_hash, 'trove', 'public', 'usage', false)
    $public_ssl_path    = get_ssl_property($ssl_hash, $public_ssl_hash, 'trove', 'public', 'path', [''])

    $internal_ssl       = get_ssl_property($ssl_hash, {}, 'trove', 'internal', 'usage', false)
    $internal_ssl_path  = get_ssl_property($ssl_hash, {}, 'trove', 'internal', 'path', [''])

    $external_lb        = hiera('external_lb', false)
    $trove_nodes        = get_nodes_hash_by_roles($network_metadata, ['primary-trove', 'trove'])

    $trove_amqp_use_ssl  = pick($trove['metadata']['rabbit_use_ssl'], true)
    $trove_amqp_port     = hiera($trove['rabbit_port'], '55671')
    $trove_api_port      = hiera($trove['metadata']['trove_api_port'], 8779)

    if (!$external_lb) {

      $trove_address_map   = get_node_to_ipaddr_map_by_network_role($trove_nodes, 'trove/api')
      $server_names        = hiera_array('trove_names', keys($trove_address_map))
      $ipaddresses         = hiera_array('trove_ipaddresses', values($trove_address_map))
      $public_virtual_ip   = hiera('public_vip')
      $internal_virtual_ip = hiera('management_vip')

      # configure trove ha proxy
      Openstack::Ha::Haproxy_service {
        internal_virtual_ip => $internal_virtual_ip,
        ipaddresses         => $ipaddresses,
        public_virtual_ip   => $public_virtual_ip,
        server_names        => $server_names,
        public              => true,
        internal_ssl        => $internal_ssl,
        internal_ssl_path   => $internal_ssl_path,
      }

      openstack::ha::haproxy_service { 'trove-api':
        order                  => '305',
        listen_port            => $trove_api_port,
        public_ssl             => $public_ssl,
        public_ssl_path        => $public_ssl_path,
        #require_service        => 'trove-api',
        haproxy_config_options => {
          option           => ['httpchk', 'httplog', 'httpclose'],
          'timeout server' => '660s',
          'http-request'   => 'set-header X-Forwarded-Proto https if { ssl_fc }',
        },
        balancermember_options => 'check inter 10s fastinter 2s downinter 3s rise 3 fall 3',
      }

      if(($public_ssl or $ssl_hash) and $trove_amqp_use_ssl) {
        $rabbit_public_ssl = true
      } else {
        $rabbit_public_ssl = false
      }

      openstack::ha::haproxy_service { 'trove-rabbitmq':
        order                  => '300',
        listen_port            => $trove_amqp_port,
        public_ssl             => $rabbit_public_ssl,
        public_ssl_path        => $public_ssl_path,
        internal               => false,
        define_backups         => true,
        haproxy_config_options => {
          'option'         => ['tcpka'],
          'timeout client' => '48h',
          'timeout server' => '48h',
          'balance'        => 'roundrobin',
          'mode'           => 'tcp',
        },
        balancermember_options => 'check inter 5000 rise 2 fall 3',
      }
    }
  }
}

