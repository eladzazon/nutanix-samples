
#variable definitions
variable "nutanix_username" {
  type = string
}
variable "nutanix_password" {
  type = string
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

variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Password for the local Administrator account"
}
