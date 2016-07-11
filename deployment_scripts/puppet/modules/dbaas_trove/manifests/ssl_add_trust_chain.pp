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

  $trove          = hiera_hash('fuel-plugin-dbaas-trove', undef)
  $trove_enabled  = pick($trove['metadata']['enabled'], false)

  if ($trove_enabled) {

    $ssl_hash = hiera_hash('use_ssl', {})
    $custom_services = ['trove']

    include ::osnailyfacter::ssl::ssl_add_trust_chain

    if !empty($ssl_hash) {
      osnailyfacter::ssl::ssl_add_trust_chain::file_link{ $custom_services:}
    }

  }
}
