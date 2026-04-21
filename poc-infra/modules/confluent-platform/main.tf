resource "confluent_environment" "this" {
  display_name = var.environment_display_name

  stream_governance {
    package = var.stream_governance_package
  }
}

resource "confluent_kafka_cluster" "this" {
  for_each = var.clusters

  display_name = "${var.name_prefix}-${each.key}-${each.value.display_name_suffix}"
  availability = each.value.availability
  cloud        = var.cloud
  region       = var.region

  # Enterprise clusters are inherently private and use PrivateLink Attachment (no network resource needed).
  enterprise {}

  environment {
    id = confluent_environment.this.id
  }
}

# One PrivateLink Attachment gateway per env/region — mirrors DKP's single platt-* per env.
resource "confluent_private_link_attachment" "this" {
  cloud        = var.cloud
  region       = var.region
  display_name = var.private_link_gateway_display_name

  environment {
    id = confluent_environment.this.id
  }
}
