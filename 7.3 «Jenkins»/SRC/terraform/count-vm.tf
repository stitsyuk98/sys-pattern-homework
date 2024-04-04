locals {
  ssh-keys = file("~/.ssh/id_ed25519.pub")
}

variable "os_image_jenkins" {
  type    = string
  default = "centos-7"
}

data "yandex_compute_image" "centos7" {
  family = var.os_image_jenkins
}
variable "yandex_compute_instance_jenkins" {
  type        = list(object({
    vm_name = string
    cores = number
    memory = number
    core_fraction = number
    count_vms = number
    platform_id = string
  }))

  default = [{
      vm_name = "centos7"
      cores         = 2
      memory        = 4
      core_fraction = 5
      count_vms = 2
      platform_id = "standard-v1"
    }]
}

variable "boot_disk_jenkins" {
  type        = list(object({
    size = number
    type = string
    }))
    default = [ {
    size = 20
    type = "network-hdd"
  }]
}


resource "yandex_compute_instance" "centos7" {
  name        = count.index == 0 ? "jenkins-master" : "jenkins-agent"
  platform_id = var.yandex_compute_instance_jenkins[0].platform_id

  count = var.yandex_compute_instance_jenkins[0].count_vms

  resources {
    cores         = var.yandex_compute_instance_jenkins[0].cores
    memory        = var.yandex_compute_instance_jenkins[0].memory
    core_fraction = var.yandex_compute_instance_jenkins[0].core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.centos7.image_id
      type     = var.boot_disk_jenkins[0].type
      size     = var.boot_disk_jenkins[0].size
    }
  }

  metadata = {
    ssh-keys = "centos:${local.ssh-keys}"
    serial-port-enable = "1"
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.develop.id
    nat       = true
  }
  scheduling_policy {
    preemptible = true
  }
}