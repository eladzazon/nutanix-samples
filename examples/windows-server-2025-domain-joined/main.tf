# Domain-Joined Windows Server 2025 VM
# Extends the base windows-server-2025 example with sysprep guest customization
# to automatically join the VM to an Active Directory domain on first boot.
# Note - Replace appropriate values of variables in terraform.tfvars file as per setup

terraform {
  required_providers {
    nutanix = {
      source = "nutanix/nutanix"
    }
  }
}

# defining nutanix configuration
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

  # Escape special characters to ensure XML is valid even with special passwords
  esc_vm_name     = replace(replace(replace(replace(replace(var.vm_name, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), "\"", "&quot;"), "'", "&apos;")
  esc_domain_name = replace(replace(replace(replace(replace(var.domain_name, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), "\"", "&quot;"), "'", "&apos;")
  esc_domain_user = replace(replace(replace(replace(replace(var.domain_user, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), "\"", "&quot;"), "'", "&apos;")
  esc_domain_pass = replace(replace(replace(replace(replace(var.domain_password, "&", "&amp;"), "<", "&lt;"), ">", "&gt;"), "\"", "&quot;"), "'", "&apos;")

  # Inline unattend.xml — re-ordered and streamlined for better compatibility
  unattend_xml = <<XML
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="*" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <ComputerName>${local.esc_vm_name}</ComputerName>
        </component>
        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="*" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Identification>
                <Credentials>
                    <Domain>${local.esc_domain_name}</Domain>
                    <Password>${local.esc_domain_pass}</Password>
                    <Username>${local.esc_domain_user}</Username>
                </Credentials>
                <JoinDomain>${local.esc_domain_name}</JoinDomain>
            </Identification>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="*" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalUserAccountScreen>true</HideLocalUserAccountScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>${local.esc_domain_pass}</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
            </UserAccounts>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="*" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
</unattend>
XML
}

# pull storage container data
data "nutanix_storage_containers_v2" "sc" {
  limit = 1
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

resource "nutanix_virtual_machine_v2" "windows_server_2025_domain" {
  name                 = var.vm_name
  description          = "Windows Server 2025 domain-joined VM orchestrated by Terraform"
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

  # Sysprep guest customization — runs once on first boot to join the domain
  guest_customization {
    config {
      sysprep {
        install_type = "PREPARED"
        sysprep_script {
          unattend_xml {
            value = base64encode(local.unattend_xml)
          }
        }
      }
    }
  }

  # Prevent re-running sysprep on subsequent applies
  lifecycle {
    ignore_changes = [guest_customization]
  }

  power_state = "ON"
}

output "vm_ip_address" {
  description = "IP address of the created VM (available after boot)"
  value       = try(nutanix_virtual_machine_v2.windows_server_2025_domain.nics[0].network_info[0].ipv4_info[0].learned_ip_addresses[0].value, null)
}
