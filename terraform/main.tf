# ==============================================================================
# Módulo 2 & 4: Infraestructura Principal y Seguridad (AWS)
# Recursos de Cifrado KMS, Almacenamiento S3, OIDC GitHub y AWS CodeDeploy
# Con soporte automático para cuentas de estudiante (AWS Academy / Learner Lab)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Seguridad de Datos: Cifrado en Reposo de Artefactos (Módulo 4)
# ------------------------------------------------------------------------------
resource "aws_kms_key" "artifacts_key" {
  count                   = var.is_aws_academy ? 0 : 1
  description             = "Clave KMS para cifrado de artefactos CI/CD y buckets S3"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-kms-key"
  }
}

resource "aws_kms_alias" "artifacts_key_alias" {
  count         = var.is_aws_academy ? 0 : 1
  name          = "alias/${var.project_name}-artifacts-key"
  target_key_id = aws_kms_key.artifacts_key[0].key_id
}

locals {
  kms_key_arn = var.is_aws_academy ? "arn:aws:kms:us-east-1:788815135328:alias/aws/s3" : (length(aws_kms_key.artifacts_key) > 0 ? aws_kms_key.artifacts_key[0].arn : null)
}

# ------------------------------------------------------------------------------
# 2. Bucket S3 para Despliegue de Frontend Estático (Módulo 3)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.frontend_bucket_name}-${var.environment}"
  force_destroy = false

  tags = {
    Name     = "${var.project_name}-frontend"
    Servicio = "Frontend"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_encryption" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_access" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 3. Bucket S3 para Artefactos CI/CD y CodePipeline con Cifrado KMS (Módulo 4)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.artifacts_bucket_name}-${var.environment}"
  force_destroy = false

  tags = {
    Name     = "${var.project_name}-artifacts"
    Servicio = "CI/CD Pipeline"
  }
}

resource "aws_s3_bucket_versioning" "artifacts_versioning" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts_encryption" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts_access" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 4. Gestión de Roles IAM: LabRole para AWS Academy vs OIDC para Producción (Módulo 4)
# ------------------------------------------------------------------------------
data "aws_iam_role" "lab_role" {
  count = var.is_aws_academy ? 1 : 0
  name  = "LabRole"
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.is_aws_academy ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  count = var.is_aws_academy ? 0 : 1

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  count              = var.is_aws_academy ? 0 : 1
  name               = "${var.project_name}-github-actions-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role[0].json

  tags = {
    Name = "${var.project_name}-github-oidc-role"
  }
}

resource "aws_iam_policy" "github_actions_policy" {
  count       = var.is_aws_academy ? 0 : 1
  name        = "${var.project_name}-github-actions-policy-${var.environment}"
  description = "Permisos mínimos necesarios para GitHub Actions (S3 Frontend y despliegues)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*",
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [local.kms_key_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  count      = var.is_aws_academy ? 0 : 1
  role       = aws_iam_role.github_actions_role[0].name
  policy_arn = aws_iam_policy.github_actions_policy[0].arn
}

# ------------------------------------------------------------------------------
# 5. AWS CodeDeploy para Despliegue de Backend (Módulo 3)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "codedeploy_service_role" {
  count = var.is_aws_academy ? 0 : 1
  name  = "${var.project_name}-codedeploy-service-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_attachment" {
  count      = var.is_aws_academy ? 0 : 1
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_service_role[0].name
}

resource "aws_codedeploy_app" "backend_app" {
  compute_platform = "Server"
  name             = "${var.project_name}-backend-${var.environment}"
}

resource "aws_codedeploy_deployment_group" "backend_deployment_group" {
  app_name              = aws_codedeploy_app.backend_app.name
  deployment_group_name = "${var.project_name}-backend-dg-${var.environment}"
  service_role_arn      = var.is_aws_academy ? data.aws_iam_role.lab_role[0].arn : aws_iam_role.codedeploy_service_role[0].arn

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
