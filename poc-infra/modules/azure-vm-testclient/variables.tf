variable "name_prefix" {
  description = "Resource name prefix."
  type        = string
  default     = "dk-confluent-poc"
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the VM."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the VM NIC lands (compute subnet — NOT the PE subnet)."
  type        = string
}

variable "admin_username" {
  description = "SSH admin username on the VM."
  type        = string
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  description = "SSH public key material (e.g. contents of ~/.ssh/id_rsa.pub)."
  type        = string
}

variable "vm_size" {
  description = "Azure VM SKU."
  type        = string
  default     = "Standard_B2s"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
