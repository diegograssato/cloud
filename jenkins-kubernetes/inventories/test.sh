#!/bin/bash 

INVENTORIES_FILE="hosts"
HOSTS=$(ansible -i ${INVENTORIES_FILE} nodes --list-hosts -o |sed -n '1!p')

for HOST in ${HOSTS};do

echo -e "=============================================================================\n"
echo ${HOST}
IP=$(cat ${INVENTORIES_FILE}|grep "${HOST}" | grep -Po "ansible_host=[^\s]+"|cut -d "=" -f2)
USER=$(cat ${INVENTORIES_FILE}|grep "${HOST}" | grep -Po "ansible_user=[^\s]+"|cut -d "=" -f2)
PASS=$(cat ${INVENTORIES_FILE}|grep "${HOST}" | grep -Po "ansible_pass=[^\s]+"|cut -d "=" -f2)
PORT=$(cat ${INVENTORIES_FILE}|grep "${HOST}" | grep -Po "ansible_port=[^\s]+"|cut -d "=" -f2)
echo $IP
echo $USER
echo $PASS
echo $PORT

done