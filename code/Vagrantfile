Vagrant.configure("2") do |config|
    config.vm.box = "sbeliakou/centos"
    # Zabbix Server
    config.vm.define "Zabbix-Server" do |server|
        server.vm.hostname = "Zabbix-Server"
        server.vm.network "private_network", ip: "172.31.31.254"

        server.vm.provider "virtualbox" do |vb|
            vb.name = "Zabbix-Server-Machine"
            vb.memory = "2048"
        end

        server.vm.provision 'shell', path: "zabbix-server.sh"
    end

    # Zabbix agent
    config.vm.define "Zabbix-Agent" do |agent|
        agent.vm.hostname = "Zabbix-Agent"
        agent.vm.network "private_network", ip: "172.31.31.100"

        agent.vm.provider "virtualbox" do |vb|
            vb.name = "Zabbix-Agent-Machine"
            vb.memory = "2048"
        end

        agent.vm.provision 'shell', path: "zabbix-agent.sh"
    end
end

