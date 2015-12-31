notice('MODULAR: trove/db.pp')

$node_name = hiera('node_name')
$trove_hash    = hiera_hash('fuel-plugin-dbaas-trove', {})
$trove_enabled = pick($trove_hash['metadata']['enabled'], false)
$mysql_hash     = hiera_hash('mysql_hash', {})
$management_vip = hiera('management_vip', undef)
$database_vip   = hiera('database_vip')

$mysql_root_user     = pick($mysql_hash['root_user'], 'root')
$mysql_db_create     = pick($mysql_hash['db_create'], true)
$mysql_root_password = $mysql_hash['root_password']

$db_user     = pick($trove_hash['metadata']['db_user'], 'trove')
$db_name     = pick($trove_hash['metadata']['db_name'], 'trove')
$db_password = pick($trove_hash['metadata']['db_password'], $mysql_root_password)

$db_host          = pick($trove_hash['metadata']['db_host'], $database_vip, 'localhost')
$db_create        = pick($trove_hash['metadata']['db_create'], $mysql_db_create)
$db_root_user     = pick($trove_hash['metadata']['root_user'], $mysql_root_user)
$db_root_password = pick($trove_hash['metadata']['root_password'], $mysql_root_password)

$allowed_hosts = [ $node_name, 'localhost', '127.0.0.1', '%' ]

if $trove_enabled and $db_create {

  class { 'galera::client':
    custom_setup_class => hiera('mysql_custom_setup_class', 'galera'),
  }

  class { 'trove::db::mysql':
    user          => $db_user,
    password      => $db_password,
    dbname        => $db_name,
    allowed_hosts => $allowed_hosts,
  }

  class { 'osnailyfacter::mysql_access':
    db_host     => $db_host,
    db_user     => $db_root_user,
    db_password => $db_root_password,
  }

  Class['galera::client'] ->
    Class['osnailyfacter::mysql_access'] ->
      Class['trove::db::mysql']

}

class mysql::config {}
include mysql::config
class mysql::server {}
include mysql::server