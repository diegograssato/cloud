 yum install -y puppet hiera openssh-clients tar nc rubygem-json

10.20.10.101

eth0 192.168.2.13 - Network node
eth1--| 
      |
      |
eth1--|
eth0 192.168.2.14 - Compute node

eth0 192.168.2.12 - Controller node

mysql -u root -p23b7079a77e24e22
use mysql;
GRANT ALL ON *.* to root@'192.168.2.12' IDENTIFIED BY '23b7079a77e24e22';
GRANT ALL ON *.* to root@'192.168.2.13' IDENTIFIED BY '23b7079a77e24e22'; 
GRANT ALL ON *.* to root@'192.168.2.14' IDENTIFIED BY '23b7079a77e24e22';

GRANT ALL ON *.* to root@'192.168.2.%' IDENTIFIED BY '23b7079a77e24e22';

GRANT ALL ON *.* to nova_api@'192.168.2.%' IDENTIFIED BY '0b028252703b4605';

nova_api:0dfa9207555c4d67@192.168.2.12/nova_api
mysql -u nova_api -p0dfa9207555c4d67 nova_api
FLUSH PRIVILEGES;

# Password for the MariaDB administrative user.
CONFIG_MARIADB_PW=diegoanna

# Password to use for the Identity service (keystone) to access the
# database.
CONFIG_KEYSTONE_DB_PW=diegoanna


# Default password to be used everywhere (overridden by passwords set
# for individual services or users).
CONFIG_DEFAULT_PASSWORD=diegoanna

CONFIG_NTP_SERVERS=0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org 
CONFIG_CONTROLLER_HOST=192.168.2.12
CONFIG_COMPUTE_HOSTS=192.168.2.14
CONFIG_NETWORK_HOSTS=192.168.2.13 
CONFIG_RH_OPTIONAL=n
CONFIG_NEUTRON_ML2_TYPE_DRIVERS=vlan
CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=vlan
CONFIG_NEUTRON_ML2_VLAN_RANGES=physnet1:1000:2000
CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=physnet1:br-eth1
CONFIG_PROVISION_DEMO=n
CONFIG_KEYSTONE_ADMIN_PW=password
 

bridge_mappings = physnet1:br-eth1
extnet:br-ex

systemctl stop postfix firewalld NetworkManager
systemctl disable postfix firewalld NetworkManager
systemctl mask NetworkManager
yum remove postfix NetworkManager NetworkManager-libnm -y

ntpdate 0.pool.ntp.org

packstack --gen-answer-file=answer-$(date +"%d.%m.%y").conf
packstack --timeout=600 --answer-file=/root/answer-07.07.18.1.conf
packstack --timeout=600 --allinone --provision-demo=n --os-heat-install=y

/etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=eth0
HWADDR=f8:34:41:37:fe:f4
UUID=80daf19b-5fdc-4783-a553-61f429eb8c85
DEVICE=eth0
ONBOOT=yes
IPADDR=192.168.2.13
PREFIX=24
GATEWAY=192.168.2.1
DNS1=201.55.232.74
PEERDNS=no
PEERROUTES=no
DEFROUTE=yes


BOOTPROTO=none
DEFROUTE=yes
DEVICE=eth0
GATEWAY=192.168.2.1
HWADDR=f8:34:41:37:fe:f1
IPADDR=192.168.2.12
NETMASK=255.255.255.0
ONBOOT=yes
TYPE=Ethernet
USERCTL=no

cp /etc/ssh/ssh_host_rsa_key.pub ~/.ssh/id_rsa_key.pub
cp /etc/ssh/ssh_host_rsa_key ~/.ssh/id_rsa

nova-manage api_db sync
Fix: https://github.com/openstack/oslo.db/commit/c432d9e93884d6962592f6d19aaec3f8f66ac3a2#diff-52043ef9a440ade65cc878df26b10604
163
vi /usr/lib/python2.7/site-packages/oslo_db/sqlalchemy/enginefacade.py
add - , 'use_tpool'


