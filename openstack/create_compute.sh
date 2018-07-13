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
MEM=4096
 
# Number of virtual CPUs
CPUS=8
DISK_GB=60
IPADDR=192.168.2.14
MSK=255.255.255.0
DOMAIN="dtux.lan"
UUID="$(uuidgen)"
VM_NAME="compute"
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
EXTERNAL_BRIDGE_MAC="f8:34:41:37:fe:f2"
INTERNAL_BRIDGE="internal"
INTERNAL_BRIDGE_MAC="f8:34:41:37:fe:f3"

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
        address: 10.0.1.2
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

    