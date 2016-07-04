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
# dbaas_trove::keystone
class dbaas_trove::keystone {

  notice('MODULAR: dbaas_trove/keystone')

  $trove         = hiera_hash('fuel-plugin-dbaas-trove', undef)
  $trove_enabled = pick($trove['metadata']['enabled'], false)

  if ($trove_enabled) {

    $management_vip     = hiera('management_vip')
    $public_ssl_hash    = hiera_hash('public_ssl', {})
    $ssl_hash           = hiera_hash('use_ssl', {})
    $public_vip         = hiera('public_vip')

    $public_protocol     = get_ssl_property($ssl_hash, $public_ssl_hash, 'trove', 'public', 'protocol', 'http')
    $public_address      = get_ssl_property($ssl_hash, $public_ssl_hash, 'trove', 'public', 'hostname', [$public_vip])

    $internal_protocol   = get_ssl_property($ssl_hash, {}, 'trove', 'internal', 'protocol', 'http')
    $internal_address    = get_ssl_property($ssl_hash, {}, 'trove', 'internal', 'hostname', [$management_vip])

    $admin_protocol      = get_ssl_property($ssl_hash, {}, 'trove', 'admin', 'protocol', 'http')
    $admin_address       = get_ssl_property($ssl_hash, {}, 'trove', 'admin', 'hostname', [$management_vip])

    $region              = pick($trove['region'], hiera('region', 'RegionOne'))
    $password            = $trove['auth_password']
    $auth_name           = pick($trove['auth_name'], 'trove')
    $configure_endpoint  = pick($trove['configure_endpoint'], true)
    $service_name        = pick($trove['service_name'], 'trove')
    $tenant              = pick($trove['tenant'], 'services')

    validate_string($public_address)
    validate_string($password)

    $bind_port = '8779'

    $public_url          = "${public_protocol}://${public_address}:${bind_port}/v1.0/%(tenant_id)s"
    $internal_url        = "${internal_protocol}://${internal_address}:${bind_port}/v1.0/%(tenant_id)s"
    $admin_url           = "${admin_protocol}://${admin_address}:${bind_port}/v1.0/%(tenant_id)s"

    Class['::osnailyfacter::wait_for_keystone_backends'] -> Class['::trove::keystone::auth']

    class {'::osnailyfacter::wait_for_keystone_backends': }

    class { '::trove::keystone::auth':
      configure_endpoint => $configure_endpoint,
      service_name       => $service_name,
      region             => $region,
      auth_name          => $auth_name,
      password           => $password,
      email              => "${auth_name}@localhost",
      tenant             => $tenant,
      public_url         => $public_url,
      internal_url       => $internal_url,
      admin_url          => $admin_url,
    }
  }
}

