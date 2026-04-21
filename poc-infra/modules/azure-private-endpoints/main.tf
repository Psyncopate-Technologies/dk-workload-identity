resource "azurerm_private_endpoint" "this" {
  for_each = var.tiers

  name                = "${var.name_prefix}-${each.key}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = each.value.subnet_id
  tags                = var.tags

  # Alias-based connections require manual approval; the Confluent access-point
  # connection resource (below) approves it on the Confluent side.
  private_service_connection {
    name                              = "${var.name_prefix}-${each.key}-psc"
    is_manual_connection              = true
    private_connection_resource_alias = var.private_link_service_alias
    request_message                   = "DK workload-identity PoC — auto-approved by Confluent access-point connection"
  }
}

# One zone shared across tiers; Confluent publishes all bootstraps under the same DNS domain.
resource "azurerm_private_dns_zone" "this" {
  name                = var.private_link_dns_domain
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = var.tiers

  name                  = "${var.name_prefix}-${each.key}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = each.value.vnet_id
  tags                  = var.tags
}

# Confluent-side access point — registers the Azure PE with the PL attachment.
resource "confluent_private_link_attachment_connection" "this" {
  for_each = var.tiers

  display_name = each.value.access_point_display_name

  environment {
    id = var.confluent_environment_id
  }

  azure {
    private_endpoint_resource_id = azurerm_private_endpoint.this[each.key].id
  }

  private_link_attachment {
    id = var.private_link_attachment_id
  }
}
