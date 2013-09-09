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
