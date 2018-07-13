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
MEM=6096
 
# Number of virtual CPUs
CPUS=8
DISK_GB=40
IPADDR=192.168.2.12
MSK=255.255.255.0
DOMAIN="dtux.lan"
UUID="$(uuidgen)"
VM_NAME="controller"
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
MAC="f8:34:41:37:fe:f1"
# Bridge for VMs (default on Fedora is bridge0)
BRIDGE="external"


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
    mac_address: ${MAC}
    subnets:
      - type: static
        address: ${IPADDR}
        netmask: ${MSK}
        routes:
          - network: 0.0.0.0
            netmask: 0.0.0.0
            gateway: ${IPADDR%.*}.1
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
      --network bridge=${BRIDGE},model=virtio,mac=${MAC}  \
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

    