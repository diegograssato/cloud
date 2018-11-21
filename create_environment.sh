#!/usr/bin/env bash
 
# Directory to store images
IMAGES="/var/lib/libvirt/images"

source "$(pwd)/enviroment.bash"
# Location of cloud image

IMAGE="${IMAGES}/${ISO}" 

STORAGE="$PWD"
INSTANCES="${STORAGE}/instances"
DISK_MAX_LIMIT=200
DISK_MIN_LIMIT=4
VCPU_MAX_LIMIT="$(grep processor /proc/cpuinfo -c)"
MEM_MAX_LIMIT="$(awk '/MemTotal/ {printf( "%.2d\n", $2 / 1024 )}' /proc/meminfo)"
## NETWORK
# Bridge for VMs
EXTERNAL_BRIDGE="vswitch_lan"
EXTERNAL_BRIDGE_MASK="255.255.255.0"

INTERNAL_BRIDGE="vswitch_int"
INTERNAL_BRIDGE_MASK="255.255.255.0"

INTERNAL_BRIDGE_GW=$(ip -4 -o addr show dev ${INTERNAL_BRIDGE}| awk '{split($4,a,"/");print a[1]}')
# if(nc -w 1 201.55.232.74 -u 53);then
#     DNS="201.55.232.74"
# else
#     DNS="$(host -t A ns3.google.com. |egrep -o '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}')"
# fi
DNS="208.67.220.220"
function _get_inventories() {

    HOST_GROUP=${1:-master}
    
    HOSTS=$(ansible -i ${INVENTORIES_FILE} ${HOST_GROUP} --list-hosts -o |sed -n '1!p')
    echo ${HOSTS}
} 

# Check if domain already exists
function _delete_vm() {

    VM_NAME=${1}
    INSTANCE_PATH="${INSTANCES}/${VM_NAME}"
   
    echo -e "\n= ==== LOADING CONFIGURATION FROM '${VM_NAME}'' HOST ======================================== =\n"
    virsh dominfo "${VM_NAME}" > /dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        echo "$(date +"%d-%m-%Y %H:%M:%S") - Destroying the ${VM_NAME} domain (if it exists)..."
    
        # Remove domain with the same name
        virsh destroy "${VM_NAME}"
        echo "$(date +"%d-%m-%Y %H:%M:%S") - Undefine the ${VM_NAME} domain configuration..."
        virsh undefine "${VM_NAME}"
        if [[ -d "${INSTANCE_PATH}" ]]; then
            echo "$(date +"%d-%m-%Y %H:%M:%S") - Remove the ${VM_NAME} domain files..."
            rm -rfv "${INSTANCE_PATH}"
        fi 
    fi
   
}

function _delete_node() {
    clear
    _NODE=${1}
    echo -e "\n= ======================  - CLEAN NODE '${_NODE}' - ======================================== =\n"
    for VM_NAME in $(_get_inventories ${_NODE:?});do

        _delete_vm "${VM_NAME}"

    done
}        

