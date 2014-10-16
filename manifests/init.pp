class ispconfig_proftpd (
  $home_dir               = params_lookup( 'home_dir' ),
  $uid                    = params_lookup( 'uid' ),
  $tls                    = params_lookup( 'tls' ),
  $ssl_domain             = params_lookup( 'ssl_domain' ),
  $root_dir               = params_lookup( 'root_dir' ),
  $ipv6                   = params_lookup( 'ipv6' ),
  $conf_file              = params_lookup( 'conf_file' ),
  $vhosts_file            = params_lookup( 'vhosts_file' ),
  $ispconfig_file         = params_lookup( 'ispconfig_file' ),
  $conf_link              = params_lookup( 'conf_link' ),
  $tls_conf               = params_lookup( 'tls_conf' ),
  $logrotate_olddir_owner = params_lookup( 'logrotate_olddir_owner' ),
  $logrotate_olddir_group = params_lookup( 'logrotate_olddir_group' ),
  $logrotate_olddir_mode  = params_lookup( 'logrotate_olddir_mode' ),
  $logrotate_create_owner = params_lookup( 'logrotate_create_owner' ),
  $logrotate_create_group = params_lookup( 'logrotate_create_group' ),
  $logrotate_create_mode  = params_lookup( 'logrotate_create_mode' ),
  $logrotate_interval     = params_lookup( 'logrotate_interval' ),
  $logrotate_rotation     = params_lookup( 'logrotate_rotation' ),
  $logrotate_file         = params_lookup( 'logrotate_file' ),
  $logrotate_archive      = params_lookup( 'logrotate_archive' ),
) inherits ispconfig_proftpd::params {

  validate_bool($ispconfig_proftpd::tls)

  if $ispconfig_proftpd::tls {
    if $ispconfig_proftpd::ssl_domain == '' {
      fail('parameter ssl_domain should contain domain name of ssl cert & key')
    }
  }

  user { 'proftpd':
    ensure  => present,
    home    => $ispconfig_proftpd::home_dir,
    shell   => '/bin/false',
    system  => true,
    uid     => $ispconfig_proftpd::uid,
    gid     => 'nogroup',
  } ->

  class {'proftpd':}

  File_line {
    require => Package[$proftpd::package],
    notify  => Service[$proftpd::service]
  }

  file {$ispconfig_proftpd::conf_link:
    ensure  => link,
    target  => $ispconfig_proftpd::conf_file
  }

  file_line {'ipv6':
    path  => $ispconfig_proftpd::conf_file,
    line  => "UseIPv6             ${ispconfig_proftpd::ipv6}",
    match => '^UseIPv6'
  }

  file_line {'default_root':
    path  => $ispconfig_proftpd::conf_file,
    line  => 'DefaultRoot ~',
    match => '^DefaultRoot'
  }

  file_line {'ident_lookups':
    path  => $ispconfig_proftpd::conf_file,
    line  => 'IdentLookups off',
    match => '^IdentLookups'
  }

  file_line {'server_ident':
    path  => $ispconfig_proftpd::conf_file,
    line  => 'ServerIdent on "FTP Server ready."',
    match => '^ServerIdent'
  }

  file_line {'reverse_dns':
    path  => $ispconfig_proftpd::conf_file,
    line  => 'UseReverseDNS off',
    match => '^UseReverseDNS'
  }

  $ensure_include_tls = $ispconfig_proftpd::tls?{
    true  => 'present',
    false => 'absent'
  }

  file_line {'include_tls':
    ensure  => $ensure_include_tls,
    path    => $ispconfig_proftpd::conf_file,
    line    => "Include ${ispconfig_proftpd::tls_conf}",
    match   => "^Include ${ispconfig_proftpd::tls_conf}"
  }

  if $ispconfig_proftpd::tls {

    if ! defined(Sslcert::Cert[$ispconfig_proftpd::ssl_domain]) {
      sslcert::cert {$ispconfig_proftpd::ssl_domain:
        notify    => Service[$proftpd::service]
      }
    }
    else {
      Sslcert::Cert[$ispconfig_proftpd::ssl_domain] {
        notify +> Service[$proftpd::service]
      }
    }

    # questa include l'ho fatta anche all'interno della define sslcert::cert ma il valore non viene preso

    # pusha il file con le direttive per tls
    file { $ispconfig_proftpd::tls_conf:
      ensure  => present,
      mode    => '0644',
      content => template('ispconfig_proftpd/etc/tls.conf.erb'),
      require => Package[$proftpd::package],
      notify  => Service[$proftpd::service],
    }

    #ruota solo i log del tls, il resto sono ruotati dal pacchetto
    class {'ispconfig_proftpd::tls_logrotate':
      logrotate_olddir_owner  => $ispconfig_proftpd::logrotate_olddir_owner,
      logrotate_olddir_group  => $ispconfig_proftpd::logrotate_olddir_group,
      logrotate_olddir_mode   => $ispconfig_proftpd::logrotate_olddir_mode,
      logrotate_create_mode   => $ispconfig_proftpd::logrotate_create_mode,
      logrotate_create_owner  => $ispconfig_proftpd::logrotate_create_owner,
      logrotate_create_group  => $ispconfig_proftpd::logrotate_create_group,
      logrotate_interval      => $ispconfig_proftpd::logrotate_interval,
      logrotate_rotation      => $ispconfig_proftpd::logrotate_rotation,
      logrotate_file          => $ispconfig_proftpd::logrotate_file,
      logrotate_archive       => $ispconfig_proftpd::logrotate_archive,
    }
  }



  # VIRTUALHOST CREATION
  if ( $public_interface != undef ) or ( $private_interface != undef ) {
    $ensure_include_vhost     = 'present'
    $ensure_include_ispconfig = 'absent'
  } else {
    $ensure_include_vhost     = 'absent'
    $ensure_include_ispconfig = 'present'
  }

  file_line {'include_vhost':
    ensure  => $ensure_include_vhost,
    path    => $ispconfig_proftpd::conf_file,
    line    => "Include ${ispconfig_proftpd::vhosts_file}",
    match   => "^Include ${ispconfig_proftpd::vhosts_file}"
  }

  file_line {'include_ispconfig':
    ensure  => $ensure_include_ispconfig,
    path    => $ispconfig_proftpd::conf_file,
    line    => "Include ${ispconfig_proftpd::ispconfig_file}",
    match   => "^Include ${ispconfig_proftpd::ispconfig_file}"
  }

  if $ensure_include_vhost == 'present' {

    #BYPASS ispconfig file
    if $public_interface != undef {
      $public_ftp_address = inline_template("<%= ipaddress_${public_interface} %>")
      ispconfig_proftpd::vhost { $public_ftp_address : }
    }

    if $private_interface != undef {
      $private_ftp_address = inline_template("<%= ipaddress_${private_interface} %>")
      ispconfig_proftpd::vhost { $private_ftp_address : }
    }

    concat_build { 'proftpd_vhosts':
      order   => ['*.tmp'],
      target  => $ispconfig_proftpd::vhosts_file,
      notify  => Service['proftpd'],
    }

    concat_fragment { 'proftpd_vhosts+001.tmp':
      content => "#generated by puppet through ispconfig_proftpd::vhost define\nDefaultAddress localhost",
    }

    file { $ispconfig_proftpd::vhosts_file :
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => Concat_build['proftpd_vhosts']
    }
  } else {
    #USE ispconfig file
    file {$ispconfig_proftpd::ispconfig_file:
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
    }
  }

  #LOGROTATE BASIC
  case $::lsbdistcodename {
    'hardy': {
      # su hardy la rotazione è gestita da un cron mensile. Rimuovo il cron, e metto lo script
      # in cron.daily con rotazione 210 giorni
      file {'/etc/cron.monthly/proftpd':
        ensure  => absent
      }

      file {'/etc/cron.daily/proftpd':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/ispconfig_proftpd/logrotate'
      }
    }
    default: {
      augeas { 'logrotate_proftpd':
        context => '/files/etc/logrotate.d/proftpd-basic',
        changes => [
          "set rule[1]/schedule ${ispconfig_proftpd::logrotate_interval}",
          "set rule[1]/rotate ${ispconfig_proftpd::logrotate_rotation}",
        ],
        require => Class['puppet'],
      }
    }
  }
}
