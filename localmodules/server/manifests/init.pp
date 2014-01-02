class server { 
  Package{
    ensure => "present",
  }
  package{ ["tmux"]: }


  class { "server::users": } ->
  class { "server::user_data": } ->
  class { "server::personal":
    user => "varokas",
  } ->
  class { "server::teamcity":
    name => "TeamCity-8.0.5",
  } ->
  class { "server::foresee":
  } 

} 

class server::foresee {
  class { "nodejs": 
    manage_repo => true
  } -> 
  package { "jasmine-node":
    provider => "npm",
    ensure => "present",
  } ->
  package { "nodemon":
    provider => "npm",
    ensure => "present",
  }

  package { ["firefox","xvfb","unzip"]: 
    ensure => "present",
  }
  
  $teamcity_port = 8111
  $foresee_port = 3000
  $foresee_qa_port = 3002

  package { "haproxy": 
    ensure => "present",
  } -> 
  file { "/etc/haproxy/haproxy.cfg": 
    ensure => "file",
    mode => "0644",
    owner => "root",
    group => "root",
    content => template("server/haproxy.cfg.erb"),
    notify => Service["haproxy"],
  } -> 
  file_line { "enable haproxy": 
    path => "/etc/default/haproxy",
    line => "ENABLED=1",
    match => "ENABLED=",
  } 
  service { "haproxy":
    ensure => "running",
    subscribe => File["/etc/haproxy/haproxy.cfg"],
  }

 server::foresee::upstart { "foresee": 
    service_name => "foresee", 
    root_path => "/opt",
    port => "3000",
 }   
 server::foresee::upstart { "foresee-qa": 
    service_name => "foresee-qa", 
    root_path => "/opt",
    port => "3002",
 } 
}

define server::foresee::upstart($service_name, $root_path, $port)  {
  $path = "${root_path}/${service_name}/foresee"
  $logfile_name = "node-${service_name}.log"

  file { "/etc/init/${service_name}.conf":
    owner => "root",
    group => "root",
    content => template("server/foresee-service.conf.erb"),
    mode => 0755,
    ensure => "file",
  } -> 
  service { $service_name: 
    ensure => 'running',
    provider => 'upstart',
  }
}

class server::teamcity($name) { 
  package{ "openjdk-7-jdk":
    ensure => "present",
  } ->
  archive { $name: 
    ensure => present,
    url    => "http://download.jetbrains.com/teamcity/${name}.tar.gz",
    target => '/var',
    root_dir => 'TeamCity',
    checksum => false,
  } ->
  file { "/etc/init.d/teamcity":
    owner => "root",
    group => "root",
    source => "puppet:///modules/server/teamcity",
    mode => 0755,
    ensure => "file",
  }
  service { "teamcity": 
    ensure => "running",
    subscribe => File["/etc/init.d/teamcity"],
  }
}
class server::personal($user) { 
  $home = "/home/${user}"
  
  class { "vim": 
    user => $user,
    home_dir => $home,
  } ->
  vim::plugin { "nerdtree":
   source => "https://github.com/scrooloose/nerdtree.git",
  }
   
}

class server::users {
  $users_default = { 
    ensure => "present",
    managehome => true,
    gid => "sudo",
    shell => "/bin/bash",
  } 
  $users = {
    "varokas" => {
      password => '$1$k8ggtHzJ$d6rxI.AuN9976pPoU444M/',
    },
    "thsea" => {
      password => '$1$5cnmQhGe$RRHg9gL5sx3jLM9NK1x4j0',
    }
  }

  create_resources(user, $users, $users_default) 
}

class server::user_data {
  $thsea = hiera("thsea")
  $thsea_id_rsa = $thsea["id_rsa"]

  file { '/home/thsea/.ssh/id_rsa':
    ensure  => 'file',
    content => $thsea_id_rsa,
    owner   => 'thsea',
    group   => 'sudo',
    mode    => '600',
  } 

  file { '/home/thsea/.ssh/id_rsa.pub':
    ensure  => 'file',
    content => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDArADXfPgs0h+phytvdxQrsvsKxxve2O+6tRQ/dFAcJy/hg5/Fi7yZDi3iNRDWj/3FyFUjcuV+joYdORiUUFXdpY2lOf/qG0LW3e0Ienoal7N3M6xZo90WFHFDiVJ4FSUmxgGBS25lFXU1Erlg6x4J8u0HlaPKNwD3JOkZ4slkghdL5kN6FmvaOX4Jts2wD9m97wQFK/BfVzkqCpzQkUHi1/xoDKkTKnKJsKs/SAYCTaMbEh2bEbJ/OPm8LHzn5sFqQq1Ly6w8UmvcBbWaWiuUeZe+9XP/nnsk70Ei2QnJ7/ugC8uNlivFHza0cM3qebhrPYgI+aFkUtO+XpnbYlp2tSfGZ/JG90rTVkAWx1DgmWKuEpZXQ74YON3k/0j0AqIBBKQt5ExLPb0hwtVksHBIiKOuBeCx4nDg0pU4Q7iniwkk5BFtaMciQFPZ9fKfH0zkeqKxriFtYiXd0XWCOjJid4KdaQCnumh/X8zgv8GkujYsxRzRgOjySbgs4SVpoIvkKjmt5s2pEyqsWCXxQq/tKf6SKMNCVXSIzwkvijuo9VqU6Qk6aswjux9DyKtnkXSOuNb2FGJiIf3F7+djt3VFC6yoYEFRoJwIJgZxGDlawELhx3JFsENvwo7Yw9MjNB27UMwlsyR2K7AbTt2jEIxZw+f4Mgspa4hybdSBtQaIMQ== thsea@li124-54',
    owner   => 'thsea',
    group   => 'sudo', 
    mode    => '644',
  }
}
