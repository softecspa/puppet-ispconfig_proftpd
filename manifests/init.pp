class ispconfig_proftpd (
  $home_dir               = params_lookup( 'home_dir' ),
  $uid                    = params_lookup( 'uid' ),
  $ssl                    = params_lookup( 'ssl' ),
  $ssl_domain             = params_lookup( 'ssl_domain' ),
  $root_dir               = params_lookup( 'root_dir' ),
  $ipv6                   = params_lookup( 'ipv6' ),
  $conf_file              = params_lookup( 'conf_file' ),
  $tls_conf               = params_lookup( 'tls_conf' ),
  $logrotate_olddir_owner = params_lookup( 'logrotate_olddir_owner' ),
  $logrotate_olddir_group = params_lookup( 'logrotate_olddir_group' ),
  $logrotate_olddir_mode  = params_lookup( 'logrotate_olddir_mode' ),
  $logrotate_create_owner = params_lookup( 'logrotate_create_owner' ),
  $logrotate_create_group = params_lookup( 'logrotate_create_group' ),
  $logrotate_create_mode  = params_lookup( 'logrotate_create_mode' ),
) inherits ispconfig_proftpd::params {

  validate_bool($ispconfig_proftpd::ssl)

  if $ispconfig_proftpd::ssl {
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

  $ensure_include_tls = $ispconfig_proftpd::ssl?{
    true  => 'present',
    false => 'absent'
  }

  file_line {'include_tls':
    ensure  => $ensure_include_tls,
    path    => $ispconfig_proftpd::conf_file,
    line    => "Include ${ispconfig_proftpd::tls_conf}",
    match   => "^Include ${ispconfig_proftpd::tls_conf}"
  }

  if $ispconfig_proftpd::ssl {

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
    include sslcert

    # pusha il file con le direttive per ssl
    file { "${ispconfig_proftpd::tls_conf}":
      ensure  => present,
      mode    => '0644',
      content => template('ispconfig_proftpd/etc/tls.conf.erb'),
      require => Package[$proftpd::package],
      notify  => Service[$proftpd::service],
    }

    #ruota solo i log del tls, il resto sono ruotati dal pacchetto
    include ispconfig_proftpd::tls_logrotate
  }
}
