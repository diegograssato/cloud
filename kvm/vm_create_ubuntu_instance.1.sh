#!/usr/bin/env bash

# Name: VM - Create Ubuntu Instance
# Default user: root
# Timeout: 300 s
# Remarks: Template (REPLACE PARAMETERS AS NECESSARY)
#          Images must be already available (see distribute script)

set -euf -o pipefail

# parameters
uuid=$(uuidgen)
vm=ubuntu-${uuid}
vm_vcpus=2
vm_mem_mb=4096
vm_root_passwd=diego
vm_disk_gb=20
storage=/Dados/storage/kvm
instances=${storage}/instances
 
# create vm folder
mkdir -p ${instances}/${vm}
IPADDR=10.0.70.2
INTERFACE=ens3
# copy image file
cp /var/lib/libvirt/images/ubuntu-16.04-server-cloudimg-amd64-disk1.img ${instances}/${vm}/${vm}-disk1.qcow2
# Cloud init files
USER_DATA=user-data
META_DATA=meta-data

cat > ${USER_DATA}  <<EOF
#cloud-config
# Hostname management
preserve_hostname: False
hostname: ${uuid}
fqdn: ${uuid}.dtux.org

# Remove cloud-init when finished with it
#  - echo "curl http://10.0.70.1:2379/v2/keys/_etcd/machines/${uuid} -XPUT -d value='{\"Id\":\"${uuid}\", \"IP\":\"\$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)\"}'" > /tmp/custom.sh && chmod 777 /tmp/custom.sh
#  - echo "127.0.0.1 ${uuid}" >> /etc/hosts
#  - [ bash, -c, "/tmp/custom.sh" ]
runcmd:
  - echo "nameserver 201.55.232.74" >> /etc/resolv.conf  
  - /etc/init.d/network restart
  - ifdown ${INTERFACE}
  - ifup ${INTERFACE}
  - [ apt, -y, remove, cloud-init ]  

# Configure where output will go
output:
  all: ">> /var/log/cloud-init.log"

users:
  - name: ubuntu
    lock-passwd: false
    plain_text_passwd: 'passw0rd'
    ssh-authorized-keys:
      - $(cat $HOME/.ssh/id_rsa.pub)
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
  - name: root
    ssh-authorized-keys: 
      - $(cat $HOME/.ssh/id_rsa.pub)
 
EOF

cat > ${META_DATA}  <<EOF
instance-id: ${uuid}
local-hostname: ${uuid}
network-interfaces: |
  iface ${INTERFACE} inet dhcp
EOF
# cat > ${META_DATA}  <<EOF
# instance-id: ${uuid}
# local-hostname: ${uuid}
# network-interfaces: |
#   iface ${INTERFACE} inet static
#   address $IPADDR
#   network ${IPADDR%.*}.0
#   netmask 255.255.255.0
#   broadcast ${IPADDR%.*}.255
# EOF

genisoimage -output ${instances}/${vm}/${vm}.iso -volid cidata -joliet -rock user-data meta-data

# resize disk
qemu-img resize ${instances}/${vm}/${vm}-disk1.qcow2 ${vm_disk_gb}GB

# create domain
virt-install --name ${vm} \
  --ram ${vm_mem_mb} \
  --vcpus ${vm_vcpus} \
  --import \
  --disk ${instances}/${vm}/${vm}-disk1.qcow2,bus=virtio \
  --disk ${instances}/${vm}/${vm}.iso,device=cdrom,perms=ro \
  --network bridge=docker0 \
  --noautoconsole \
  --graphics spice \
  --print-xml > ${instances}/${vm}/${vm}.xml

# define domain
virsh define ${instances}/${vm}/${vm}.xml

# start it
virsh start ${vm}

rm user-data meta-data
