#
# Copyright (C) 2016 AT&T Inc, Services.
#
# Author: Shaik Apsar
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
# dbaas_trove::hiera_override

class dbaas_trove::hiera_override {

  notice('MODULAR: dbaas_trove/hiera_override.pp')

  $plugin_name      = 'fuel-plugin-dbaas-trove'
  $trove            = hiera_hash($plugin_name, undef)
  $trove_enabled    = pick($trove['metadata']['enabled'], false)
  $hiera_dir        = '/etc/hiera/override'

  if ($trove_enabled) {

    $plugin_yaml       = "${plugin_name}.yaml"
    $network_metadata  = hiera_hash('network_metadata')

    if empty($network_metadata) {
      fail('Network_metadata not given in the astute.yaml')
    }

    $trove_roles       = [ 'primary-trove', 'trove' ]
    $trove_nodes       = get_nodes_hash_by_roles($network_metadata, $trove_roles)

    $trove_address_map = get_node_to_ipaddr_map_by_network_role(
      $trove_nodes,
      'trove/api'
    )

    $trove_nodes_ips    = values($trove_address_map)
    $trove_nodes_names  = keys($trove_address_map)

    $corosync_roles = $trove_roles
    $corosync_nodes = $trove_nodes

    $rabbit_hosts    = $trove_nodes_ips
    $rabbit_port     = hiera($trove['rabbit_port'], '55671')
    $rabbit_username = $trove['rabbit_user']
    $rabbit_password = $trove['rabbit_password']
    $trove_api_port  = hiera($trove['trove_api_port'], 8779)

  }
  $calculated_content = inline_template('<%
require "yaml"
rabbit_hosts = @rabbit_hosts.map {|x| x + ":" + @rabbit_port}.join(",")
data = {
  "trove_amqp_hosts" => @rabbit_hosts,
  "trove_amqp_port"  => @rabbit_port ,
  "trove_api_port"   => @trove_api_port,
  "rabbit_hash"      => {
    "user"           => @rabbit_username ,
    "password"       => @rabbit_password ,
  } ,
}
#data["trove_nodes"]    = @trove_nodes if @trove_nodes
data["corosync_nodes"] = @corosync_nodes if @corosync_nodes
data["corosync_roles"] = @corosync_roles if @corosync_roles
-%>

<%= YAML.dump(data) %>')

  file { $hiera_dir :
    ensure => 'directory',
    path   => $hiera_dir,
  } ->
  file { "${hiera_dir}/${plugin_yaml}" :
    ensure  => 'present',
    content => $calculated_content,
  }
  package {'ruby-deep-merge':
      ensure  => 'installed',
  }

  # hiera file changes between 7.0 and 8.0 so we need to handle the override the
  # different yaml formats via these exec hacks.  It should be noted that the
  # fuel hiera task will wipe out these this update to the hiera.yaml
  exec { "${plugin_name}_hiera_override_7.0":
    command => "sed -i '/  - override\\/plugins/a\\  - override\\/${plugin_name}' /etc/hiera.yaml",
    path    => '/bin:/usr/bin',
    unless  => "grep -q '^  - override/${plugin_name}' /etc/hiera.yaml",
    onlyif  => 'grep -q "^  - override/plugins" /etc/hiera.yaml'
  }

  exec { "${plugin_name}_hiera_override_8.0":
    command => "sed -i '/    - override\\/plugins/a\\    - override\\/${plugin_name}' /etc/hiera.yaml",
    path    => '/bin:/usr/bin',
    unless  => "grep -q '^    - override/${plugin_name}' /etc/hiera.yaml",
    onlyif  => 'grep -q "^    - override/plugins" /etc/hiera.yaml'
  }
}
