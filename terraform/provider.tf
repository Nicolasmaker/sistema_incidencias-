# ==============================================================================
# Módulo 2: Infraestructura como Código - Proveedor AWS
# Configuración del provider AWS y etiquetas globales de auditoría
# ==============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Proyecto    = var.project_name
      Ambiente    = var.environment
      Gestionado  = "Terraform"
      Repositorio = "sistema_incidencias"
    }
  }
}
