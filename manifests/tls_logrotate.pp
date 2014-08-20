class ispconfig_proftpd::tls_logrotate (
  $logrotate_olddir_owner,
  $logrotate_olddir_group,
  $logrotate_olddir_mode,
  $logrotate_create_mode,
  $logrotate_create_owner,
  $logrotate_create_group,
  $logrotate_interval,
  $logrotate_rotation,
  $logrotate_file,
  $logrotate_archive,
){

  logrotate::file { "proftpd-tls":
    log          => $logrotate_file,
    interval     => $logrotate_interval,
    rotation     => $logrotate_rotation,
    options      => [ 'missingok', 'compress', ],
    archive      => true,
    olddir       => $logrotate_archive,
    olddir_owner => $logrotate_olddir_owner,
    olddir_group => $logrotate_olddir_group,
    olddir_mode  => $logrotate_olddir_mode,
    create       => "${logrotate_create_mode} ${logrotate_create_owner} ${logrotate_create_group}",
  }

}
