box	= 'precise64'
url	= 'http://files.vagrantup.com/precise64.box'
ram = '2048'

Vagrant.configure("2") do |config|
	config.vm.box = box
	config.vm.box_url = url
	config.vm.hostname = "cribogis"
	config.vm.synced_folder "glassfish", "/opt/glassfish4"
	config.vm.network "private_network", ip: "192.168.0.50"
	config.vm.network "forwarded_port", guest: 8080, host: 8080
	config.vm.network "forwarded_port", guest: 4848, host: 4848
	config.vm.network "forwarded_port", guest: 5433, host: 5433

	config.vm.provider "virtualbox" do |vb|
		vb.customize [
			'modifyvm', :id,
			'--memory', ram
		]
	end

	config.vm.provision "puppet" do |puppet|
		puppet.manifests_path = 'puppet/manifests'
		puppet.manifest_file = 'site.pp'
		puppet.module_path = 'puppet/modules'
	end

end
