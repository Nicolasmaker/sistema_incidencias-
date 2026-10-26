# ==============================================================================
# Módulo 2: Infraestructura como Código - Configuración del Backend Remoto
# Estado remoto centralizado en AWS S3 con bloqueo de concurrencia en DynamoDB
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "sistema-incidencias-tfstate-788815135328"
    key            = "environments/sandbox/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sistema-incidencias-tf-locks"
    encrypt        = true
  }
}
