provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "ars-rg" {
  name     = var.ars_rg_name
  location = var.location
}

##################################################################
######################## VIRTUAL NETWORKS ########################
##################################################################

resource "azurerm_network_security_group" "ars-nsg" {
  name                = "ars-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.ars-rg.name
  
}

resource "azurerm_network_security_rule" "ssh-inbound" {
  name                        = "AllowAnySSHInbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.ars-rg.name
  network_security_group_name = azurerm_network_security_group.ars-nsg.name
}

resource "azurerm_network_security_rule" "vxlan-inbound" {
  name                        = "AllowAnyVXLANInbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "4789"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.ars-rg.name
  network_security_group_name = azurerm_network_security_group.ars-nsg.name
}

############################## HUB01 #############################

resource "azurerm_virtual_network" "hub01" {
  name                = "hub01"
  location            = var.location
  resource_group_name = azurerm_resource_group.ars-rg.name
  address_space       = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "hub01-default-subnet" {
    name                 = "default-subnet"
    resource_group_name  = azurerm_resource_group.ars-rg.name
    virtual_network_name = azurerm_virtual_network.hub01.name
    address_prefixes     = ["10.1.0.0/25"]
}

resource "azurerm_subnet" "hub01-ars-subnet" {
    name                 = "RouteServerSubnet"
    resource_group_name  = azurerm_resource_group.ars-rg.name
    virtual_network_name = azurerm_virtual_network.hub01.name
    address_prefixes     = ["10.1.0.128/26"]
}

resource "azurerm_subnet" "hub01-vxlan-subnet" {
    name                 = "vxlan-subnet"
    resource_group_name  = azurerm_resource_group.ars-rg.name
    virtual_network_name = azurerm_virtual_network.hub01.name
    address_prefixes     = ["10.1.0.192/26"]
}

resource "azurerm_subnet_network_security_group_association" "hub01-default-subnet-nsg" {
  subnet_id                 = azurerm_subnet.hub01-default-subnet.id
  network_security_group_id = azurerm_network_security_group.ars-nsg.id
}

resource "azurerm_subnet_network_security_group_association" "hub01-vxlan-subnet-nsg" {
  subnet_id                 = azurerm_subnet.hub01-vxlan-subnet.id
  network_security_group_id = azurerm_network_security_group.ars-nsg.id
}

############################## SPOKE01 #############################

resource "azurerm_virtual_network" "spoke01" {
  name                = "spoke01"
  location            = var.location
  resource_group_name = azurerm_resource_group.ars-rg.name
  address_space       = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "spoke01-default-subnet" {
    name                 = "default-subnet"
    resource_group_name  = azurerm_resource_group.ars-rg.name
    virtual_network_name = azurerm_virtual_network.spoke01.name
    address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "spoke01-default-subnet-nsg" {
  subnet_id                 = azurerm_subnet.spoke01-default-subnet.id
  network_security_group_id = azurerm_network_security_group.ars-nsg.id
}

############################## HUB02 #############################

resource "azurerm_virtual_network" "hub02" {
  name                = "hub02"
  location            = var.location
  resource_group_name = azurerm_resource_group.ars-rg.name
  address_space       = ["10.2.0.0/24"]
}

resource "azurerm_subnet" "hub02-default-subnet" {
    name                 = "default-subnet"
    resource_group_name  = azurerm_resource_group.ars-rg.name
    virtual_network_name = azurerm_virtual_network.hub02.name
    address_prefixes     = ["10.2.0.0/25"]
}

resource "azurerm_subnet" "hub02-ars-subnet" {
    name                 = "RouteServerSubnet"
    resource_group_name  = azurerm_resource_group.ars-rg.name
    virtual_network_name = azurerm_virtual_network.hub02.name
    address_prefixes     = ["10.2.0.128/26"]
}

resource "azurerm_subnet" "hub02-vxlan-subnet" {
    name                 = "vxlan-subnet"
    resource_group_name  = azurerm_resource_group.ars-rg.name
    virtual_network_name = azurerm_virtual_network.hub02.name
    address_prefixes     = ["10.2.0.192/26"]
}

resource "azurerm_subnet_network_security_group_association" "hub02-default-subnet-nsg" {
  subnet_id                 = azurerm_subnet.hub02-default-subnet.id
  network_security_group_id = azurerm_network_security_group.ars-nsg.id
}

resource "azurerm_subnet_network_security_group_association" "hub02-vxlan-subnet-nsg" {
  subnet_id                 = azurerm_subnet.hub02-vxlan-subnet.id
  network_security_group_id = azurerm_network_security_group.ars-nsg.id
}

############################## SPOKE02 #############################

resource "azurerm_virtual_network" "spoke02" {
  name                = "spoke02"
  location            = var.location
  resource_group_name = azurerm_resource_group.ars-rg.name
  address_space       = ["10.2.1.0/24"]
}

resource "azurerm_subnet" "spoke02-default-subnet" {
    name                 = "default-subnet"
    resource_group_name  = azurerm_resource_group.ars-rg.name
    virtual_network_name = azurerm_virtual_network.spoke02.name
    address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "spoke02-default-subnet-nsg" {
  subnet_id                 = azurerm_subnet.spoke02-default-subnet.id
  network_security_group_id = azurerm_network_security_group.ars-nsg.id
}

######################## VIRTUAL NETWORK PEERINGS ########################

resource "azurerm_virtual_network_peering" "hub01-hub02" {
  name                      = "hub01-to-hub02"
  resource_group_name       = azurerm_resource_group.ars-rg.name
  virtual_network_name      = azurerm_virtual_network.hub01.name
  remote_virtual_network_id = azurerm_virtual_network.hub02.id

  allow_forwarded_traffic = true
}

resource "azurerm_virtual_network_peering" "hub02-hub01" {
  name                      = "hub02-to-hub01"
  resource_group_name       = azurerm_resource_group.ars-rg.name
  virtual_network_name      = azurerm_virtual_network.hub02.name
  remote_virtual_network_id = azurerm_virtual_network.hub01.id

  allow_forwarded_traffic = true
}


resource "azurerm_virtual_network_peering" "hub01-spoke01" {
  name                      = "hub01-to-spoke01"
  resource_group_name       = azurerm_resource_group.ars-rg.name
  virtual_network_name      = azurerm_virtual_network.hub01.name
  remote_virtual_network_id = azurerm_virtual_network.spoke01.id

  allow_gateway_transit = true
}

resource "azurerm_virtual_network_peering" "spoke01-hub01" {
  name                      = "spoke01-to-hub01"
  resource_group_name       = azurerm_resource_group.ars-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke01.name
  remote_virtual_network_id = azurerm_virtual_network.hub01.id

  allow_forwarded_traffic = true
  use_remote_gateways = true
}

resource "azurerm_virtual_network_peering" "hub02-spoke02" {
  name                      = "hub02-to-spoke02"
  resource_group_name       = azurerm_resource_group.ars-rg.name
  virtual_network_name      = azurerm_virtual_network.hub02.name
  remote_virtual_network_id = azurerm_virtual_network.spoke02.id

  allow_gateway_transit = true
}

resource "azurerm_virtual_network_peering" "spoke02-hub02" {
  name                      = "spoke02-to-hub02"
  resource_group_name       = azurerm_resource_group.ars-rg.name
  virtual_network_name      = azurerm_virtual_network.spoke02.name
  remote_virtual_network_id = azurerm_virtual_network.hub02.id

  allow_forwarded_traffic = true
  use_remote_gateways = true
}

##################################################################
######################## VIRTUAL MACHINES ########################
##################################################################

############################ test01 ##############################

resource "azurerm_public_ip" "test01-pip" {
  name                = "test01-pip"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = var.location
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "test01-nic" {
  name                          = "test01-nic"
  resource_group_name           = azurerm_resource_group.ars-rg.name
  location                      = var.location
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "main-private-ip-config"
    subnet_id                     = azurerm_subnet.spoke01-default-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.11"
    public_ip_address_id          = azurerm_public_ip.test01-pip.id
  }
}

resource "azurerm_linux_virtual_machine" "test01" {
  name                = "test01"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = var.location
  size                = "Standard_D2s_v5"
  admin_username      = "kadmin"
  network_interface_ids = [
    azurerm_network_interface.test01-nic.id
  ]

  admin_ssh_key {
    username   = "kadmin"
    public_key = file("./keys/kadmin_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

############################ test02 ##############################

resource "azurerm_public_ip" "test02-pip" {
  name                = "test02-pip"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = var.location
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "test02-nic" {
  name                          = "test02-nic"
  resource_group_name           = azurerm_resource_group.ars-rg.name
  location                      = var.location
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "main-private-ip-config"
    subnet_id                     = azurerm_subnet.spoke02-default-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.1.11"
    public_ip_address_id          = azurerm_public_ip.test02-pip.id
  }
}

resource "azurerm_linux_virtual_machine" "test02" {
  name                = "test02"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = var.location
  size                = "Standard_D2s_v5"
  admin_username      = "kadmin"
  network_interface_ids = [
    azurerm_network_interface.test02-nic.id
  ]

  admin_ssh_key {
    username   = "kadmin"
    public_key = file("./keys/kadmin_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

########################### nva01 ##############################

resource "azurerm_public_ip" "nva01-pip" {
  name                = "nva01-pip"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = var.location
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "nva01-nic01" {
  name                          = "nva01-nic01"
  resource_group_name           = azurerm_resource_group.ars-rg.name
  location                      = var.location
  accelerated_networking_enabled = true
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "nva-ip-config"
    subnet_id                     = azurerm_subnet.hub01-default-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.0.4"
    public_ip_address_id          = azurerm_public_ip.nva01-pip.id
  }
}

resource "azurerm_network_interface" "nva01-nic02" {
  name                          = "nva01-nic02"
  resource_group_name           = azurerm_resource_group.ars-rg.name
  location                      = var.location
  accelerated_networking_enabled = true
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "vxlan-ip-config"
    subnet_id                     = azurerm_subnet.hub01-vxlan-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.0.200"
  }
}

resource "azurerm_linux_virtual_machine" "nva01" {
  name                = "nva01"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = var.location
  size                = "Standard_D2s_v5"
  admin_username      = "kadmin"
  network_interface_ids = [
    azurerm_network_interface.nva01-nic01.id,
    azurerm_network_interface.nva01-nic02.id
  ]

  admin_ssh_key {
    username   = "kadmin"
    public_key = file("./keys/kadmin_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

########################### nva02 ##############################

resource "azurerm_public_ip" "nva02-pip" {
  name                = "nva02-pip"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = var.location
  allocation_method   = "Static"

}

resource "azurerm_network_interface" "nva02-nic01" {
  name                          = "nva02-nic01"
  resource_group_name           = azurerm_resource_group.ars-rg.name
  location                      = var.location
  accelerated_networking_enabled = true
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "nva-ip-config"
    subnet_id                     = azurerm_subnet.hub02-default-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.0.4"
    public_ip_address_id          = azurerm_public_ip.nva02-pip.id
  }
}

resource "azurerm_network_interface" "nva02-nic02" {
  name                          = "nva02-nic02"
  resource_group_name           = azurerm_resource_group.ars-rg.name
  location                      = var.location
  accelerated_networking_enabled = true
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "vxlan-ip-config"
    subnet_id                     = azurerm_subnet.hub02-vxlan-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.0.200"
  }
}

resource "azurerm_linux_virtual_machine" "nva02" {
  name                = "nva02"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = var.location
  size                = "Standard_D2s_v5"
  admin_username      = "kadmin"
  network_interface_ids = [
    azurerm_network_interface.nva02-nic01.id,
    azurerm_network_interface.nva02-nic02.id
  ]

  admin_ssh_key {
    username   = "kadmin"
    public_key = file("./keys/kadmin_key.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

###################### Route Servers #######################

resource "azurerm_public_ip" "ars01_pip" {
  name                = "ars01-pip"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = azurerm_resource_group.ars-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "ars01" {
  name                             = "ars01"
  resource_group_name              = azurerm_resource_group.ars-rg.name
  location                         = azurerm_resource_group.ars-rg.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars01_pip.id
  subnet_id                        = azurerm_subnet.hub01-ars-subnet.id
  branch_to_branch_traffic_enabled = true
  hub_routing_preference           = "ASPath"
}

resource "azurerm_route_server_bgp_connection" "ars01-nva01-connection" {
  name            = "ars01-nva01-connection"
  route_server_id = azurerm_route_server.ars01.id
  peer_asn        = 65501
  peer_ip         = "10.1.0.4"
}

resource "azurerm_public_ip" "ars02_pip" {
  name                = "ars02-pip"
  resource_group_name = azurerm_resource_group.ars-rg.name
  location            = azurerm_resource_group.ars-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_route_server" "ars02" {
  name                             = "ars02"
  resource_group_name              = azurerm_resource_group.ars-rg.name
  location                         = azurerm_resource_group.ars-rg.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars02_pip.id
  subnet_id                        = azurerm_subnet.hub02-ars-subnet.id
  branch_to_branch_traffic_enabled = true
  hub_routing_preference           = "ASPath"
}

resource "azurerm_route_server_bgp_connection" "ars02-nva02-connection" {
  name            = "ars02-nva02-connection"
  route_server_id = azurerm_route_server.ars02.id
  peer_asn        = 65502
  peer_ip         = "10.2.0.4"
}