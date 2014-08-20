define ispconfig_proftpd::vhost (
  $vhost_address = ''
) {

  $vhost_listen_address = $vhost_address? {
    ''      => $name,
    default => $vhost_address,
  }

  concat_fragment {"proftpd_vhosts+002+${name}+.tmp":
    content => template('ispconfig_proftpd/etc/vhost.erb'),
  }
}

