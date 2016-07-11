# == Class: trove::guestagent
#
# Manages trove guest agent package and service
#
# === Parameters:
#
# [*enabled*]
#   (optional) Whether to enable the trove guest agent service
#   Defaults to true
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*ensure_package*]
#   (optional) The state of the trove guest agent package
#   Defaults to 'present'
#
# [*verbose*]
#   (optional) Rather to log the trove guest agent service at verbose level.
#   Default: false
#
# [*debug*]
#   (optional) Rather to log the trove guest agent service at debug level.
#   Default: false
#
# [*log_file*]
#   (optional) The path of file used for logging
#   If set to boolean false, it will not log to any file.
#   Default: /var/log/trove/guestagent.log
#
# [*log_dir*]
#    (optional) directory to which trove logs are sent.
#    If set to boolean false, it will not log to any directory.
#    Defaults to '/var/log/trove'
#
# [*use_syslog*]
#   (optional) Use syslog for logging.
#   Defaults to false.
#
# [*log_facility*]
#   (optional) Syslog facility to receive log lines.
#   Defaults to 'LOG_USER'.
#
# [*auth_url*]
#   (optional) Authentication URL.
#   Defaults to 'http://localhost:5000/v2.0'.
#
# [*swift_url*]
#   (optional) Swift URL.
#   Defaults to 'http://localhost:8080/v1/AUTH_'.
#
# [*control_exchange*]
#   (optional) Control exchange.
#   Defaults to 'trove'.
#
# TODO(shaikapsar): remove this once bug/1585783 merged to stable/liberty.
# [*rabbit_hosts*]
#   (optional) List of clustered rabbit servers.
#   Defaults to the value set in the trove class.
#   The default can generally be left unless the
#   guests need to talk to the rabbit cluster via
#   different IPs.
#
# TODO(shaikapsar): remove this once bug/1585783 merged to stable/liberty.
# [*rabbit_host*]
#   (optional) Location of rabbitmq installation.
#   Defaults to the value set in the trove class.
#   The default can generally be left unless the
#   guests need to talk to the rabbit cluster via
#   a different IP.
#
# TODO(shaikapsar): remove this once bug/1585783 merged to stable/liberty.
# [*rabbit_port*]
#   (optional) Port for rabbitmq instance.
#   Defaults to the value set in the trove class.
#   The default can generally be left unless the
#   guests need to talk to the rabbit cluster via
#   a different port.
#
# TODO(shaikapsar): remove this once bug/1585783 merged to stable/liberty.
# [*rabbit_use_ssl*]
#   (optional) Connect over SSL for RabbitMQ
#   Defaults to the value set in the trove class.
#   The default can generally be left unless the
#   guests need to talk to the rabbit cluster via
#   a different ssl connection option.
#
class trove::guestagent(
  $enabled                   = true,
  $manage_service            = true,
  $ensure_package            = 'present',
  $verbose                   = false,
  $debug                     = false,
  $log_file                  = '/var/log/trove/guestagent.log',
  $log_dir                   = '/var/log/trove',
  $use_syslog                = false,
  $log_facility              = 'LOG_USER',
  $auth_url                  = 'http://localhost:5000/v2.0',
  $swift_url                 = 'http://localhost:8080/v1/AUTH_',
  $control_exchange          = 'trove',
  # TODO(shaikapsar): remove the below 4lines once bug/1585783 merged to stable/liberty.
  $rabbit_hosts              = $::trove::rabbit_hosts,
  $rabbit_host               = $::trove::rabbit_host,
  $rabbit_port               = $::trove::rabbit_port,
  $rabbit_use_ssl            = $::trove::rabbit_use_ssl,
) inherits trove {

  include ::trove::params

  Trove_guestagent_config<||> ~> Exec['post-trove_config']
  Trove_guestagent_config<||> ~> Service['trove-guestagent']

  # basic service config
  trove_guestagent_config {
    'DEFAULT/verbose':                      value => $verbose;
    'DEFAULT/debug':                        value => $debug;
    'DEFAULT/control_exchange':             value => $control_exchange;
    'DEFAULT/rpc_backend':                  value => $::trove::rpc_backend;
  }

  # (shaikapsar): Option to fetch auth_url and swift_url from the keystone catalog.

  # auth_url
  if $auth_url {
    trove_guestagent_config { 'DEFAULT/trove_auth_url': value => $auth_url }
  }
  else {
    trove_guestagent_config { 'DEFAULT/trove_auth_url': ensure => absent }
  }

  # swift_url
  if $swift_url {
    trove_guestagent_config { 'DEFAULT/swift_url': value => $swift_url }
  }
  else {
    trove_guestagent_config { 'DEFAULT/swift_url': ensure => absent }
  }

  # region name
  if $::trove::os_region_name {
    trove_guestagent_config { 'DEFAULT/os_region_name': value => $::trove::os_region_name }
  }
  else {
    trove_guestagent_config {'DEFAULT/os_region_name': ensure => absent }
  }

  if $::trove::rpc_backend == 'trove.openstack.common.rpc.impl_kombu' or $::trove::rpc_backend == 'rabbit' {
    if ! $::trove::rabbit_password {
      fail('When rpc_backend is rabbitmq, you must set rabbit password')
    }

    # TODO(shaikapsar): remove the below lines once bug/1585783 merged to stable/liberty.
    if $rabbit_hosts {
      trove_guestagent_config { 'oslo_messaging_rabbit/rabbit_hosts':     value  => $rabbit_hosts }
    } else  {
      trove_guestagent_config { 'oslo_messaging_rabbit/rabbit_host':      value => $rabbit_host }
      trove_guestagent_config { 'oslo_messaging_rabbit/rabbit_port':      value => $rabbit_port }
      trove_guestagent_config { 'oslo_messaging_rabbit/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}" }
    }

    if $::trove::rabbit_ha_queues == undef {
      # TODO(shaikapsar): remove the below lines once bug/1585783 merged to stable/liberty.
      if size($rabbit_hosts) > 1 {
        trove_guestagent_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value  => true }
      } else {
        trove_guestagent_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value => false }
      }
    } else {
      trove_guestagent_config { 'oslo_messaging_rabbit/rabbit_ha_queues': value => $::trove::rabbit_ha_queues }
    }

    trove_guestagent_config {
      'oslo_messaging_rabbit/rabbit_userid':         value => $::trove::rabbit_userid;
      'oslo_messaging_rabbit/rabbit_password':       value => $::trove::rabbit_password, secret => true;
      'oslo_messaging_rabbit/rabbit_virtual_host':   value => $::trove::rabbit_virtual_host;
      # TODO(shaikapsar): remove the below lines once bug/1585783 merged to stable/liberty.
      'oslo_messaging_rabbit/rabbit_use_ssl':        value => $rabbit_use_ssl;
      'oslo_messaging_rabbit/kombu_reconnect_delay': value => $::trove::kombu_reconnect_delay;
      # TODO(shaikapsar): remove the below lines once bug/1486319 merged to stable/liberty.
      'oslo_messaging_rabbit/amqp_durable_queues':   value => $::trove::amqp_durable_queues;
    }

    # TODO(shaikapsar): remove the below lines once bug/1585783 merged to stable/liberty.
    if $rabbit_use_ssl {

      if $::trove::kombu_ssl_ca_certs {
        trove_guestagent_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': value => $::trove::kombu_ssl_ca_certs; }
      } else {
        trove_guestagent_config { 'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent; }
      }

      if $::trove::kombu_ssl_certfile or $::trove::kombu_ssl_keyfile {
        trove_guestagent_config {
          'oslo_messaging_rabbit/kombu_ssl_certfile': value => $::trove::kombu_ssl_certfile;
          'oslo_messaging_rabbit/kombu_ssl_keyfile':  value => $::trove::kombu_ssl_keyfile;
        }
      } else {
        trove_guestagent_config {
          'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent;
          'oslo_messaging_rabbit/kombu_ssl_keyfile':  ensure => absent;
        }
      }

      if $::trove::kombu_ssl_version {
        trove_guestagent_config { 'oslo_messaging_rabbit/kombu_ssl_version':  value => $::trove::kombu_ssl_version; }
      } else {
        trove_guestagent_config { 'oslo_messaging_rabbit/kombu_ssl_version':  ensure => absent; }
      }

    } else {
      trove_guestagent_config {
        'oslo_messaging_rabbit/kombu_ssl_ca_certs': ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_certfile': ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_keyfile':  ensure => absent;
        'oslo_messaging_rabbit/kombu_ssl_version':  ensure => absent;
      }
    }
  }

  if $::trove::rpc_backend == 'trove.openstack.common.rpc.impl_qpid' or $::trove::rpc_backend == 'qpid'{

    warning('Qpid driver is removed from Oslo.messaging in the Mitaka release')

    trove_guestagent_config {
      'oslo_messaging_qpid/qpid_hostname':    value => $::trove::qpid_hostname;
      'oslo_messaging_qpid/qpid_port':        value => $::trove::qpid_port;
      'oslo_messaging_qpid/qpid_username':    value => $::trove::qpid_username;
      'oslo_messaging_qpid/qpid_password':    value => $::trove::qpid_password, secret => true;
      'oslo_messaging_qpid/qpid_heartbeat':   value => $::trove::qpid_heartbeat;
      'oslo_messaging_qpid/qpid_protocol':    value => $::trove::qpid_protocol;
      'oslo_messaging_qpid/qpid_tcp_nodelay': value => $::trove::qpid_tcp_nodelay;
    }
    if is_array($::trove::qpid_sasl_mechanisms) {
      trove_guestagent_config {
        'oslo_messaging_qpid/qpid_sasl_mechanisms': value => join($::trove::qpid_sasl_mechanisms, ' ');
      }
    }
  }

  # Logging
  if $log_file {
    trove_guestagent_config {
      'DEFAULT/log_file': value  => $log_file;
    }
  } else {
    trove_guestagent_config {
      'DEFAULT/log_file': ensure => absent;
    }
  }

  if $log_dir {
    trove_guestagent_config {
      'DEFAULT/log_dir': value  => $log_dir;
    }
  } else {
    trove_guestagent_config {
      'DEFAULT/log_dir': ensure => absent;
    }
  }

  # Syslog
  if $use_syslog {
    trove_guestagent_config {
      'DEFAULT/use_syslog'          : value => true;
      'DEFAULT/syslog_log_facility' : value => $log_facility;
    }
  } else {
    trove_guestagent_config {
      'DEFAULT/use_syslog': value => false;
    }
  }

  trove::generic_service { 'guestagent':
    enabled        => $enabled,
    manage_service => $manage_service,
    package_name   => $::trove::params::guestagent_package_name,
    service_name   => $::trove::params::guestagent_service_name,
    ensure_package => $ensure_package,
  }

}
