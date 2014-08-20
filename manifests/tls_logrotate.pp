class ispconfig_proftpd::tls_logrotate {

  logrotate::file { "proftpd-tls":
    log          => "/var/log/proftpd/tls.log",
    interval     => "daily",
    rotation     => "210",
    options      => [ 'missingok', 'compress', ],
    archive      => true,
    olddir       => "/var/log/proftpd/archives",
    olddir_owner => $proftpd::logrotate_olddir_owner,
    olddir_group => $proftpd::logrotate_olddir_group,
    olddir_mode  => $proftpd::logrotate_olddir_mode,
    create       => "${proftpd::logrotate_create_mode} ${proftpd::logrotate_create_owner} ${proftpd::logrotate_create_group}",
  }

}
