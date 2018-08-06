#!/usr/bin/env bash

#ISO="${IMAGES}/CentOS-6-x86_64-GenericCloud.qcow2"
ISO="CentOS-7-x86_64-GenericCloud.qcow2"

#ISO=ubuntu-16.04-server-cloudimg-amd64-disk1.img
INVENTORIES_FILE="$(pwd)/inventories/hosts"
 
DOMAIN="dtux.lan"
UUID="$(uuidgen)"

function _create_metadata() {
    cat > ${META_DATA} << _EOF_
instance-id: ${UUID}-${VM_NAME}
local-hostname: ${VM_NAME}
_EOF_

}

function _create_user_data() {

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
      - ${ADMIN_KEY}
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
  - name: ${ADMIN_USER}
    ssh_pwauth: True
    lock-passwd: false
    plain_text_passwd: '${PASSWORD}'
    ssh-authorized-keys: 
      - ${ADMIN_KEY}
 
# Remove cloud-init when finished with it
runcmd:
   - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin yes/' /etc/ssh/sshd_config
   
final_message: "The system is finally up"  

_EOF_


}

function _create_network_data() {

if [[ -n ${INTERNAL_BRIDGE_IP} ]]; then

        echo "$(date +"%d-%m-%Y %H:%M:%S") - Get network information from ${EXTERNAL_BRIDGE} => ${EXTERNAL_BRIDGE_IP}"
        echo "$(date +"%d-%m-%Y %H:%M:%S") - Get network information from ${INTERNAL_BRIDGE} => ${INTERNAL_BRIDGE_IP}"
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
    else
        echo "$(date +"%d-%m-%Y %H:%M:%S") - Get network information from ${EXTERNAL_BRIDGE} => ${EXTERNAL_BRIDGE_IP}"
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
  - type: nameserver
    address: [ ${DNS}  ]
    search: [${VM_NAME}.${DOMAIN}]            
_EOF_

    fi

}