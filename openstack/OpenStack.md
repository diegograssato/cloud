#Base
yum install ntpdate wget htop iptraf openssh-clients tar nc 

#Openstack
yum install https://www.rdoproject.org/repos/rdo-release.rpm 
yum install -y centos-release-openstack-queens
yum update -y
yum install  openstack-packstack -y


# Set SELinux into the permissive mode
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
echo 0 > /selinux/enforce
---------------------------------------------------------------------
10.20.10.101

eth0 192.168.2.13 - Network node
eth1--| 
      |
      |
eth1--|
eth0 192.168.2.14 - Compute node

eth0 192.168.2.12 - Controller node

# On host
brctl addbr external
ifconfig external 192.168.2.1 netmask 255.255.255.0 up

brctl addbr internal
ifconfig internal 10.0.1.1 netmask 255.255.255.0 up

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


CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=physnet1:br-eth1
CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-eth1:eth1
CONFIG_NEUTRON_OVS_BRIDGES_COMPUTE=br-eth1


CONFIG_NEUTRON_ML2_TYPE_DRIVERS=vxlan
CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=vxlan
CONFIG_NEUTRON_ML2_MECHANISM_DRIVERS=openvswitch
CONFIG_NEUTRON_ML2_FLAT_NETWORKS=*
CONFIG_NEUTRON_ML2_VLAN_RANGES=
CONFIG_NEUTRON_ML2_TUNNEL_ID_RANGES=
CONFIG_NEUTRON_ML2_VXLAN_GROUP=
CONFIG_NEUTRON_ML2_VNI_RANGES=10:100
CONFIG_NEUTRON_L2_AGENT=openvswitch
CONFIG_NEUTRON_LB_TENANT_NETWORK_TYPE=local
CONFIG_NEUTRON_LB_VLAN_RANGES=
CONFIG_NEUTRON_LB_INTERFACE_MAPPINGS=
CONFIG_NEUTRON_OVS_TENANT_NETWORK_TYPE=vxlan
CONFIG_NEUTRON_OVS_VLAN_RANGES=physnet1:4000:4094
CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=physnet1:br-eth1
CONFIG_NEUTRON_OVS_BRIDGE_IFACES=
CONFIG_NEUTRON_OVS_TUNNEL_RANGES=1000:1100
CONFIG_NEUTRON_OVS_TUNNEL_IF=eth1
CONFIG_NEUTRON_OVS_VXLAN_UDP_PORT=4789
 

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



# Network configuration
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /root/ifcfg-eth0.backup
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-br-ex
cp /etc/sysconfig/network-scripts/ifcfg-eth1 /root/ifcfg-eth1.backup

  cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=none
NAME=eth0
UUID=80daf19b-5fdc-4783-a553-61f429eb8c85
DEVICE=eth0
ONBOOT=yes
PEERDNS=no
PEERROUTES=no
DEFROUTE=yes
USERCTL=no
NM_CONTROLLED=no
EOF

  cat << EOF > /etc/sysconfig/network-scripts/ifcfg-br-ex
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6_ADDR_GEN_MODE=stable-privacy
NAME=br-ex
DEVICE=br-ex
ONBOOT=yes
IPADDR=192.168.2.14
PREFIX=24
GATEWAY=192.168.2.1
DNS1=201.55.232.74
PEERDNS=no
PEERROUTES=no
DEFROUTE=yes
USERCTL=no
NM_CONTROLLED=no
EOF

  cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth1
BOOTPROTO=none
DEVICE=eth1
ONBOOT=yes
TYPE=Ethernet
USERCTL=no
NM_CONTROLLED=no
EOF
 
ovs-vsctl add-port br-ex eth0; ovs-vsctl add-port br-eth1 eth1; systemctl restart network
ovs-vsctl show

source /root/keystonerc_admin 

# Network

brctl addbr external
ifconfig external 192.168.2.1 netmask 255.255.255.0 up

brctl addbr internal
ifconfig internal 10.0.1.1 netmask 255.255.255.0 up 



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


# Create private network.

