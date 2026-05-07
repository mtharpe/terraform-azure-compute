variable "resource_group_name" {
  description = "Name of the resource group in which the resources will be created"
  type        = string
}

variable "vnet_subnet_id" {
  description = "Subnet ID where the VM NICs will reside"
  type        = string
}

variable "public_ip_dns" {
  description = "Optional globally unique per-datacenter-region domain name label for the public IP. Only one label is supported regardless of nb_public_ip."
  type        = string
  default     = null
}

variable "admin_password" {
  description = "Admin password for the VM. Required for Windows or when enable_ssh_key is false."
  type        = string
  default     = null
  sensitive   = true
}

variable "ssh_key" {
  description = "Path to the public SSH key for Linux VMs. Ignored for Windows."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "remote_port" {
  description = "Remote TCP port allowed inbound by the NSG. Defaults to 22 (Linux) or 3389 (Windows) based on the OS selection."
  type        = string
  default     = null
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "custom_data" {
  description = "Custom data to supply to the VM (cloud-init for Linux). Will be base64-encoded by the module."
  type        = string
  default     = null
}

variable "storage_account_type" {
  description = "Type of storage account for the OS disk. Valid: Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS."
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS", "StandardSSD_ZRS", "Premium_ZRS"], var.storage_account_type)
    error_message = "storage_account_type must be one of Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS, Premium_ZRS."
  }
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "nb_instances" {
  description = "Number of VM instances"
  type        = number
  default     = 1

  validation {
    condition     = var.nb_instances >= 1
    error_message = "nb_instances must be >= 1."
  }
}

variable "vm_hostname" {
  description = "Local hostname/prefix for the VM. Windows VM names are truncated to 15 characters."
  type        = string
  default     = "myvm"
}

variable "vm_os_simple" {
  description = "Specify UbuntuServer, WindowsServer, RHEL, openSUSE-Leap, Debian, or SLES to use a curated default image. Leave empty when supplying vm_os_publisher/offer/sku or vm_os_id."
  type        = string
  default     = ""
}

variable "vm_os_id" {
  description = "Resource ID of a custom image. When set, overrides vm_os_simple/publisher/offer/sku. Pair with is_windows_image = true for Windows custom images."
  type        = string
  default     = ""
}

variable "is_windows_image" {
  description = "True when the custom image (vm_os_id) is Windows-based."
  type        = bool
  default     = false
}

variable "vm_os_publisher" {
  description = "Image publisher. Ignored when vm_os_id or vm_os_simple is set."
  type        = string
  default     = null
}

variable "vm_os_offer" {
  description = "Image offer. Ignored when vm_os_id or vm_os_simple is set."
  type        = string
  default     = null
}

variable "vm_os_sku" {
  description = "Image SKU. Ignored when vm_os_id or vm_os_simple is set."
  type        = string
  default     = null
}

variable "vm_os_version" {
  description = "Image version. Defaults to latest."
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    source = "terraform"
  }
}

variable "allocation_method" {
  description = "Public IP allocation method. Valid: Static, Dynamic. Standard SKU IPs require Static."
  type        = string
  default     = "Static"

  validation {
    condition     = contains(["Static", "Dynamic"], var.allocation_method)
    error_message = "allocation_method must be Static or Dynamic."
  }
}

variable "nb_public_ip" {
  description = "Number of public IPs to allocate (one per VM). Set to 0 to disable."
  type        = number
  default     = 1
}

variable "data_sa_type" {
  description = "Storage account type for data disks"
  type        = string
  default     = "Standard_LRS"
}

variable "data_disk_size_gb" {
  description = "Data disk size in GB"
  type        = number
  default     = 30
}

variable "boot_diagnostics" {
  description = "Enable boot diagnostics (creates a storage account)"
  type        = bool
  default     = false
}

variable "boot_diagnostics_sa_type" {
  description = "Storage account type for boot diagnostics. Format: <Tier>_<Replication>"
  type        = string
  default     = "Standard_LRS"
}

variable "enable_ssh_key" {
  description = "Use SSH key authentication for Linux VMs (disables password auth)"
  type        = bool
  default     = true
}

variable "nb_data_disk" {
  description = "Number of data disks attached to each VM"
  type        = number
  default     = 0
}

variable "use_availability_set" {
  description = "Place VMs in an availability set. Mutually exclusive with zone."
  type        = bool
  default     = true
}

variable "zone" {
  description = "Availability zone for the VMs (e.g. \"1\"). When set, no availability set is created."
  type        = string
  default     = null
}
