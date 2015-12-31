notice('MODULAR: trove/keystone.pp')

$trove_hash         = hiera_hash('fuel-plugin-dbaas-trove', {})
$public_ssl_hash     = hiera('public_ssl')
$public_vip          = hiera('public_vip')
$public_address      = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}
$public_protocol     = $public_ssl_hash['services'] ? {
  true    => 'https',
  default => 'http',
}
$admin_protocol      = 'http'
$admin_address       = hiera('management_vip')
$region              = pick($trove_hash['metadata']['region'], hiera('region', 'RegionOne'))

$password            = pick($trove_hash['metadata']['user_password'], 'password')
$auth_name           = pick($trove_hash['metadata']['auth_name'], 'trove')
$configure_endpoint  = pick($trove_hash['metadata']['configure_endpoint'], true)
$configure_user      = pick($trove_hash['metadata']['configure_user'], true)
$configure_user_role = pick($trove_hash['metadata']['configure_user_role'], true)
$service_name        = pick($trove_hash['metadata']['service_name'], 'trove')
$tenant              = pick($trove_hash['metadata']['tenant'], 'services')

$port = '8779'

$public_url      = "${public_protocol}://${public_address}:${port}/v1.0/%(tenant_id)s"
$admin_url       = "${admin_protocol}://${admin_address}:${port}/v1.0/%(tenant_id)s"

validate_string($public_address)
validate_string($password)

class { 'trove::keystone::auth':
  password            => $password,
  auth_name           => $auth_name,
  configure_endpoint  => $configure_endpoint,
  service_name        => $service_name,
  public_url          => $public_url,
  internal_url        => $admin_url,
  admin_url           => $admin_url,
  region              => $region,
  tenant              => $tenant,
}