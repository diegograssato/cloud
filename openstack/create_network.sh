#!/usr/bin/env bash

# Name: VM - Create Ubuntu Instance
# Default user: root
# Timeout: 300 s
# Remarks: Template (REPLACE PARAMETERS AS NECESSARY)
#          Images must be already available (see distribute script)

#set -euf -o pipefail
clear 
# Directory to store images
IMAGES="/var/lib/libvirt/images"
 
# Location of cloud image
#IMAGE="${IMAGES}/CentOS-6-x86_64-GenericCloud.qcow2"
IMAGE="${IMAGES}/CentOS-7-x86_64-GenericCloud.qcow2"
 
STORAGE="/home/diego/projects/clould/openstack"
INSTANCES="${STORAGE}/instances"
 
# Amount of RAM in MB
MEM=2096
 
# Number of virtual CPUs
CPUS=4
DISK_GB=20
IPADDR=192.168.2.13
MSK=255.255.255.0
DOMAIN="dtux.lan"
UUID="$(uuidgen)"
VM_NAME="network"
INSTANCE_PATH="${INSTANCES}/${VM_NAME}"
 
# Check if domain already exists
virsh dominfo "${VM_NAME}" > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo -n "[WARNING] ${VM_NAME} already exists.  "
    read -p "Do you want to overwrite ${VM_NAME} [y/N]? " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
    else
        echo -e "\nNot overwriting ${VM_NAME}. Exiting..."
        exit 1
    fi
fi
 
# Cloud init files
USER_DATA=user-data
META_DATA=meta-data
NET_DATA=network-config
CI_ISO="${INSTANCE_PATH}/${VM_NAME}-cidata.iso"
DISK="${INSTANCE_PATH}/${VM_NAME}.qcow2" 

# Bridge for VMs (default on Fedora is bridge0)
EXTERNAL_BRIDGE="external"
EXTERNAL_BRIDGE_MAC="f8:34:41:37:fe:f4"
INTERNAL_BRIDGE="internal"
INTERNAL_BRIDGE_MAC="f8:34:41:37:fe:f5"

echo "INFO: Creating instance environment ${INSTANCE_PATH}" 

virsh dominfo ${VM_NAME} > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    echo "$(date -R) Destroying the ${VM_NAME} domain (if it exists)..."
 
    # Remove domain with the same name
    virsh shutdown "${VM_NAME}"
    sleep 5;
    virsh destroy "${VM_NAME}"
    virsh undefine "${VM_NAME}"

fi
if [[ -d "${INSTANCE_PATH}" ]]; then
   rm -rf "${INSTANCE_PATH}"
fi


echo "$(date -R) Creating instance path ${INSTANCE_PATH}"
mkdir -p "${INSTANCE_PATH}"
echo "$(date -R) Copyng disk ${INSTANCE_PATH}"
cp -v "${IMAGE}" "${DISK}"

pushd ${INSTANCE_PATH} > /dev/null
  
  
    # cloud-init config: set hostname, remove cloud-init package,
    # and add ssh-key 
    cat > $USER_DATA << _EOF_
#cloud-config
 
# Hostname management
preserve_hostname: False
hostname: ${VM_NAME}
fqdn: ${VM_NAME}.${DOMAIN}

bootcmd:
   - echo "nameserver 201.55.232.74" > /etc/resolv.conf
   - echo "domain dtux.lan" >> /etc/resolv.conf
   - echo "192.168.2.12   controller  controller.dtux.lan" >> /etc/hosts
   - echo "192.168.2.13   network     network.dtux.lan" >> /etc/hosts
   - echo "192.168.2.14   compute     compute.dtux.lan" >> /etc/hosts

# configure interaction with ssh server
ssh_svcname: ssh
ssh_deletekeys: True
ssh_keys:
  rsa_private: |
    -----BEGIN RSA PRIVATE KEY-----
    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
    -----END RSA PRIVATE KEY-----

  rsa_public: $(cat $HOME/projects/clould/openstack/keys/${VM_NAME}_rsa.pub)

users:
  - name: centos
    lock-passwd: false
    plain_text_passwd: 'passw0rd'
    ssh-authorized-keys:
      - $(cat $HOME/.ssh/id_rsa.pub)
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
  - name: root
    ssh_pwauth: True
    lock-passwd: false
    plain_text_passwd: 'root'
    ssh-authorized-keys: 
      - $(cat $HOME/.ssh/id_rsa.pub)
      - $(cat $HOME/projects/clould/openstack/keys/controller_rsa.pub)
      - $(cat $HOME/projects/clould/openstack/keys/network_rsa.pub)
      - $(cat $HOME/projects/clould/openstack/keys/compute_rsa.pub)      

runcmd:
   - [ yum, -y, remove, cloud-init ]
   - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config

