

kolla_base_distro: "centos"

# Valid options are [ binary, source ]
kolla_install_type: "binary"

kolla_internal_vip_address: "10.1.2.10"
network_interface: "eth0"
neutron_external_interface: "eth1"
designate_backend: "bind9"
designate_ns_record: "master.dtux.lan"
neutron_plugin_agent: "openvswitch"