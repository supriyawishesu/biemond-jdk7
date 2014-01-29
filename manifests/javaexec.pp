# jdk7::javaexec
#
# unpack the java tar.gz
# set the default java links
# set this java as default
#
define javaexec (
  $path                 = undef,
  $fullVersion          = undef,
  $jdkfile              = undef,
  $alternativesPriority = undef,
  $user                 = undef,
  $group                = undef,
) {

  # set the Exec defaults
  Exec {
    path      => "/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:",
    logoutput => true,
    user      => $user,
    group     => $group,
  }

  # set the defaults for File
  File {
    replace => false,
    owner   => $user,
    group   => $group,
    mode    => 0755,
  }

  # check java install folder
  if ! defined(File["/u01/app/oracle/product/java"]) {
    file { "/u01/app/oracle/java" :
      ensure  => directory,
    }
  }

  # extract gz file in /usr/java
  exec { "extract java ${fullVersion}":
    cwd     => "/u01/app/oracle/product/java",
    command => "tar -xzf ${path}/${jdkfile}",
    creates => "/u01/app/oracle/product/java/${fullVersion}",
    require => File["/u01/app/oracle/product/java"],
  }

  # set permissions
  exec { "chown -R oracle:noinstall /usr/java/${fullVersion}":
    unless  => "ls -al /usr/java/${fullVersion}/bin/java | awk ' { print \$3 }' |  grep  root",
    require => Exec["extract java ${fullVersion}"],
  }

	# java link to latest
  file { '/u01/app/oracle/product/java/latest':
    ensure  => link,
    target  => "/u01/app/pracle/product/java/${fullVersion}",
    require => Exec["extract java ${fullVersion}"],
  }

	# java link to default
  file { '/u01/app/oracle/product/java/default':
    ensure  => link,
    target  => "/u01/app/oracle/product/java/latest",
    require => File['/u01/app/oracle/product/java/latest'],
  }

  case $osfamily {
    RedHat: {
			# set the java default
      exec { "default java alternatives ${fullVersion}":
        command => "alternatives --install /u01/app/oracle/product/bin/java java /u01/app/oracle/product/java/${fullVersion}/bin/java ${alternativesPriority}",
        require => File['/u01/app/oracle/product/java/default'],
        unless  => "alternatives --display java | /bin/grep ${fullVersion}",
      }
    }
    Debian, Suse:{
			# set the java default
      exec { "default java alternatives ${fullVersion}":
        command => "update-alternatives --install /u01/app/oracle/product/bin/java java /u01/app/oracle/product/java/${fullVersion}/bin/java ${alternativesPriority}",
        require => File['/u01/app/oracle/product/java/default'],
        unless  => "update-alternatives --list java | /bin/grep ${fullVersion}",
      }
    }
  }
}
