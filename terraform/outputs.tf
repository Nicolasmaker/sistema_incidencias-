# ==============================================================================
# Módulo 2: Infraestructura como Código - Salidas (Outputs)
# Atributos exportados para su consumo en pipelines de CI/CD
# ==============================================================================

output "frontend_bucket_id" {
  description = "Nombre del bucket S3 para alojamiento del frontend"
  value       = aws_cloudformation_stack.frontend_bucket.outputs["BucketId"]
}

output "frontend_bucket_arn" {
  description = "ARN del bucket S3 para alojamiento del frontend"
  value       = aws_cloudformation_stack.frontend_bucket.outputs["BucketArn"]
}

output "frontend_website_url" {
  description = "URL pública de acceso al sitio web estático alojado en Amazon S3"
  value       = "http://${aws_cloudformation_stack.frontend_bucket.outputs["BucketId"]}.s3-website-us-east-1.amazonaws.com"
}

output "artifacts_bucket_id" {
  description = "Nombre del bucket S3 para artefactos de CodePipeline"
  value       = aws_cloudformation_stack.artifacts_bucket.outputs["BucketId"]
}

output "github_actions_role_arn" {
  description = "ARN del Rol IAM para despliegues (LabRole en Academy)"
  value       = data.aws_iam_role.lab_role.arn
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
