terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.112.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.1.254:8006/"

  # Lab environment - Proxmox uses a self-signed certificate
  insecure = true
}

# Download Ubuntu 24.04 cloud image directly to Proxmox
resource "proxmox_virtual_environment_download_file" "ubuntu_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "hdc"

  url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"

  file_name = "noble-server-cloudimg-amd64.qcow2"
}

# Provision Ubuntu VM
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {

  name        = "terraform-ubuntu01"
  description = "Ubuntu VM provisioned using Terraform"

  node_name = "hdc"

  tags = [
    "terraform",
    "ubuntu",
    "iac"
  ]

  started         = true
  stop_on_destroy = true

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = "local-lvm"

    import_from = proxmox_virtual_environment_download_file.ubuntu_image.id

    interface = "scsi0"

    iothread = true
    discard  = "on"

    size = 32
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {

    datastore_id = "local-lvm"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "labadmin"
      password = var.vm_password
      keys = [
        trimspace(file("/home/labadmin/.ssh/ansible_k3s_lab.pub"))
      ]
    }
  }

  operating_system {
    type = "l26"
  }
}
