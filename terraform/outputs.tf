# ==============================================================================
# Módulo 2: Infraestructura como Código - Salidas (Outputs)
# Atributos exportados para su consumo en pipelines de CI/CD
# ==============================================================================

output "frontend_bucket_id" {
  description = "Nombre del bucket S3 para alojamiento del frontend"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "ARN del bucket S3 para alojamiento del frontend"
  value       = aws_s3_bucket.frontend.arn
}

output "artifacts_bucket_id" {
  description = "Nombre del bucket S3 para artefactos de CodePipeline"
  value       = aws_s3_bucket.artifacts.id
}

output "github_actions_role_arn" {
  description = "ARN del Rol IAM para despliegues (LabRole en Academy u OIDC en Prod)"
  value       = var.is_aws_academy ? data.aws_iam_role.lab_role[0].arn : aws_iam_role.github_actions_role[0].arn
}

output "kms_key_arn" {
  description = "ARN de la clave KMS para cifrado de artefactos"
  value       = local.kms_key_arn
}

output "codedeploy_app_name" {
  description = "Nombre de la aplicación de CodeDeploy para el Backend"
  value       = aws_codedeploy_app.backend_app.name
}

output "codedeploy_deployment_group_name" {
  description = "Nombre del grupo de despliegue de CodeDeploy"
  value       = aws_codedeploy_deployment_group.backend_deployment_group.deployment_group_name
}