package_update: true
package_upgrade: true
packages:
  - ntpdate
  - net-tools
  - chrony
  - openssh-clients
  - tar
  - nc
  - vim
  - git
 
final_message: "The system is finally up, authenticate using user ubuntu and pass 'passw0rd' on host ${IPADDR}"  

_EOF_
 
# Manging metadata cloud-init now
    cat > ${META_DATA} << _EOF_
instance-id: ${UUID}-${VM_NAME}
local-hostname: ${VM_NAME}
_EOF_

    cat > ${NET_DATA} << _EOF_
---
version: 1
config:
  - type: physical
    name: eth0
    mac_address: ${EXTERNAL_BRIDGE_MAC}
    subnets:
      - type: static
        address: ${IPADDR}
        netmask: ${MSK}
        routes:
          - network: 0.0.0.0
            netmask: 0.0.0.0
            gateway: ${IPADDR%.*}.1
  - type: physical
    name: eth1
    mac_address: ${INTERNAL_BRIDGE_MAC}
    subnets:
      - type: static
        address: 10.0.1.3
        netmask: ${MSK}      
  - type: nameserver
    address: [ 201.55.232.74, 8.8.4.4]
    search: [${VM_NAME}.${DOMAIN}]            
_EOF_
   
    echo "$(date -R) instance-id: ${VM_NAME}; local-hostname: ${VM_NAME}" 
    echo "$(date -R) INFO: qemu-img resize ${DISK}  ${DISK_GB}GB"  
    qemu-img resize ${DISK}  ${DISK_GB}GB
 
    # Create CD-ROM ISO with cloud-init config
    echo "$(date -R) Generating ISO for cloud-init..."
    genisoimage -output ${CI_ISO} -volid cidata -joliet -rock ${USER_DATA} ${META_DATA} ${NET_DATA}
 
    echo "$(date -R) Installing the domain and adjusting the configuration..."
 
    # create domain
    virt-install --name ${VM_NAME} \
      --boot loader=/var/lib/libvirt/images/bios.bin-1.11.0 \
      --ram ${MEM} \
      --vcpus ${CPUS} \
      --import \
      --disk ${DISK},device=disk,bus=scsi,discard=unmap,boot_order=1 \
      --disk ${CI_ISO},device=cdrom,device=cdrom,perms=ro,bus=sata,boot_order=2 \
      --network bridge=${EXTERNAL_BRIDGE},model=virtio,mac=${EXTERNAL_BRIDGE_MAC}  \
      --network bridge=${INTERNAL_BRIDGE},model=virtio,mac=${INTERNAL_BRIDGE_MAC} \
      --features hyperv_relaxed=on,hyperv_vapic=on,hyperv_spinlocks=on,hyperv_spinlocks_retries=8191,acpi=on \
      --clock hypervclock_present=yes \
      --controller type=scsi,model=virtio-scsi \
      --noautoconsole \
      --noapic \
      --graphics spice \
      --print-xml > ${VM_NAME}.xml

    echo "$(date -R) Define doamin ${VM_NAME}.xml."
    virsh define ${VM_NAME}.xml

    echo "$(date -R) Start it ${VM_NAME}."
    virsh start ${VM_NAME} 
  
    #virsh console ${VM_NAME}   
    FAILS=0   
    while true; do
        ping -c 1 ${IPADDR} >/dev/null 2>&1
        if [[ $? -ne 0 ]] ; then #if ping exits nonzero...
           FAILS=$[FAILS + 1]
           echo "INFO: Checking if server ${VM_NAME} with IP ${IPADDR} is online. (${FAILS} out of 20)" 
        fi

        nc -z -v -w5 ${IPADDR} 22 >/dev/null 2>&1
        if [[ $? -ne 0 ]] ; then #if wc exits nonzero...
           FAILS=$[FAILS + 1]
           echo "INFO: Checking if SSH server is online on ${VM_NAME}(${IPADDR})"
           
        else
           echo "INFO: server ${VM_NAME} is alive. let's remove cloud init files"
           break;
        fi

        if [[ ${FAILS} -gt 20 ]]; then
           echo "INFO: Server is still offline after 20min. I will end here!"
           exit 20;
        fi
        sleep 5;
    done
     
    # # Eject cdrom    
    #echo "$(date -R) Eject cdrom ${CI_ISO}." 
    # virsh detach-disk ${VM_NAME} ${CI_ISO}  --config 
    # if [ $? -eq 0 ] ; then
    #   echo "$(date -R) Removing metadata ISO ${CI_ISO}."
    #   rm -rf ${CI_ISO}
    # fi
    # Remove the unnecessary cloud init files
    #echo "$(date -R) Cleaning up cloud-init..."
    #rm -rf ${USER_DATA}  ${META_DATA} ${NET_DATA}
    echo "$(date -R) DONE. SSH to ${VM_NAME} using ${IPADDR}, with  username 'ubuntu' or 'root'."

popd > /dev/null

    