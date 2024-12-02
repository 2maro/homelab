packer {
  required_plugins {
    proxmox = {
      version = "v1.2.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url" {
  type    = string
  default = "http://your-proxmox-url:8006/api2/json"
}
variable "username" {
  type    = string
  default = "root@pam"
}
variable "token" {
  type    = string
  default = "your_token"
}

variable "insecure_skip_tls_verify" {
  type    = bool
  default = true
}
variable "ssh_password" {
  type    = string
  default = "password"
}
variable "node" {
  type    = string
  default = "nameofyournode"
}
variable "disk_size" {
  type    = string
  default = "10G"
}
variable "localiso" {
  type    = string
  default = "local:iso/nameofyouriso"
}

source "proxmox-iso" "rocky9" {

  proxmox_url              = var.proxmox_url
  username                 = var.username
  token                    = var.token
  insecure_skip_tls_verify = var.insecure_skip_tls_verify
  node                     = var.node
  ssh_password             = var.ssh_password
  ssh_username             = "root"
  ssh_timeout              = "10m"
  vm_id                    = 1000
  vm_name                  = "rocky9-base"
  numa                     = true
  cores                    = 2
  memory                   = 2048
  os                       = "l26"
  qemu_agent               = true
  machine                  = "q35"
  cpu_type                 = "host"

  http_directory    = "http"
  http_port_min     = 8613
  http_port_max     = 8613
  http_bind_address = "0.0.0.0"
  boot_wait         = "10s"

  scsi_controller = "virtio-scsi-pci"
  boot_iso {
    type     = "scsi"
    iso_file = var.localiso
    unmount  = true
  }

  disks {
    type         = "virtio"
    disk_size    = var.disk_size
    storage_pool = "local-lvm"
    format       = "raw"
  }
  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = false
  }

  boot_command = [
    "<tab>",
    " inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky9-ks.cfg",
    " inst.stage2=cdrom",
    " inst.text",
    " ip=dhcp",
    " <enter>"
  ]

}

build {
  sources = ["source.proxmox-iso.rocky9"]

  provisioner "shell" {
    inline = [
      "dnf update -y",
      "dnf install -y qemu-guest-agent",
      "systemctl enable qemu-guest-agent",
      "systemctl start qemu-guest-agent"
    ]
  }
}