brctl addbr external
ifconfig external 192.168.2.1 netmask 255.255.255.0 up

brctl addbr internal
ifconfig internal 10.0.1.1 netmask 255.255.255.0 up










Para aqueles que ainda não se inscreveram, compartilhamos o cupom: "telegram_opbr18_50"

Acesse: http://openstackbr.com.br/events/2018/

















ssh-keygen -t rsa -b 4096 -C "root@controller.dtux.lan"
ssh-keygen -t dsa -C "root@controller.dtux.lan"

/home/diego/projects/clould/openstack/keys/controller_rsa
/home/diego/projects/clould/openstack/keys/controller_rsa


ssh-keygen -t rsa -b 4096 -C "root@controller.dtux.lan" -f /home/diego/projects/clould/openstack/keys/controller_rsa -N ""
ssh-keygen -t rsa -b 4096 -C "root@network.dtux.lan" -f /home/diego/projects/clould/openstack/keys/network_rsa -N ""
ssh-keygen -t rsa -b 4096 -C "root@compute.dtux.lan" -f /home/diego/projects/clould/openstack/keys/compute_rsa -N ""

ssh-keygen -t dsa -C "root@controller.dtux.lan" -f /home/diego/projects/clould/openstack/keys/controller_dsa -N ""
ssh-keygen -t dsa -C "root@network.dtux.lan" -f /home/diego/projects/clould/openstack/keys/network_dsa -N ""
ssh-keygen -t dsa -C "root@compute.dtux.lan" -f /home/diego/projects/clould/openstack/keys/commpute_dsa -N ""


https://www.tecmint.com/ngxtop-monitor-nginx-log-files-in-real-time-in-linux/
https://www.tecmint.com/learn-vi-commands-with-pacvim-game/
https://www.tecmint.com/ctop-monitor-docker-containers/
https://www.tecmint.com/mtr-a-network-diagnostic-tool-for-linux/



https://www.tecmint.com/install-nagios-in-linux/
https://www.tecmint.com/how-to-install-and-setup-monit-linux-process-and-services-monitoring-program/


 scp  root@192.168.2.12:/root/answer-06.07.18.conf


brctl addbr external
ifconfig external 192.168.2.1 netmask 255.255.255.0 up

brctl addbr internal
ifconfig internal 10.0.1.1 netmask 255.255.255.0 up

Create private network.

openstack network create --internal --share internal
openstack subnet create internal_subnet --subnet-range 10.0.1.0/24 --dhcp --gateway 10.0.1.1 --network internal --allocation-pool start=10.0.1.170,end=10.0.1.180

openstack network create --external --share external
openstack subnet create external_subnet --subnet-range 192.168.2.0/24 --no-dhcp --gateway 192.168.2.1 --network external --allocation-pool start=192.168.2.70,end=192.168.2.80

openstack router create external_router
openstack router set external_router --external-gateway external
openstack router add subnet external_router external_subnet

openstack router set external_router --route destination=192.168.2.0/24,gateway=192.168.2.12


openstack port create dtux_port_1 --network external
openstack port create dtux_port_2 --network external --fixed-ip subnet=209aacb3-6369-4cb9-b979-eb5c5b61bb45,ip_address=192.168.2.2


openstack flavor list
openstack flavor create --public --vcpus 1 --ram 128 --disk 1 --id 6 m2.tiny

wget https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create --container-format bare --file /root/cirros-0.4.0-x86_64-disk.img --public cirros_0.4.0




openstack security group create --project admin dtux_sec
 openstack security group rule create --protocol tcp --dst-port 22 --ingress --project admin dtux_sec
openstack security group rule create --protocol icmp --ingress --project admin dtux_sec

openstack floating ip create external


openstack server create --flavor m2.tiny --image cirros_0.4.0 --nic net-id=external --security-group dtux_sec cirros_inst_1

openstack server add floating ip cirros_inst_1 192.168.2.71 

 ovs-vsctl -t 10 -- --if-exists del-port br-ex eth0 -- add-port br-ex eth0

