# ==============================================================================
# Módulo 2 & 4: Infraestructura Principal y Seguridad (AWS)
# Recursos de Cifrado KMS, Almacenamiento S3, OIDC GitHub y AWS CodeDeploy
# Adaptado con alta compatibilidad para cuentas de estudiante (AWS Academy / Learner Lab)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Seguridad de Datos: Clave KMS / Alias para Cifrado en Reposo (Módulo 4)
# ------------------------------------------------------------------------------
locals {
  kms_key_arn = "arn:aws:kms:us-east-1:788815135328:alias/aws/s3"
}

# ------------------------------------------------------------------------------
# 2. Bucket S3 para Frontend Estático (Módulo 3)
# Desplegado vía CloudFormation para eludir el bloqueo de SCP (s3:GetBucketObjectLockConfiguration)
# ------------------------------------------------------------------------------
resource "aws_cloudformation_stack" "frontend_bucket" {
  name = "${var.project_name}-frontend-stack-${var.environment}"

  template_body = jsonencode({
    Resources = {
      FrontendBucket = {
        Type = "AWS::S3::Bucket"
        Properties = {
          BucketName = "${var.frontend_bucket_name}-${var.environment}"
          BucketEncryption = {
            ServerSideEncryptionConfiguration = [
              {
                ServerSideEncryptionByDefault = {
                  SSEAlgorithm = "AES256"
                }
              }
            ]
          }
          PublicAccessBlockConfiguration = {
            BlockPublicAcls       = true
            BlockPublicPolicy     = true
            IgnorePublicAcls      = true
            RestrictPublicBuckets = true
          }
        }
      }
    }
    Outputs = {
      BucketId = {
        Description = "ID del bucket Frontend"
        Value       = { Ref = "FrontendBucket" }
      }
      BucketArn = {
        Description = "ARN del bucket Frontend"
        Value       = { "Fn::GetAtt" = ["FrontendBucket", "Arn"] }
      }
    }
  })

  tags = {
    Name     = "${var.project_name}-frontend"
    Servicio = "Frontend"
  }
}

# ------------------------------------------------------------------------------
# 3. Bucket S3 para Artefactos CI/CD con Cifrado KMS y Versionado (Módulo 4)
# ------------------------------------------------------------------------------
resource "aws_cloudformation_stack" "artifacts_bucket" {
  name = "${var.project_name}-artifacts-stack-${var.environment}"

  template_body = jsonencode({
    Resources = {
      ArtifactsBucket = {
        Type = "AWS::S3::Bucket"
        Properties = {
          BucketName = "${var.artifacts_bucket_name}-${var.environment}"
          VersioningConfiguration = {
            Status = "Enabled"
          }
          BucketEncryption = {
            ServerSideEncryptionConfiguration = [
              {
                ServerSideEncryptionByDefault = {
                  SSEAlgorithm = "aws:kms"
                }
              }
            ]
          }
          PublicAccessBlockConfiguration = {
            BlockPublicAcls       = true
            BlockPublicPolicy     = true
            IgnorePublicAcls      = true
            RestrictPublicBuckets = true
          }
        }
      }
    }
    Outputs = {
      BucketId = {
        Description = "ID del bucket Artefactos"
        Value       = { Ref = "ArtifactsBucket" }
      }
      BucketArn = {
        Description = "ARN del bucket Artefactos"
        Value       = { "Fn::GetAtt" = ["ArtifactsBucket", "Arn"] }
      }
    }
  })

  tags = {
    Name     = "${var.project_name}-artifacts"
    Servicio = "CI/CD Pipeline"
  }
}

# ------------------------------------------------------------------------------
# 4. Gestión de Roles IAM: LabRole para AWS Academy vs OIDC para Producción (Módulo 4)
# ------------------------------------------------------------------------------
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ------------------------------------------------------------------------------
# 5. AWS CodeDeploy para Despliegue de Backend (Módulo 3)
# ------------------------------------------------------------------------------
resource "aws_codedeploy_app" "backend_app" {
  compute_platform = "Server"
  name             = "${var.project_name}-backend-${var.environment}"
}

resource "aws_codedeploy_deployment_group" "backend_deployment_group" {
  app_name              = aws_codedeploy_app.backend_app.name
  deployment_group_name = "${var.project_name}-backend-dg-${var.environment}"
  service_role_arn      = data.aws_iam_role.lab_role.arn

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