openstack network create --internal --share internal
openstack subnet create internal_subnet --subnet-range 10.0.1.0/24 --dhcp --gateway 10.0.1.1 --network internal --allocation-pool start=10.0.1.170,end=10.0.1.180

openstack network create --external --share external
openstack subnet create external_subnet --subnet-range 192.168.2.0/24 --no-dhcp --gateway 192.168.2.1 --network external --allocation-pool start=192.168.2.70,end=192.168.2.80

openstack router create external_router
openstack router set external_router --external-gateway external
openstack router add subnet external_router external_subnet

openstack router set external_router --route destination=192.168.2.0/24,gateway=192.168.2.12


openstack router create internal_router
openstack router set internal_router --external-gateway external
openstack router add subnet internal_router internal_subnet

openstack router set external_router --route destination=192.168.2.0/24,gateway=192.168.2.12

openstack router set internal_router --route destination=10.0.1.0/24,gateway=10.0.1.1


openstack port create dtux_port_1 --network external
openstack port create dtux_port_1 --network internal


openstack port create dtux_port_2 --network external --fixed-ip subnet=209aacb3-6369-4cb9-b979-eb5c5b61bb45,ip_address=192.168.2.2
openstack port create dtux_port_ubuntu --network internal --fixed-ip subnet=2d1374f0-549a-473d-8caa-b6f6d75422bc,ip_address=10.0.1.180

 openstack port create dtux_port_ubuntu --network internal --fixed-ip subnet=2d1374f0-549a-473d-8caa-b6f6d754220c,ip-address=10.0.1.18
 openstack port create dtux_port_ubuntu --network internal --fixed-ip subnet=internal_subnet,ip-address=10.0.1.80 --security-group dtux_sec
 openstack port create port_ubuntu --network internal --fixed-ip subnet=internal_subnet,ip-address=10.0.1.90 --security-group dtux_sec

openstack flavor list
openstack flavor create --public --vcpus 1 --ram 1028 --disk 1 --id 7 m2.tiny

openstack flavor create --public --vcpus 8 --ram 4048 --disk 10 --id 1 m1.tiny

openstack flavor  delete m1.tiny


openstack security group create --project admin dtux_sec
openstack security group rule create --protocol tcp --dst-port 22 --ingress --project admin dtux_sec
openstack security group rule create --protocol icmp --ingress --project admin dtux_sec

openstack server group list
openstack server group create zone_one


wget https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
openstack image create --container-format bare --disk-format qcow2 --file /root/CentOS-7-x86_64-GenericCloud.qcow2 --public "CentOS_7"

wget https://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img
openstack image create --container-format bare --disk-format qcow2 --file /root/ubuntu-16.04-server-cloudimg-amd64-disk1.img --public "ubuntu_14_04"


openstack server create --flavor m1.tiny --image CentOS_7 --port dtux_port_ubuntu --availability-zone nova --security-group dtux_sec --user-data /tmp/user-data centos_inst_1
openstack console log show --lines 40 centos_inst_1

openstack server create --flavor m1.tiny --image "ubuntu_14_04" --port port_ubuntu --availability-zone nova --security-group dtux_sec --user-data /tmp/user-data ubuntu_inst_2
openstack console log show --lines 40 ubuntu_inst_2
openstack server delete centos_inst_2


openstack server add floating ip cirros_inst_1 192.168.2.71 

 ovs-vsctl -t 10 -- --if-exists del-port br-ex eth0 -- add-port br-ex eth0


 ovs-vsctl -t 10 -- --if-exists del-port br-eth1 eth1 -- add-port br-eth1 eth1

# others


https://www.tecmint.com/ngxtop-monitor-nginx-log-files-in-real-time-in-linux/
https://www.tecmint.com/learn-vi-commands-with-pacvim-game/
https://www.tecmint.com/ctop-monitor-docker-containers/
https://www.tecmint.com/mtr-a-network-diagnostic-tool-for-linux/



https://www.tecmint.com/install-nagios-in-linux/
https://www.tecmint.com/how-to-install-and-setup-monit-linux-process-and-services-monitoring-program/

