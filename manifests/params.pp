class ispconfig_proftpd::params {

  $home_dir               = '/var/run/proftpd'
  $uid  = $local_proftpd_uid ? {
    undef   => '3002',
    default => $local_proftpd_uid
  }
  $tls                    = false
  $ssl_domain             = ''
  $root_dir               = '/etc/proftpd'
  $conf_file              = "${root_dir}/proftpd.conf"
  $vhosts_file            = "${root_dir}/vhosts.conf"
  $conf_link              = '/etc/proftpd.conf'
  $tls_conf               = "${root_dir}/tls.conf"
  $ipv6                   = 'off'
  $logrotate_olddir_owner = 'root'
  $logrotate_olddir_group = 'adm'
  $logrotate_olddir_mode  = '0750'
  $logrotate_create_owner = 'root'
  $logrotate_create_group = 'adm'
  $logrotate_create_mode  = '0640'
  $logrotate_interval     = 'daily'
  $logrotate_rotation     = '210'
  $logrotate_file         = '/var/log/proftpd/tls.log'
  $logrotate_archive      = '/var/log/proftpd/archives'
}
