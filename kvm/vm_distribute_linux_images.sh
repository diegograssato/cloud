#!/usr/bin/env bash

# Name: VM - Distribute Linux Images
# Default user: root
# Timeout: 1200 s (20 mins)
# Remarks: Downloads ~600MB from Internet

set -euf -o pipefail

if [ ! -d "/var/lib/libvirt/images" ]; then
  echo "Libvirt Images folder (/var/lib/libvirt/images) not found, check installation."
  exit 1
fi


centos6image=CentOS-6-x86_64-GenericCloud.qcow2
if [ ! -f "/var/lib/libvirt/images/${centos6image}" ]; then
  echo "Centos 6 image needs to be distributed."

  echo "Removing any previous version of this image"
  rm -f "/var/lib/libvirt/images/CentOS-6-x86_64-GenericCloud-*"

  echo "Downloading image"
  wget https://cloud.centos.org/centos/6.6/images/${centos6image}.xz \
    -O /var/lib/libvirt/images/${centos6image}.xz

  echo "Decompressing"
  xz -d /var/lib/libvirt/images/${centos6image}.xz
else
  echo "Centos 6 image already deployed"
fi



centos7image=CentOS-7-x86_64-GenericCloud.qcow2
if [ ! -f "/var/lib/libvirt/images/${centos7image}" ]; then
  echo "Centos 7 image needs to be distributed."

  echo "Removing any previous version of this image"
  rm -f "/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud-*"

  echo "Downloading image"
  wget https://cloud.centos.org/centos/7/images/${centos7image}.xz \
    -O /var/lib/libvirt/images/${centos7image}.xz

  echo "Decompressing"
  xz -d /var/lib/libvirt/images/${centos7image}.xz
else
  echo "Centos 7 image already deployed"
fi

ubuntu16image=ubuntu-16.04-server-cloudimg-amd64-disk1.img
if [ ! -f "/var/lib/libvirt/images/${ubuntu16image}" ]; then
  echo "Ubuntu 16.04 image needs to be distributed."

  echo "Removing any previous version of this image"
  rm -f "/var/lib/libvirt/images/${ubuntu16image}"

  echo "Downloading latest Ubuntu 16.04 image"
  wget https://cloud-images.ubuntu.com/releases/16.04/release/${ubuntu16image} \
      -O /var/lib/libvirt/images/${ubuntu16image}
else
  echo "Ubuntu 16.04 image already deployed"
fi
 
