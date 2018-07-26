#!/usr/bin/env bash
 
# Directory to store images
IMAGES="/var/lib/libvirt/images"
 
# Location of cloud image
UBUNTU=ubuntu-16.04-server-cloudimg-amd64-disk1.img
IMAGE="${IMAGES}/${UBUNTU}"
 
STORAGE="/home/CIT/dgrassato/projects/cloud/kubernetes"
INSTANCES="${STORAGE}/instances"

# Check if domain already exists
function _delete_vm() {

    VM_NAME=${1}
    INSTANCE_PATH="${INSTANCES}/${VM_NAME}"
    virsh dominfo "${VM_NAME}" > /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        echo "$(date +"%d-%m-%Y %H:%M:%S") - Destroying the ${VM_NAME} domain (if it exists)..."
    
        # Remove domain with the same name
        virsh destroy "${VM_NAME}"
        virsh undefine "${VM_NAME}"

    fi
    if [[ -d "${INSTANCE_PATH}" ]]; then
        rm -rfv "${INSTANCE_PATH}"
    fi
}


function _generate_vm() {
    
    DOMAIN="dtux.lan"
    UUID="$(uuidgen)"

    # Check if domain already exists
    virsh dominfo "${VM_NAME}" > /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        echo "[WARNING] ${VM_NAME} already exists.  "
        exit 0
    fi

    # Cloud init files
    USER_DATA="${CONFIG2}/user-data"
    META_DATA="${CONFIG2}/meta-data"
    NETWORK_DATA="${CONFIG2}/network-config"
    [[ -d "${CONFIG2}" ]] && echo "$(date +"%d-%m-%Y %H:%M:%S") - Cleaning up cloud-init..." && rm -rvf "${CONFIG2}"
    [[ ! -d  "${CONFIG2}" ]] && mkdir -p "${CONFIG2}"     
    # set amount of RAM in MB
    MEM=4096 
    # Set mumber of virtual CPUs
    CPUS=2
    # Set disk size
    DISK_GB=40

    ## NETWORK
    # Bridge for VMs (default on Fedora is bridge0)
    EXTERNAL_BRIDGE="external"
    EXTERNAL_BRIDGE_IP="192.168.2.20"
    EXTERNAL_BRIDGE_MASK="255.255.255.0"

    DNS="172.16.22.244"

    INTERNAL_BRIDGE="internal"
    INTERNAL_BRIDGE_IP="192.168.2.20"
    INTERNAL_BRIDGE_MASK="255.255.255.0"

    # Set password
    PASSWORD='passw0rd'
    # Set disk path
    DISK="${INSTANCE_PATH}/${VM_NAME}.qcow2"
    # Get timezone
    TIMEZONE=$(cat /etc/timezone)
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Get timezone: ${TIMEZONE}" 
    
    echo "INFO: Creating instance environment ${INSTANCE_PATH}" 
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Creating instance path ${INSTANCE_PATH}"
    mkdir -p "${INSTANCE_PATH}"
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Copying disk ${INSTANCE_PATH}"
    cp -a "${IMAGE}" "${DISK}"
    touch "${CD_ISO_PATH}"

pushd "${INSTANCE_PATH}" > /dev/null  
  
    # Generate user_data file configuration
    cat > "$USER_DATA" << _EOF_
#cloud-config
datasource_list: ['ConfigDrive']
disable_ec2_metadata: true 
# Hostname management
preserve_hostname: False
hostname: ${VM_NAME}
fqdn: ${VM_NAME}.${DOMAIN}
timezone: "${TIMEZONE}"

bootcmd:
   - echo "nameserver ${DNS}" > /etc/resolv.conf
   - echo "domain ${DOMAIN}" >> /etc/resolv.conf
   - echo "${EXTERNAL_BRIDGE_IP}   ${VM_NAME}    ${VM_NAME}.${DOMAIN}" >> /etc/hosts

users:
  - name: centos
    lock-passwd: false
    plain_text_passwd: '${PASSWORD}'
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
 
# Remove cloud-init when finished with it
runcmd:
   - [ yum, -y, remove, cloud-init ]
   - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
   - curl -sL https://gist.githubusercontent.com/alexellis/7315e75635623667c32199368aa11e95/raw/aabc1973111a668473323e91a32970758e75bbbd/kube.sh |sudo sh
  #  - sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.1/ctop-0.7.1-linux-amd64 -O /usr/local/bin/ctop
  #  - sudo chmod +x /usr/local/bin/ctop

package_update: true
package_upgrade: false
packages:
  - ntpdate
  - net-tools
  - openssh-clients
  - nc
  - vim
  - git
  - apt-transport-https
 
final_message: "The system is finally up"  

_EOF_
# Generate meta_data file configuration
    cat > "${META_DATA}" << _EOF_
instance-id: ${VM_NAME}
local-hostname: ${VM_NAME}
_EOF_
    
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Copying template image and resize..."
    echo "INFO: qemu-img resize ${DISK}  ${DISK_GB}GB"  
    qemu-img resize "${DISK}" "${DISK_GB}GB" > /dev/null
 
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Installing the domain and adjusting the configuration..."
    virt-install --name "${VM_NAME}" \
      --boot loader=/var/lib/libvirt/images/bios.bin-1.11.0 \
      --ram "${MEM}" \
      --vcpus "${CPUS}" \
      --import \
      --cpu host-passthrough \
      --disk "${DISK}",device=disk,bus=scsi,discard=unmap,boot_order=1 \
      --disk "${CD_ISO_PATH}",device=cdrom,device=cdrom,perms=ro,bus=sata,boot_order=2 \
      --network bridge="${EXTERNAL_BRIDGE}",model=virtio \
      --network bridge="${INTERNAL_BRIDGE}",model=virtio \
      --features hyperv_relaxed=on,hyperv_vapic=on,hyperv_spinlocks=on,hyperv_spinlocks_retries=8191,acpi=on \
      --clock hypervclock_present=yes \
      --controller type=scsi,model=virtio-scsi \
      --noautoconsole \
      --noapic \
      --accelerate \
      --graphics spice \
      --print-xml > "${VM_NAME}.xml"

    echo "$(date +"%d-%m-%Y %H:%M:%S") - Define domain ${VM_NAME}.xml."
    virsh define "${VM_NAME}.xml" >/dev/null
    MACS=$(virsh domiflist "${VM_NAME}"|grep -w -o -E "([0-9a-f]{2}:){5}([0-9a-f]{2})")
    MAC_COUNT=1
    for MAC in $MACS; do
      eval "MAC_$MAC_COUNT"="${MAC}"
      let  MAC_COUNT++
    done
    
        cat > "${NETWORK_DATA}" << _EOF_
---
version: 1
config:
  - type: physical
    name: eth0
    mac_address: ${MAC_1}
    subnets:
      - type: static
        address: ${EXTERNAL_BRIDGE_IP}
        netmask: ${EXTERNAL_BRIDGE_MASK}
        routes:
          - network: 0.0.0.0
            netmask: 0.0.0.0
            gateway: ${EXTERNAL_BRIDGE_IP%.*}.1
  - type: physical
    name: eth1
    mac_address: ${MAC_2}
    subnets:
      - type: static
        address: ${INTERNAL_BRIDGE_IP}
        netmask: ${INTERNAL_BRIDGE_MASK}      
  - type: nameserver
    address: [ ${DNS}  ]
    search: [${VM_NAME}.${DOMAIN}]            
_EOF_
    
    # Create CD-ROM ISO with cloud-init config
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Generating ISO for cloud-init..."
    genisoimage -output "${CD_ISO_PATH}" -volid cidata -joliet -rock "${CONFIG2}" &>/dev/null
      
popd > /dev/null

}

