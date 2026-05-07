module "os" {
  source       = "./os"
  vm_os_simple = var.vm_os_simple
}

data "azurerm_resource_group" "vm" {
  name = var.resource_group_name
}

locals {
  is_windows = var.is_windows_image || contains([var.vm_os_simple, var.vm_os_offer], "Windows") || contains([var.vm_os_simple], "WindowsServer")

  use_avset = var.use_availability_set && var.zone == null

  remote_port = coalesce(var.remote_port, module.os.calculated_remote_port)
}

#############
# Boot diag #
#############

resource "random_id" "vm_sa" {
  count       = var.boot_diagnostics ? 1 : 0
  keepers     = { vm_hostname = var.vm_hostname }
  byte_length = 6
}

resource "azurerm_storage_account" "vm" {
  count                    = var.boot_diagnostics ? 1 : 0
  name                     = "bootdiag${lower(random_id.vm_sa[0].hex)}"
  resource_group_name      = data.azurerm_resource_group.vm.name
  location                 = data.azurerm_resource_group.vm.location
  account_tier             = element(split("_", var.boot_diagnostics_sa_type), 0)
  account_replication_type = element(split("_", var.boot_diagnostics_sa_type), 1)
  tags                     = var.tags
}

#####################
# Availability set  #
#####################

resource "azurerm_availability_set" "vm" {
  count                        = local.use_avset ? 1 : 0
  name                         = "${var.vm_hostname}-avset"
  resource_group_name          = data.azurerm_resource_group.vm.name
  location                     = data.azurerm_resource_group.vm.location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = var.tags
}

###############
# Networking  #
###############

resource "azurerm_public_ip" "vm" {
  count               = var.nb_public_ip
  name                = "${var.vm_hostname}-pip-${count.index}"
  resource_group_name = data.azurerm_resource_group.vm.name
  location            = data.azurerm_resource_group.vm.location
  allocation_method   = var.allocation_method
  domain_name_label   = var.public_ip_dns
  tags                = var.tags
}

resource "azurerm_network_security_group" "vm" {
  name                = "${var.vm_hostname}-nsg"
  resource_group_name = data.azurerm_resource_group.vm.name
  location            = data.azurerm_resource_group.vm.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "vm" {
  name                        = "allow_remote_${local.remote_port}_in_all"
  resource_group_name         = data.azurerm_resource_group.vm.name
  description                 = "Allow remote protocol in from all locations"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = local.remote_port
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vm.name
}

resource "azurerm_network_interface" "vm" {
  count               = var.nb_instances
  name                = "${var.vm_hostname}-nic-${count.index}"
  resource_group_name = data.azurerm_resource_group.vm.name
  location            = data.azurerm_resource_group.vm.location

  ip_configuration {
    name                          = "${var.vm_hostname}-ip-${count.index}"
    subnet_id                     = var.vnet_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.nb_public_ip > 0 ? element(concat(azurerm_public_ip.vm[*].id, [null]), count.index) : null
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "vm" {
  count                     = var.nb_instances
  network_interface_id      = azurerm_network_interface.vm[count.index].id
  network_security_group_id = azurerm_network_security_group.vm.id
}

#######################
# Linux virtual machine #
#######################

resource "azurerm_linux_virtual_machine" "vm" {
  count               = local.is_windows ? 0 : var.nb_instances
  name                = "${var.vm_hostname}-vmLinux-${count.index}"
  resource_group_name = data.azurerm_resource_group.vm.name
  location            = data.azurerm_resource_group.vm.location
  size                = var.vm_size

  admin_username                  = var.admin_username
  admin_password                  = var.enable_ssh_key ? null : var.admin_password
  disable_password_authentication = var.enable_ssh_key

  network_interface_ids = [azurerm_network_interface.vm[count.index].id]
  availability_set_id   = local.use_avset ? azurerm_availability_set.vm[0].id : null
  zone                  = var.zone

  custom_data = var.custom_data == null ? null : base64encode(var.custom_data)

  dynamic "admin_ssh_key" {
    for_each = var.enable_ssh_key ? [1] : []
    content {
      username   = var.admin_username
      public_key = file(var.ssh_key)
    }
  }

  os_disk {
    name                 = "osdisk-${var.vm_hostname}-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_id = var.vm_os_id == "" ? null : var.vm_os_id

  dynamic "source_image_reference" {
    for_each = var.vm_os_id == "" ? [1] : []
    content {
      publisher = coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher)
      offer     = coalesce(var.vm_os_offer, module.os.calculated_value_os_offer)
      sku       = coalesce(var.vm_os_sku, module.os.calculated_value_os_sku)
      version   = var.vm_os_version
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics ? [1] : []
    content {
      storage_account_uri = azurerm_storage_account.vm[0].primary_blob_endpoint
    }
  }

  tags = var.tags
}

#########################
# Windows virtual machine #
#########################

resource "azurerm_windows_virtual_machine" "vm" {
  count               = local.is_windows ? var.nb_instances : 0
  name                = substr("${var.vm_hostname}-w${count.index}", 0, 15) # Windows hostname max 15 chars
  resource_group_name = data.azurerm_resource_group.vm.name
  location            = data.azurerm_resource_group.vm.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.vm[count.index].id]
  availability_set_id   = local.use_avset ? azurerm_availability_set.vm[0].id : null
  zone                  = var.zone

  os_disk {
    name                 = "${var.vm_hostname}-osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_id = var.vm_os_id == "" ? null : var.vm_os_id

  dynamic "source_image_reference" {
    for_each = var.vm_os_id == "" ? [1] : []
    content {
      publisher = coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher)
      offer     = coalesce(var.vm_os_offer, module.os.calculated_value_os_offer)
      sku       = coalesce(var.vm_os_sku, module.os.calculated_value_os_sku)
      version   = var.vm_os_version
    }
  }

  dynamic "boot_diagnostics" {
    for_each = var.boot_diagnostics ? [1] : []
    content {
      storage_account_uri = azurerm_storage_account.vm[0].primary_blob_endpoint
    }
  }

  tags = var.tags
}

#############
# Data disks #
#############

locals {
  vm_ids = local.is_windows ? azurerm_windows_virtual_machine.vm[*].id : azurerm_linux_virtual_machine.vm[*].id

  data_disks = flatten([
    for i in range(var.nb_instances) : [
      for j in range(var.nb_data_disk) : {
        key      = "${i}-${j}"
        vm_index = i
        lun      = j
      }
    ]
  ])
}

resource "azurerm_managed_disk" "vm" {
  for_each = { for d in local.data_disks : d.key => d }

  name                 = "${var.vm_hostname}-datadisk-${each.value.vm_index}-${each.value.lun}"
  location             = data.azurerm_resource_group.vm.location
  resource_group_name  = data.azurerm_resource_group.vm.name
  storage_account_type = var.data_sa_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm" {
  for_each = { for d in local.data_disks : d.key => d }

  managed_disk_id    = azurerm_managed_disk.vm[each.key].id
  virtual_machine_id = local.vm_ids[each.value.vm_index]
  lun                = each.value.lun
  caching            = "None"
}
