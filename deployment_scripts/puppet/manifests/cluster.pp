notice('MODULAR: trove/cluster.pp')

if !(hiera('role') in ['trove']) {
    fail('The node role is not in trove roles')
}

$network_scheme = hiera_hash('network_scheme', {})
$network_metadata = hiera_hash('network_metadata', {})

prepare_network_config($network_scheme)

$trove_node       = get_nodes_hash_by_roles($network_metadata, ['trove'])

$corosync_nodes   = corosync_nodes($trove_node, 'trove/api')

$network_ip       = get_network_role_property('trove/api', 'ipaddr')

class { 'cluster':
  internal_address => $network_ip,
  corosync_nodes   => $corosync_nodes,
}

pcmk_nodes { 'pacemaker' :
  nodes => $corosync_nodes,
  add_pacemaker_nodes => false,
}

Service <| title == 'corosync' |> {
  subscribe => File['/etc/corosync/service.d'],
  require   => File['/etc/corosync/corosync.conf'],
}

Service['corosync'] -> Pcmk_nodes<||>
Pcmk_nodes<||> -> Service<| provider == 'pacemaker' |>

# Sometimes during first start pacemaker can not connect to corosync
# via IPC due to pacemaker and corosync processes are run under different users
if($::operatingsystem == 'Ubuntu') {
  $pacemaker_run_uid = 'hacluster'
  $pacemaker_run_gid = 'haclient'

  file {'/etc/corosync/uidgid.d/pacemaker':
    content =>"uidgid {
   uid: ${pacemaker_run_uid}
   gid: ${pacemaker_run_gid}
}"
  }

  File['/etc/corosync/corosync.conf'] -> File['/etc/corosync/uidgid.d/pacemaker'] -> Service <| title == 'corosync' |>
}