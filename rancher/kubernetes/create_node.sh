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
IMAGE="${IMAGES}/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
 
STORAGE="$PWD"
INSTANCES="${STORAGE}/instances"
 
# Amount of RAM in MB
MEM=4096
 
# Number of virtual CPUs
CPUS=8
DISK_GB=60
IPADDR=192.168.2.21
MSK=255.255.255.0
DOMAIN="dtux.lan"
UUID="$(uuidgen)"
VM_NAME="kube-node"
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
EXTERNAL_BRIDGE_MAC="f8:35:41:37:fe:e1"
INTERNAL_BRIDGE="internal"
INTERNAL_BRIDGE_MAC="f8:35:41:37:fe:e2"

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
   - echo "nameserver 172.16.22.244" > /etc/resolv.conf
   - echo "domain dtux.lan" >> /etc/resolv.conf
   - echo "192.168.2.20   kube-master    kube-master.dtux.lan" >> /etc/hosts
   - echo "${IPADDR}   ${VM_NAME}    ${VM_NAME}.dtux.lan" >> /etc/hosts

# configure interaction with ssh server
ssh_svcname: ssh
ssh_deletekeys: True

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

runcmd:
   - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config

package_update: true
package_upgrade: false
packages:
  - ntpdate
  - net-tools
  - chrony
  - openssh-clients
  - tar
  - nc
  - vim
  - git
  - apt-transport-https
 
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
        address: 10.0.1.11
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

    