function _generate_vm() { 
  
    echo -e "\n----- MACHINE SPEC FROM '${VM_NAME}' HOST --------------------------------------------------\n"
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

    # Set disk path
    DISK="${INSTANCE_PATH}/${VM_NAME}.qcow2"

    # Get timezone
    TIMEZONE=$(cat /etc/timezone)
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Get timezone: ${TIMEZONE}" 
    
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Creating instance path ${INSTANCE_PATH}"
    mkdir -p "${INSTANCE_PATH}"
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Copying disk ${INSTANCE_PATH}"
    cp -a "${IMAGE}" "${DISK}"
    touch "${CD_ISO_PATH}"

pushd "${INSTANCE_PATH}" > /dev/null  
    
    # Generate user_data file configuration 
    _create_user_data
    # Generate meta_data file configuration 
    _create_metadata
    
    echo -n "$(date +"%d-%m-%Y %H:%M:%S") - Copying template image and resize..."
    echo "INFO: qemu-img resize ${DISK}  ${DISK_GB}GB"  
    qemu-img resize "${DISK}" "${DISK_GB}GB" > /dev/null
 
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Installing the domain and adjusting the configuration..."
    if [[ -n ${EXTERNAL_BRIDGE_IP} ]]; then
   
        virt-install --name "${VM_NAME}" \
            --boot loader=/var/lib/libvirt/images/bios.bin-1.11.0 \
            --ram "${MEM}" \
            --vcpus "${CPUS}" \
            --import \
            --cpu host-passthrough \
            --disk "${DISK}",device=disk,bus=scsi,discard=unmap,boot_order=1 \
            --disk "${CD_ISO_PATH}",device=cdrom,device=cdrom,perms=ro,bus=sata,boot_order=2 \
            --network bridge="${INTERNAL_BRIDGE}",model=virtio,virtualport_type=openvswitch \
            --network bridge="${EXTERNAL_BRIDGE}",model=virtio,virtualport_type=openvswitch \
            --clock hypervclock_present=yes \
            --controller type=scsi,model=virtio-scsi \
            --noautoconsole \
            --noapic \
            --accelerate \
            --graphics spice \
            --print-xml > "${VM_NAME}.xml"
    else

        virt-install --name "${VM_NAME}" \
            --boot loader=/var/lib/libvirt/images/bios.bin-1.11.0 \
            --ram "${MEM}" \
            --vcpus "${CPUS}" \
            --import \
            --cpu host-passthrough \
            --disk "${DISK}",device=disk,bus=scsi,discard=unmap,boot_order=1 \
            --disk "${CD_ISO_PATH}",device=cdrom,device=cdrom,perms=ro,bus=sata,boot_order=2 \
            --network bridge="${INTERNAL_BRIDGE}",model=virtio,virtualport_type=openvswitch \
            --clock hypervclock_present=yes \
            --controller type=scsi,model=virtio-scsi \
            --noautoconsole \
            --noapic \
            --accelerate \
            --graphics spice \
            --print-xml > "${VM_NAME}.xml"
#--features hyperv_relaxed=on,hyperv_vapic=on,hyperv_spinlocks=on,hyperv_spinlocks_retries=8191,acpi=on \
                        
    fi

    echo "$(date +"%d-%m-%Y %H:%M:%S") - Define domain ${VM_NAME}.xml."
    virsh define "${VM_NAME}.xml" >/dev/null
    MACS=$(virsh domiflist "${VM_NAME}"|grep -w -o -E "([0-9a-f]{2}:){5}([0-9a-f]{2})")
    MAC_COUNT=1
    for MAC in $MACS; do
      eval "MAC_$MAC_COUNT"="${MAC}"
     
      let  MAC_COUNT++
    done
    
    # Generate network_data file configuration 
    _create_network_data
    
    # Create CD-ROM ISO with cloud-init config
    echo "$(date +"%d-%m-%Y %H:%M:%S") - Generating ISO for cloud-init..."
    genisoimage -output "${CD_ISO_PATH}" -volid cidata -joliet -rock "${CONFIG2}" &>/dev/null
      
popd > /dev/null
 
}

