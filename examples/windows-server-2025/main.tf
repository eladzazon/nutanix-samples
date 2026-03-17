#Here we will create a vm clone
#the variable "" present in terraform.tfvars file.
#Note - Replace appropriate values of variables in terraform.tfvars file as per setup

terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      
    }
  }
}

#defining nutanix configuration
provider "nutanix" {
  username = var.nutanix_username
  password = var.nutanix_password
  endpoint = var.nutanix_endpoint
  port     = var.nutanix_port
  insecure = true
}

data "nutanix_clusters_v2" "clusters" {}

locals {
  cluster_ext_id = [
    for cluster in data.nutanix_clusters_v2.clusters.cluster_entities :
    cluster.ext_id if cluster.config[0].cluster_function[0] != "PRISM_CENTRAL"
  ][0]
}


# pull storage container data
data "nutanix_storage_containers_v2" "sc" {
  limit  = 1
}

# pull subnet data
data "nutanix_subnets_v2" "vm-subnet" {
  filter = "name eq '${var.subnet_name}'"
}

# pull image data
data "nutanix_images_v2" "vm-image" {
  filter = "name eq '${var.image_name}'"
  limit  = 1
}

#pull all categories data
data "nutanix_categories_v2" "categories-list" {}



# list all virtual machines
data "nutanix_virtual_machines_v2" "vms" {}

resource "nutanix_virtual_machine_v2" "windows_server_2025" {
  name                 = var.vm_name
  description          = "Test Windows Server 2025 orchestrated by Terraform"
  num_cores_per_socket = 2
  num_sockets          = 2
  memory_size_bytes    = 8589934592 # 8 GB

  cluster {
    ext_id = local.cluster_ext_id
  }

  # OS Disk from Image
  disks {
    disk_address {
      bus_type = "SCSI"
      index    = 0
    }
    backing_info {
      vm_disk {
        data_source {
          reference {
            image_reference {
              image_ext_id = data.nutanix_images_v2.vm-image.images[0].ext_id
            }
          }
        }
      }
    }
  }


  nics {
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = data.nutanix_subnets_v2.vm-subnet.subnets[0].ext_id
      }
      vlan_mode = "ACCESS"
    }
  }

  boot_config {
    uefi_boot {
      boot_device {
        boot_device_disk {
          disk_address {
            bus_type = "SCSI"
            index    = 0
          }
        }
      }
    }
  }

  power_state = "ON"
}

output "vm_ip_address" {
  description = "IP address of the created VM"
  value       = try(nutanix_virtual_machine_v2.windows_server_2025.nics[0].network_info[0].ipv4_info[0].learned_ip_addresses[0].value, null)
}
