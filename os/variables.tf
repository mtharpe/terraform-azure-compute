variable "vm_os_simple" {
  description = "Simple OS selector. Valid: UbuntuServer, WindowsServer, RHEL, openSUSE-Leap, Debian, SLES."
  type        = string
  default     = ""
}

# Standard OS catalog. Format: "publisher,offer,sku".
# Versions track current LTS / supported releases as of 2025+.
variable "standard_os" {
  description = "Curated map of OS keyword to Azure publisher/offer/sku."
  type        = map(string)
  default = {
    UbuntuServer    = "Canonical,0001-com-ubuntu-server-jammy,22_04-lts-gen2"
    WindowsServer   = "MicrosoftWindowsServer,WindowsServer,2022-datacenter-azure-edition"
    RHEL            = "RedHat,RHEL,9-lvm-gen2"
    "openSUSE-Leap" = "SUSE,opensuse-leap-15-5,gen2"
    Debian          = "Debian,debian-12,12-gen2"
    SLES            = "SUSE,sles-15-sp5,gen2"
  }
}
