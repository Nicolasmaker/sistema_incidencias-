# ==============================================================================
# Módulo 2: Infraestructura como Código - Variables de Configuración
# Parametrización para despliegues reproducibles y seguros
# ==============================================================================

variable "aws_region" {
  description = "Región de AWS para el despliegue de los recursos"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Entorno de despliegue (sandbox, testing, staging, prod)"
  type        = string
  default     = "sandbox"
}

variable "project_name" {
  description = "Nombre base del proyecto para nombrado de recursos"
  type        = string
  default     = "sistema-incidencias"
}

variable "github_repo" {
  description = "Identificador del repositorio GitHub en formato 'usuario/repo' para federación OIDC"
  type        = string
  default     = "Nicolasmaker/sistema_incidencias-"
}

variable "frontend_bucket_name" {
  description = "Nombre único del bucket S3 para alojar el frontend estático"
  type        = string
  default     = "sistema-incidencias-frontend-cahuinlab"
}

variable "artifacts_bucket_name" {
  description = "Nombre del bucket S3 para artefactos cifrados de CodePipeline/CodeDeploy"
  type        = string
  default     = "sistema-incidencias-artifacts-cahuinlab"
}
