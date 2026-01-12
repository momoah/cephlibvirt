# Defining VM Volume

resource "libvirt_volume" "os_image_base" {
  name   = "os_image_base.qcow2"
  pool   = var.mypool
  source = var.qcow_source
  format = "qcow2"
}
resource "libvirt_volume" "os_image" {
  count = "${length(local.vm_details_list)}"
  name = "${element(local.vm_details_list[count.index], 0)}_os_image.qcow2"
  pool = "${var.mypool}" 
  format = "qcow2"
  base_volume_id = libvirt_volume.os_image_base.id
  size = 50 * 1024 * 1024 * 1024
}

resource "libvirt_volume" "local_disk_01" {
  # This will likely be /dev/vdb
  # When size is "0", a file will still be created, but not attached.
  # TODO: Figure out a way to avoid creating an empty disk if the size is zero.

  name = "${element(local.vm_details_list[count.index], 0)}_local_disk_01.qcow2"
  pool = "${var.mypool}" # List storage pools using virsh pool-list
  format = "qcow2"
  size = element(local.vm_details_list[count.index], 5)*1073741824 # multiply by 1,073,741,824 (must be in bytes)
  count = "${length(local.vm_details_list)}"

}

resource "libvirt_volume" "local_disk_02" {
  # This will likely be /dev/vdc
  # When size is "0", a file will still be created, but not attached.
  # TODO: Figure out a way to avoid creating an empty disk if the size is zero.

  name = "${element(local.vm_details_list[count.index], 0)}_local_disk_02.qcow2"
  pool = "${var.mypool}" # List storage pools using virsh pool-list
  size = element(local.vm_details_list[count.index], 6)*1073741824 # multiply by 1,073,741,824 (must be in bytes)
  count = "${length(local.vm_details_list)}"

}

resource "libvirt_volume" "local_disk_03" {
  # This will likely be /dev/vdd
  # When size is "0", a file will still be created, but not attached.
  # TODO: Figure out a way to avoid creating an empty disk if the size is zero.

  name = "${element(local.vm_details_list[count.index], 0)}_local_disk_03.qcow2"
  pool = "${var.mypool}" # List storage pools using virsh pool-list
  size = element(local.vm_details_list[count.index], 7)*1073741824 # multiply by 1,073,741,824 (must be in bytes)
  count = "${length(local.vm_details_list)}"

}

resource "libvirt_volume" "local_disk_04" {
  # This will likely be /dev/vde
  # When size is "0", a file will still be created, but not attached.
  # TODO: Figure out a way to avoid creating an empty disk if the size is zero.

  name = "${element(local.vm_details_list[count.index], 0)}_local_disk_04.qcow2"
  pool = "${var.mypool}" # List storage pools using virsh pool-list
  size = element(local.vm_details_list[count.index], 8)*1073741824 # multiply by 1,073,741,824 (must be in bytes)
  count = "${length(local.vm_details_list)}"

}

resource "libvirt_volume" "local_disk_05" {
  # This will likely be /dev/vdf
  # When size is "0", a file will still be created, but not attached.
  # TODO: Figure out a way to avoid creating an empty disk if the size is zero.

  name = "${element(local.vm_details_list[count.index], 0)}_local_disk_05.qcow2"
  pool = "${var.mypool}" # List storage pools using virsh pool-list
  size = element(local.vm_details_list[count.index], 9)*1073741824 # multiply by 1,073,741,824 (must be in bytes)
  count = "${length(local.vm_details_list)}"

}


# get user data info
data "template_file" "user_data" {
  template = "${file("${path.module}/templates/cloud_init.cfg")}"
  count = "${length(local.vm_details_list)}"

  vars = {
    hostname = "${element(local.vm_details_list[count.index], 0)}"
    fqdn = "${element(local.vm_details_list[count.index], 0)}.${var.domain}"
    username = "${ var.myusername }"
    password = "${ var.mypassword }"
    sshkey = "${ var.mysshkey }"
  }
}

data "template_file" "network_config" {
  template = "${file("${path.module}/templates/network.cfg")}"
  count = "${length(local.vm_details_list)}"

  vars = {
    addresses = "${element(local.vm_details_list[count.index], 1)}"
    macaddr = "${element(local.vm_details_list[count.index], 2)}"
    dns = "${var.dns}"
  }
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  count = "${length(local.vm_details_list)}"
  name = "${element(local.vm_details_list[count.index], 0)}_commoninit.iso"
  pool = "${var.mypool}" # List storage pools using virsh pool-list
  user_data      = "${data.template_file.user_data[count.index].rendered}"
  network_config = "${data.template_file.network_config[count.index].rendered}"


}


# Define KVM domain to create
resource "libvirt_domain" "myvm" {
  name   = "${element(local.vm_details_list[count.index], 0)}"
  memory = element(local.vm_details_list[count.index], 4)*1024
  vcpu   = "${element(local.vm_details_list[count.index], 3)}"
  # Still having an issue with 0.74
  # https://github.com/dmacvicar/terraform-provider-libvirt/pull/1039
  qemu_agent = true
  count = "${length(local.vm_details_list)}"

  cpu { mode = "host-passthrough" } # Needed to specify this due to a bug in RHEL9, which causes a kernel panic -> https://bugzilla.redhat.com/show_bug.cgi?id=2094260

  network_interface {
    network_name = "${ var.bridged_network_name }" # I'm having trouble with this. # https://github.com/dmacvicar/terraform-provider-libvirt/pull/1039
    bridge = "${ var.bridge_name }"
    macvtap = "${ var.macvtap_name }"
    wait_for_lease = true
    mac = "${element(local.vm_details_list[count.index], 2)}"
  }

  boot_device {
    dev = [ "hd", "network"]
  }

  disk {
    volume_id = element(libvirt_volume.os_image.*.id, count.index)
  }

  # Data disk #01
  dynamic "disk" {
    # Check if disk1 is set to size 0
    for_each = element(local.vm_details_list[count.index], 5) == "0" ? [] : [1] 
    content {
      volume_id = libvirt_volume.local_disk_01[count.index].id
    }
  }

  # Data disk #02
  dynamic "disk" {
    # Check if disk2 is set to size 0
    for_each = element(local.vm_details_list[count.index], 6) == "0" ? [] : [1]
    content {
      volume_id = libvirt_volume.local_disk_02[count.index].id
    }
  }


  # Data disk #03
  dynamic "disk" {
    # Check if disk3 is set to size 0
    for_each = element(local.vm_details_list[count.index], 7) == "0" ? [] : [1]
    content {
      volume_id = libvirt_volume.local_disk_03[count.index].id
    }
  }

  # Data disk #04
  dynamic "disk" {
    # Check if disk4 is set to size 0
    for_each = element(local.vm_details_list[count.index], 8) == "0" ? [] : [1]
    content {
      volume_id = libvirt_volume.local_disk_04[count.index].id
    }
  }

  # Data disk #05
  dynamic "disk" {
    # Check if disk5 is set to size 0
    for_each = element(local.vm_details_list[count.index], 9) == "0" ? [] : [1]
    content {
      volume_id = libvirt_volume.local_disk_05[count.index].id
    }
  }


  cloudinit = "${libvirt_cloudinit_disk.commoninit[count.index].id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }


}

# Output Server IP
output "ips" {
  value = libvirt_domain.myvm.*.network_interface.0.addresses
}
