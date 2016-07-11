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
# dbaas_trove::ssl_add_trust_chain

class dbaas_trove::ssl_add_trust_chain {

  notice('MODULAR: dbaas_trove/ssl_add_trust_chain.pp')

  $trove            = hiera_hash('fuel-plugin-dbaas-trove', undef)
  $trove_enabled    = pick($trove['metadata']['enabled'], false)

 Exec {
    path => '/bin:/usr/bin:/sbin:/usr/sbin',
  }

  File {
    ensure => file,
  }

  define file_link {
    $service = $name
    if !empty(file("/etc/pki/tls/certs/public_${service}.pem",'/dev/null')) {
      file { "/usr/local/share/ca-certificates/${service}_public_haproxy.crt":
        source => "/etc/pki/tls/certs/public_${service}.pem",
      }
    }

    if !empty(file("/etc/pki/tls/certs/internal_${service}.pem",'/dev/null')) {
      file { "/usr/local/share/ca-certificates/${service}_internal_haproxy.crt":
        source => "/etc/pki/tls/certs/internal_${service}.pem",
      }
    }

    if !empty(file("/etc/pki/tls/certs/admin_${service}.pem",'/dev/null')) {
      file { "/usr/local/share/ca-certificates/${service}_admin_haproxy.crt":
        source => "/etc/pki/tls/certs/admin_${service}.pem",
      }
    }
  }

  if !empty($ssl_hash and $trove_enabled) {
    $custome_services = [ 'trove' ]

    file_link { $custome_services: }

  }  elsif !empty($custome_services and $trove_enabled) {
    case $::osfamily {
      'RedHat': {
        file { '/etc/pki/ca-trust/source/anchors/public_haproxy.pem':
          source => '/etc/pki/tls/certs/public_haproxy.pem',
        }
      }

      'Debian': {
        file { '/usr/local/share/ca-certificates/public_haproxy.crt':
          source => '/etc/pki/tls/certs/public_haproxy.pem',
        }
      }

      default: {
        fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
      }
    }
  }

  case $::osfamily {
    'RedHat': {
      exec { 'enable_trust':
        command     => 'update-ca-trust force-enable',
        refreshonly => true,
        notify      => Exec['add_trust']
      }

      File <||> ~> Exec['enable_trust']
    }

    'Debian': {
      File <||> ~> Exec['add_trust']
    }

    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }

  exec { 'add_trust':
    command     => 'update-ca-certificates',
    refreshonly => true,
  }
}
