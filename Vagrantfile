# -*- mode: ruby -*-
# vi: set ft=ruby :

SERVER_IP = "192.168.10.10"
BACKUP_IP = "192.168.10.11"
#diskdir = './Disk.vdi'

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.define "server" do |server|
    server.vm.network "private_network", ip: SERVER_IP
    server.vm.provider "virtualbox" do |vb|
      	  vb.memory = 1024
          vb.cpus = 2
    server.vm.hostname = "server"
         unless File.exist?('./Disk.vdi')
          vb.customize ['createhd', '--filename', './Disk.vdi', '--variant', 'Fixed', '--size', 2 * 1024]
        end
          vb.customize ['storageattach', :id,  '--storagectl', 'IDE', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', './Disk.vdi']
       end
      server.vm.provision "ansible" do |ansible|
      ansible.playbook = "playserver.yml"
    end
      server.vm.provision "shell", path: "server.sh"
    end


  config.vm.define "backup" do |backup|
    backup.vm.hostname = "backup"
    backup.vm.network "private_network", ip: BACKUP_IP
        backup.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 2      
    end
    backup.vm.provision "ansible" do |ansible|
      ansible.playbook = "playbackup.yml"
    end
  end
end



















