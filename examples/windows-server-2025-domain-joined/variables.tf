
# variable definitions
variable "nutanix_username" {
  type = string
}
variable "nutanix_password" {
  type      = string
  sensitive = true
}
variable "nutanix_endpoint" {
  type = string
}
variable "nutanix_port" {
  type = string
}
variable "subnet_name" {
  type = string
}
variable "image_name" {
  type = string
}

# VM identity
variable "vm_name" {
  type        = string
  description = "VM name in Nutanix and computer name in Windows"
}

# Domain join variables
variable "domain_name" {
  type        = string
  description = "FQDN of the Active Directory domain to join (e.g. corp.example.com)"
}
variable "domain_user" {
  type        = string
  description = "Username with permission to join computers to the domain"
}
variable "domain_password" {
  type        = string
  sensitive   = true
  description = "Password for the domain join account"
}
