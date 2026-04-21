resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "this" {
  for_each = var.vnets

  name                = "${var.name_prefix}-${each.key}-vnet"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = each.value.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "private_endpoints" {
  for_each = var.vnets

  name                 = "${var.name_prefix}-${each.key}-pe-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this[each.key].name
  address_prefixes     = [each.value.private_endpoint_cidr]

  # Required for Private Endpoints per Azure docs.
  private_endpoint_network_policies = "Disabled"
}
