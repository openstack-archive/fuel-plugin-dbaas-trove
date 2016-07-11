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
# dbaas_trove::firewall

class dbaas_trove::firewall {

  notice('MODULAR: dbaas_trove/firewall.pp')

  $trove          = hiera_hash('fuel-plugin-dbaas-trove', undef)
  $trove_enabled  = pick($trove['metadata']['enabled'], false)

  if ($trove_enabled) {

    $network_scheme  = hiera_hash('network_scheme')
    $trove_amqp_port = hiera('amqp_port')
    $trove_api_port  = hiera('trove_api_port')

    $corosync_input_port          = 5404
    $corosync_output_port         = 5405
    $erlang_epmd_port             = 4369
    $erlang_inet_dist_port        = 41055
    $erlang_rabbitmq_backend_port = $trove_amqp_port
    $erlang_rabbitmq_port         = $trove_amqp_port
    $pcsd_port                    = 2224

    $trove_networks    = get_routable_networks_for_network_role($network_scheme, 'trove/api')
    $corosync_networks = $trove_networks

    openstack::firewall::multi_net {'210 trove-api':
      port        => $trove_api_port,
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $trove_networks,
    }


    openstack::firewall::multi_net {'106 rabbitmq':
      port        => [$erlang_epmd_port, $erlang_rabbitmq_port, $erlang_rabbitmq_backend_port, $erlang_inet_dist_port],
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $trove_networks,
    }

    # Workaround for fuel bug with firewall
    firewall {'003 remote rabbitmq ':
      sport  => [$erlang_epmd_port, $erlang_rabbitmq_port, $erlang_rabbitmq_backend_port, $erlang_inet_dist_port, 55672, 61613],
      source => hiera('master_ip'),
      proto  => 'tcp',
      action => 'accept',
    }

    # allow local rabbitmq admin traffic for LP#1383258
    firewall {'005 local rabbitmq admin':
      sport   => [ 15672 ],
      iniface => 'lo',
      proto   => 'tcp',
      action  => 'accept',
    }

    # reject all non-local rabbitmq admin traffic for LP#1450443
    firewall {'006 reject non-local rabbitmq admin':
      sport  => [ 15672 ],
      proto  => 'tcp',
      action => 'drop',
    }

    # allow connections from haproxy namespace
    firewall {'030 allow connections from haproxy namespace':
      source => '240.0.0.2',
      action => 'accept',
    }

    openstack::firewall::multi_net {'113 corosync-input':
      port        => $corosync_input_port,
      proto       => 'udp',
      action      => 'accept',
      source_nets => $corosync_networks,
    }

    openstack::firewall::multi_net {'114 corosync-output':
      port        => $corosync_output_port,
      proto       => 'udp',
      action      => 'accept',
      source_nets => $corosync_networks,
    }

    openstack::firewall::multi_net {'115 pcsd-server':
      port        => $pcsd_port,
      proto       => 'tcp',
      action      => 'accept',
      source_nets => $corosync_networks,
    }
  }
}
