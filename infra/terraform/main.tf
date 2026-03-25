# Terraform configuration
terraform {
  required_version = ">= 1.6"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

# Docker provider (local daemon)
provider "docker" {}

# Locals and data sources
locals {
  common_tags = {
    project     = var.app_name
    environment = var.environment
    managed_by  = "terraform"
  }

  container_name = "${var.app_name}-${var.environment}"
}

data "docker_network" "bridge" {
  name = "bridge"
}

# Network
resource "docker_network" "app_network" {
  name = "devops-network"
}

# Nginx image
resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

# Nginx container
resource "docker_container" "web"{
  name  = local.container_name
  image = docker_image.nginx.image_id
  
  

  ports {
    internal = 80
    external = var.web_port
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  env = [
    "NGINX_HOST=localhost",
    "NGINX_PORT=80"
  ]

  dynamic "labels" {
    for_each = local.common_tags
    content {
      label = labels.key
      value = labels.value
    }
  }
}

# Outputs
output "web_url" {
  value       = "http://localhost:${docker_container.web.ports[0].external}"
  description = "URL du serveur web"
}

output "container_id" {
  value       = docker_container.web.id
  description = "ID du conteneur déployé"
}
