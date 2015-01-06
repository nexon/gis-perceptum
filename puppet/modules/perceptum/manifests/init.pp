include postgresql

class perceptum {

  class { 'postgresql::globals':
    manage_package_repo => true,
    version             => '9.1',
  }->
  class { 'postgresql::server': }

  class {'postgresql::server::postgis':}

  postgresql::server::database { 'template_postgis':
    istemplate => true,
    template   => 'template1',
  }

  if $::postgresql::globals::globals_version >= '9.1' and $::postgresql::globals::globals_postgis_version >= '2.0' {
    postgresql_psql {'Add postgis extension on template_postgis':
      db      => 'template_postgis',
      command => 'CREATE EXTENSION postgis',
      unless  => "SELECT extname FROM pg_extension WHERE extname = 'postgis'",
      require => Postgresql::Server::Database['template_postgis'],
    } ->
    postgresql_psql {'Add postgis_topology extension on template_postgis':
      db      => 'template_postgis',
      command => 'CREATE EXTENSION postgis_topology',
      unless  => "SELECT extname FROM pg_extension WHERE extname = 'postgis_topology'",
    }
  }
  else {
    $script_path = $::osfamily ? {
      'Debian' => $::postgresql::globals::globals_version ? {
        '8.3'   => '/usr/share/postgresql-8.3-postgis',
        default => "/usr/share/postgresql/${::postgresql::globals::globals_version}/contrib/postgis-${::postgresql::globals::globals_postgis_version}",
      },
      'RedHat' => "/usr/pgsql-${::postgresql::globals::globals_version}}/share/contrib/postgis-${::postgresql::globals::globals_postgis_version}",
    }
    Exec {
      path => ['/usr/bin', '/bin', ],
    }
    exec { 'createlang plpgsql template_postgis':
      user    => 'postgres',
      unless  => 'createlang -l template_postgis | grep -q plpgsql',
      require => Postgresql::Server::Database['template_postgis'],
    } ->
    exec { "psql -q -d template_postgis -f ${script_path}/postgis.sql":
      user   => 'postgres',
      unless => 'echo "\dt" | psql -d template_postgis | grep -q geometry_columns',
    } ->
    exec { "psql -q -d template_postgis -f ${script_path}/spatial_ref_sys.sql":
      user   => 'postgres',
      unless => 'test $(psql -At -d template_postgis -c "select count(*) from spatial_ref_sys") -ne 0',
    }
  }

  postgresql::server::role { 'vagrant':
    password_hash => postgresql_password('vagrant', 'vagrant'),
  }

  postgresql::server::database_grant { 'template_postgis':
    privilege => 'ALL',
    db        => 'template_postgis',
    role      => 'vagrant',
  }

}
