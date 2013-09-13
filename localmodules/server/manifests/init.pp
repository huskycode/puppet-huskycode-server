class server { 
  Package{
    ensure => "present",
  }
  package{ ["tmux"]: }


  class { "server::users": } ->
  class { "server::personal":
    user => "varokas",
  } ->
  class { "server::teamcity":
    name => "TeamCity-8.0.3",
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

  package { ["firefox","xvfb"]: 
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
  }
  service { "haproxy":
    ensure => "running",
    subscribe => File["/etc/haproxy/haproxy.cfg"],
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
    }
  }

  create_resources(user, $users, $users_default)
}
