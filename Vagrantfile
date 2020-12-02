# -*- mode: ruby -*-
# vi: set ft=ruby :

diskdir = './secondDisk.vdi'
  
#### 
Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.define "server" do |server|
    server.vm.synced_folder ".", "/vagrant", disabled: true
    server.vm.network "private_network", ip: "192.168.10.10"
    server.vm.provider "virtualbox" do |vb|
      	  vb.memory = 1024
          vb.cpus = 2
    server.vm.hostname = "server"
    	unless File.exist?(diskdir)
          vb.customize ['createhd', '--filename', diskdir, '--variant', 'Fixed', '--size', 2 * 1024]
        end
          vb.customize ['storageattach', :id,  '--storagectl', 'IDE', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', diskdir]
       # end
        end
    server.vm.hostname = "server"
    server.vm.provision "shell", path: "server.sh"
    server.vm.provision :ansible do |ansible|
            ansible.limit = "all"
            ansible.playbook = 'playserver.yml'
            #ansible.verbose = "vv"
          end
    end

  config.vm.define "backup" do |backup|
    backup.vm.network "private_network", ip: "192.168.10.11"
    backup.vm.provider :virtualbox do |vb|
      	  vb.memory = 1024
          vb.cpus = 2
        
      end
 
    backup.vm.provision :ansible do |ansible|
           ansible.limit = "all"
           ansible.playbook = 'playbackup.yml'
            #ansible.verbose = "vv"
          end
          #box.vm.provision "shell", run: "always", path: "server.sh"
      end

end







