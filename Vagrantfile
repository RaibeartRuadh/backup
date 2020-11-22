# -*- mode: ruby -*-
# vi: set ft=ruby :

server = "192.168.10.10"
backup = "192.168.10.11"

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.define "server" do |server|
      webserver.vm.hostname = "server"
    webserver.vm.network "private_network", ip: server
    server.vm.hostname = "server"
  end

  config.vm.define "backup" do |backup|
      webserver.vm.hostname = "backup"
    webserver.vm.network "private_network", ip: backup
    backup.vm.hostname = "backup"
  end

end