function _validate_parameters() {
        
        local VM_NAME=${1} 
        local _ERROR=0
       
        _GET_EXTERNAL_BRIDGE_IP=$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Po "ansible_external_host=[^\s]+"|cut -d "=" -f2)
        _GET_INTERNAL_BRIDGE_IP=$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Pwo "ansible_host=[^\s]+"|cut -d "=" -f2)
        _GET_USER=$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Po "ansible_user=[^\s]+"|cut -d "=" -f2)
        _GET_PASS=$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Po "ansible_pass=[^\s]+"|cut -d "=" -f2)
        _GET_PORT="$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Po "ansible_port=[^\s]+"|cut -d "=" -f2)"
        
        _GET_MEM="$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Pwo "ansible_mem=[^\s]+"|cut -d "=" -f2)"

        _GET_CPUS="$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Po "ansible_cpu=[^\s]+"|cut -d "=" -f2)"
        _GET_DISK_GB="$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Po "ansible_disk=[^\s]+"|cut -d "=" -f2)"
        _GET_ADMIN_KEY="$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Po "ansible_ssh_private_key_file=[^\s]+"|cut -d "=" -f2)"
        _GET_SSH_PASS="$(grep -w "${VM_NAME}" "${INVENTORIES_FILE}"| grep -Po "ansible_ssh_pass=[^\s]+"|cut -d "=" -f2)"
 
        
        # Check External IP exists
        _CHECK_EXTERNAL_BRIDGE_IP=$(grep -v "${VM_NAME}" "${INVENTORIES_FILE}"| grep -w -o "ansible_external_host=${_GET_EXTERNAL_BRIDGE_IP}")

        # Check Internal IP exists
        _CHECK_INTERNAL_BRIDGE_IP=$(grep -v "${VM_NAME}" "${INVENTORIES_FILE}"| grep -w -o "ansible_host=${_GET_INTERNAL_BRIDGE_IP}")
          
        
        [[ -n "${_CHECK_EXTERNAL_BRIDGE_IP}" ]] && echo -e "$(date +"%d-%m-%Y %H:%M:%S") - External IP '${_GET_EXTERNAL_BRIDGE_IP}' allready in uso.\n" && _ERROR=1
        [[ -n "${_CHECK_INTERNAL_BRIDGE_IP}" ]] && echo -e "$(date +"%d-%m-%Y %H:%M:%S") - Internal IP '${_GET_INTERNAL_BRIDGE_IP}' allready in uso.\n" && _ERROR=1

        # Memory validation
        if [[ -n "${_GET_MEM}" ]]; then
            [[ "${MEM_MAX_LIMIT}" -le  "${_GET_MEM}"  ]] && \
                        echo -e "$(date +"%d-%m-%Y %H:%M:%S") - The memory from '${VM_NAME}' must be less than ${MEM_MAX_LIMIT}.\n" && _ERROR=1
            [[ "${_GET_MEM}" -lt 1000 ]] && echo -e "$(date +"%d-%m-%Y %H:%M:%S") - The memory from '${VM_NAME}' must be greater than 1000MB.\n" && _ERROR=1
            MEM="${_GET_MEM}"
        else
            MEM="1024"
        fi

        # VCPU validation
        if [[ -n "${_GET_CPUS}" ]]; then
            [[ "${_GET_CPUS}" -gt "${VCPU_MAX_LIMIT}"  ]] && \
                        echo -e "$(date +"%d-%m-%Y %H:%M:%S") - The vcpu from '${VM_NAME}' must be less than ${VCPU_MAX_LIMIT}.\n" && _ERROR=1

            [[ 0 -ge "${_GET_CPUS}" ]] && echo -e "$(date +"%d-%m-%Y %H:%M:%S") - The vcpu from '${VM_NAME}' must be greater than 0.\n" && _ERROR=1

            CPUS="${_GET_CPUS}"

        else
            CPUS="2"
        fi

        # Disk validation
        if [[ -n "${_GET_DISK_GB}" ]]; then

            [[ "${DISK_MIN_LIMIT}" -ge  "${_GET_DISK_GB}"  ]] && \
                        echo -e "$(date +"%d-%m-%Y %H:%M:%S") - The disk from '${VM_NAME}' must be less than ${DISK_MIN_LIMIT}.\n" && _ERROR=1

            [[ "${DISK_MAX_LIMIT}" -lt "${_GET_DISK_GB}" ]] && echo -e "$(date +"%d-%m-%Y %H:%M:%S") - The disk from '${VM_NAME}' must be greater than ${DISK_MAX_LIMIT}.\n" && _ERROR=1
            DISK_GB="${_GET_DISK_GB:-10}"
            
        else
            DISK_GB="10"
        fi

        # Disk validation
        if [[ -n "${_GET_PORT}" ]]; then

            [[ 0 -ge "${_GET_PORT}" ]] && echo -e "$(date +"%d-%m-%Y %H:%M:%S") - The ssh port from '${VM_NAME}' must be greater than 0.\n" && _ERROR=1

            PORT="${_GET_PORT:-22}"
            
        else
            PORT="22"
        fi
        
        ADMIN_KEY="${_GET_ADMIN_KEY:-$(cat $HOME/.ssh/id_rsa.pub)}"       
        EXTERNAL_BRIDGE_IP="${_GET_EXTERNAL_BRIDGE_IP}"
        INTERNAL_BRIDGE_IP="${_GET_INTERNAL_BRIDGE_IP:?}"

        if [[ -n "${_GET_PASS}" ]] &&  [[ -z "${_GET_SSH_PASS}" ]]; then
            PASSWORD="${_GET_PASS}"
        elif [[ -n "${_GET_SSH_PASS}" ]]; then
            PASSWORD="${_GET_SSH_PASS}"
        else
            PASSWORD="passw0rd"
        fi

        # VM spec   
        INSTANCE_PATH="${INSTANCES}/${VM_NAME}" 
        ADMIN_USER="${_GET_USER:-root}"
        
        echo "ADMIN USER: ${ADMIN_USER}"
        echo "ADMIN PASSWORD: ${PASSWORD}"
        echo "SSH PORT: ${PORT}"
        echo "EXTERNAL IP ${EXTERNAL_BRIDGE}: ${EXTERNAL_BRIDGE_IP}"
        echo "INTERNAL IP ${INTERNAL_BRIDGE}: ${INTERNAL_BRIDGE_IP}"
        
 
        echo "INSTANCE LOCALTION: ${INSTANCE_PATH}"
        echo "MEMORY: ${MEM}MB"
        echo "CPUS: ${CPUS} VCPUs"
        echo -e "DISK 1: ${DISK_GB}GB\n"
        [[ "${_ERROR}" -ne 0 ]] && exit 1;
     
}