openstack flavor create --public --vcpus 1 --ram 1028 --disk 1 --id 7 m2.tiny









--------------------------------------------------------------------------------------------------------

https://www.ovirt.org/documentation/install-guide/appe-Configuring_a_Hypervisor_Host_for_PCI_Passthrough/


vi /etc/default/grub
  ...
  GRUB_CMDLINE_LINUX="nofb splash=quiet console=tty0 ... intel_iommu=on
  ...

grub2-mkconfig -o /boot/grub2/grub.cfg


vi /etc/modprobe.d/kvm.conf 
options kvm_intel nested=1
options vfio_iommu_type1 allow_unsafe_interrupts=1

reboot

--------------------------------------------------------------------------------------------------------
104.155.149.16
10.10.0.3 - compute
172.19.39.133 - compute
ssh-keygen -t rsa -b 4096 -C "root@compute-1.dtux.lan" -N ""


35.184.249.10
10.10.0.2 -  controller
172.19.39.131 - controller
ssh-keygen -t rsa -b 4096 -C "root@controller.dtux.lan" -N ""

tD<L9~B>%!iPW=>


cat > /tmp/user-data << _EOF_
#cloud-config
bootcmd:
   - echo "nameserver 201.55.232.74" > /etc/resolv.conf
   - echo "domain dtux.lan" >> /etc/resolv.conf

users:
  - default
  - name: ubuntu
    lock-passwd: false
    plain_text_passwd: 'passw0rd'
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
  - name: root
    lock-passwd: false
    plain_text_passwd: 'anna'

runcmd:
   - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config

package_update: true
package_upgrade: false
packages:
  - vim 
manage_etc_hosts: true
_EOF_


#######################
# Prepare GlusterFS disks
mkfs -t xfs -L brick1 /dev/sdb
mkdir -p /glusterfs/brick1

# Mount GlusterFS disks
- Edit /etc/fstab file on both nodes and add the following line:
/dev/sdb   /glusterfs/brick1   xfs   defaults   1 2

mount -a

# Open GlusterFS ports on firewall

- GlusterFS by default uses the following ports:

24007/TCP – Gluster Daemon
24008/TCP – Gluster Management
49152/TCP – Brick port (for GlusterFS version 3.7 each new brick will use next new port: 49153, 49154, etc…)
38465-38469/TCP – Gluster NFS service
111/TCP/UDP – Portmapper
2049/TCP – NFS Service

# Install GlusterFS software

yum install glusterfs centos-release-gluster  -y
yum install glusterfs-server -y

systemctl enable glusterd.service && systemctl start glusterd.service

# Configure GlusterFS trusted pool
host A - gluster peer probe 192.168.2.36
host B - gluster peer probe 192.168.2.35

gluster peer status

# Set up a GlusterFS volume
- Create volume directory on both nodes:
 mkdir /glusterfs/brick1/

# Create volume from any single node:
gluster volume create gluster_volume_0 replica 2 transport tcp 192.168.2.35:/glusterfs/brick1/gluster_volume_0 192.168.2.36:/glusterfs/brick1/gluster_volume_0

# Start volume from any single GlusterFS node:
gluster volume start gluster_volume_0
gluster volume set gluster_volume_0 readdir-ahead on
gluster volume set gluster_volume_0 performance.client-io-threads on

gluster volume set gluster_volume_0 auth.allow 192.168.2.14

# Verify volume from any single node:
gluster volume info all

# Remove volume
gluster volume stop gluster_volume_0
gluster volume delete gluster_volume_0


# Mount GlusterFS volume on client machine
yum install glusterfs glusterfs-fuse attr -y
mount -t glusterfs 192.168.2.35:/gluster_volume_0 /mnt/volume/
mkdir -p /mnt/volume

mount -t glusterfs 192.168.2.35:/gluster_volume_0 /mnt/volume
df -hT | grep /mnt/volume


# If you want to access this volume “gluster_volume_0” via nfs set the following :
gluster volume set gluster_volume_0 nfs.disable off


 