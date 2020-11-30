# -*- mode: ruby -*-
# vi: set ft=ruby :
###
MACHINES = {
  :server => {
        :box_name => "centos/7",
        :ip_addr => '192.168.10.10',
        :memory => '512',
        :cpu => '1',
        :playbook => 'playserver.yml'
  },
  :backup => {
        :box_name => "centos/7",
        :ip_addr => '192.168.10.11',
        :memory => '512',
        :cpu => '1',
        :playbook => 'playbackup.yml'
  }
}
#### 
Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
      config.vm.define boxname do |box|
          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s
          box.vm.network "private_network", ip: boxconfig[:ip_addr]
          box.vm.provider :virtualbox do |vb|
            vb.memory = boxconfig[:memory]
            vb.cpus = boxconfig[:cpu]
       end
          box.vm.provision :ansible do |ansible|
            ansible.limit = "all"
            ansible.playbook = boxconfig[:playbook]
            #ansible.verbose = "vv"
          end
          #box.vm.provision "shell", run: "always", path: "server.sh"
      end
  end
end


