function _create_vm() {
    clear
    local _NODE="${1:-}"
    
    echo -e "\n===== LOADING '${_NODE:?}' NODE =========================================\n"
    for VM_NAME in $(_get_inventories ${_NODE:?});do

        echo -e "\n===== VALIDATING CONFIGURATION FROM '${VM_NAME}' HOST =========================================\n"
        
        _validate_parameters "${VM_NAME}" 
         
        # Check if domain already exists
        virsh dominfo "${VM_NAME}" > /dev/null 2>&1
        if [ "$?" -eq 0 ]; then
        
            echo -n -e "\n[WARNING] ${VM_NAME} already exists.  "
            read -p "Do you want to overwrite ${VM_NAME} [y/N]? " -r
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                
                echo "$(date +"%d-%m-%Y %H:%M:%S") - Destroying the ${VM_NAME} domain (if it exists)..."
 
                # Remove domain with the same name
                virsh destroy "${VM_NAME}"
                virsh undefine "${VM_NAME}"

            else
                echo -e "\n$(date +"%d-%m-%Y %H:%M:%S") - Not overwriting ${VM_NAME}. Connect via ssh using '${ADMIN_USER}@${INTERNAL_BRIDGE_IP}' and password '${PASSWORD}'.\n"
                continue;
            fi
        fi

        if [[ -d "${INSTANCE_PATH}" ]]; then
            rm -rfv "${INSTANCE_PATH}"
        fi

        CD_ISO_PATH="${INSTANCE_PATH}/${VM_NAME}-cidata.iso"
        CONFIG2="${INSTANCE_PATH}/config-2"
        
        #Generate vm METADA information
        _generate_vm "${@}"

        echo "$(date +"%d-%m-%Y %H:%M:%S") - Start it ${VM_NAME}."
        virsh start "${VM_NAME}" >/dev/null
    
        FAILS=0   
        while true; do
            echo -e "\n"
            # Check if the machine is already accessible.
            ping -c 1 "${INTERNAL_BRIDGE_IP}" >/dev/null 2>&1
            if [[ "$?" -ne 0 ]] ; then #if ping exits nonzero...
            FAILS=$((FAILS + 1))
            echo "INFO: Checking if server ${VM_NAME} with IP ${INTERNAL_BRIDGE_IP} is online. (${FAILS} out of 20)" 
            fi

            # Check if the machine can already be accessed via SSH
            nc -z -v -w5 "${INTERNAL_BRIDGE_IP}" 22 >/dev/null 2>&1
            if [[ "$?" -ne 0 ]] ; then #if wc exits nonzero...
            FAILS=$((FAILS + 1))
            echo "INFO: Checking if SSH server is online on ${VM_NAME}(${INTERNAL_BRIDGE_IP})"
            
            else
            echo -e "\n===== SERVER ${VM_NAME} IS ALIVE. LET's REMOVE CLOUD-INIT FILES =========================================\n"
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
        ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${INTERNAL_BRIDGE_IP}"  >/dev/null 2>&1
        ssh-keygen -f "${HOME}/.ssh/known_hosts" -R "${INTERNAL_BRIDGE_IP}"  >/dev/null 2>&1
        echo -e "\n$(date +"%d-%m-%Y %H:%M:%S") - Done connect via ssh using ${ADMIN_USER}@${INTERNAL_BRIDGE_IP} and password ${PASSWORD}.\n" 
    done
 
}

OPERATION="${1}"
shift 1;
case "${OPERATION}" in
	create-vm|create-node|create|new|n)
        _create_vm "${1}"
	;;

	delete-vm|delete|destroy|d)
		_delete_vm "${1}"
	;;

	delete-node|delete-node|destroy-node|dd|dn)
		_delete_node "${1}"
	;;

	*)
        echo "Sorry, I don't understand!"
    ;;
  esac
 