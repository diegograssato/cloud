# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

# We fetch the latest ubuntu release image from their mirrors
resource "libvirt_volume" "master-qcow2" {
  name   = "master.qcow2"
  pool   = "default"                                                              #CHANGE_ME
  source = "/var/lib/libvirt/images/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
  format = "qcow2"
}

# volume to attach to the "master" domain as main disk
# blank 10GB image for net install.
# resource "libvirt_volume" "master" {
#   name           = "master.qcow2"
#   base_volume_id = "${libvirt_volume.ubuntu.id}"
# }

# Create a network for our VMs
# resource "libvirt_network" "external" {
#   name   = "external"
#   mode   = "bridge"
#   bridge = "external"
# }

# Use CloudInit to add our ssh-key to the instance
resource "libvirt_cloudinit" "commoninit" {
  name               = "commoninit.iso"                                                                                                                                                                                                                                                                                                                                                                                                      #CHANGEME
  ssh_authorized_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDRF6A2AKlwBmFB7Po59d6tJ30/Z63Ra7RHZL/IWmk7ZNgXPkTJI3oDCEzbwXeiBkVIpA248mH9rbOM0fz4vIBCx5j1BbLhFKTMFjReOrJhrIqQJHXe47IHCiaeYgYsSOyrw7kYXHU/emGkxXJOlIzHhn7H2i3UH7SoktIp88BSrcbLVuQYsDYuiNX+TyRyNFYlpkIBcZfITHJZI6xWPNAutkq8xr2Iv7CvmeHyass1mmJgRfZlEwoMf70Qt7mwSlD+NxKYo9E0Msk6QNCze/tHhGwcAFA6JL1lP/iG7RH5dGYLXA1v06+nq5rFd0y1gvYdhKfO0BV7ViL+kuYkKRf/ dgrassato@OptiPlex-980" #CHANGE_ME
  pool               = "default"

  user_data = <<EOF
chpasswd:
  list: |
    centos:centos
network-interfaces: |
  iface eth0 inet static
  address 192.168.2.26
  netmask 255.255.255.0
  gateway 192.168.2.1
EOF
}

# Create the machine
resource "libvirt_domain" "domain-ubuntu" {
  name   = "ubuntu-terraform"
  memory = "3024"
  vcpu   = 8

  #firmware = "/var/lib/libvirt/images/bios.bin-1.11.0"
  emulator = "/usr/bin/kvm-spice"
  arch     = "x86_64"

  boot_device {
    dev = ["hd", "network"]
  }

  cpu {
    mode = "host-passthrough"
  }

  cloudinit = "${libvirt_cloudinit.commoninit.id}"

  network_interface {
    bridge         = "external"
    hostname       = "master"
    addresses      = ["192.168.2.26"]
    wait_for_lease = true
  }

  # IMPORTANT
  # Ubuntu can hang is a isa-serial is not present at boot time.
  # If you find your CPU 100% and never is available this is why
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = "${libvirt_volume.master-qcow2.id}"

    # scsi      = 1
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = "true"
  }
}

# Print the Boxes IP
# # Note: you can use `virsh domifaddr <vm_name> <interface>` to get the ip later
# output "ip" {
#   value = "${libvirt_domain.domain-ubuntu.network_interface.0.addresses.0}"
# }

