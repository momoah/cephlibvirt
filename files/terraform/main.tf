terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      # Suddenly hit an issue using 0.7.1, so going without. See github post below to understand the original issue
      #version = "0.7.1" # https://github.com/dmacvicar/terraform-provider-libvirt/issues/1037#issuecomment-1793012834
    }
  }
}

provider "libvirt" {
  # Configuration options
  uri = "qemu:///system"
}