function _create_vm() {

    # Get vm name
    VM_NAME=${1:-"kube-master"}
    
    INSTANCE_PATH="${INSTANCES}/${VM_NAME}" 
    # Check if domain already exists
    virsh dominfo "${VM_NAME}" > /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        echo "[WARNING] ${VM_NAME} already exists.  "
        exit 0
    fi
 
    CD_ISO_PATH="${INSTANCE_PATH}/${VM_NAME}-cidata.iso"
    CONFIG2="${INSTANCE_PATH}/config-2"
    
    _generate_vm "${@}"

    echo "$(date +"%d-%m-%Y %H:%M:%S") - Start it ${VM_NAME}."
    virsh start "${VM_NAME}" >/dev/null
  
    FAILS=0   
    while true; do
        # Check if the machine is already accessible.
        ping -c 1 "${EXTERNAL_BRIDGE_IP}" >/dev/null 2>&1
        if [[ "$?" -ne 0 ]] ; then #if ping exits nonzero...
           FAILS=$((FAILS + 1))
           echo "INFO: Checking if server ${VM_NAME} with IP ${EXTERNAL_BRIDGE_IP} is online. (${FAILS} out of 20)" 
        fi

        # Check if the machine can already be accessed via SSH
        nc -z -v -w5 "${EXTERNAL_BRIDGE_IP}" 22 >/dev/null 2>&1
        if [[ "$?" -ne 0 ]] ; then #if wc exits nonzero...
           FAILS=$((FAILS + 1))
           echo "INFO: Checking if SSH server is online on ${VM_NAME}(${EXTERNAL_BRIDGE_IP})"
           
        else
           echo "INFO: server ${VM_NAME} is alive. let's remove cloud init files"
           break;
        fi

        # Fixed the problem with provisioning VM
        if [[ "${FAILS}" -gt 20 ]]; then
           echo "INFO: Server is still offline after 20min. I will end here!"
           exit 10;
        fi
        sleep 10;
    done
     
    # Detach cdrom    
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Detach cdrom ${CD_ISO_PATH}."  
    # At the next boot, the cdrom will be removed."
    virsh detach-disk "${VM_NAME}" "${CD_ISO_PATH}" --config
    if [ $? -eq 0 ] ; then
      echo "$(date +"%d-%m-%Y %H:%M:%S") - Removing metadata ISO ${CD_ISO_PATH}."
      rm -rf "${CD_ISO_PATH}"      
    fi
    # Remove the unnecessary cloud init files
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Cleaning up cloud-init..."
    rm -rfv "${CONFIG2}"
    echo "$(date +"%d-%m-%Y %H:%M:%S") - DONE."
 
}

OPERATION="${1}"
shift 1;
case ${OPERATION} in
	create-vm)
		_create_vm "${@}"
		;;
	delete-vm)
		_delete_vm "${1}";
		;;
	*)
		echo "Sorry, I don't understand"
		;;
  esac
 