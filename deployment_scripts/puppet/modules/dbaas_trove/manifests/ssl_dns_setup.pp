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
# dbaas_trove::ssl_dns_setup

class dbaas_trove::ssl_dns_setup {

  notice('MODULAR: dbaas_trove/ssl_dns_setup.pp')

  $trove            = hiera_hash('fuel-plugin-dbaas-trove', undef)
  $trove_enabled    = pick($trove['metadata']['enabled'], false)

  if ($trove_enabled) {

    $ssl_hash = hiera_hash('use_ssl', {})

    include ::osnailyfacter::ssl::ssl_dns_setup

    if !empty($ssl_hash) {
      $custom_services = ['trove']
      osnailyfacter::ssl::ssl_dns_setup::hosts { $custom_services:
        ssl_hash => $ssl_hash,
      }
    }
  }
}
