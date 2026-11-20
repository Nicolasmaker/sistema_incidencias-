#!/usr/bin/env bash
# ==============================================================================
# Despliegue Automatizado en Amazon ECS Fargate + Service Connect + CloudWatch
# Compatible con AWS Academy Learner Lab (LabRole, us-east-1)
# ==============================================================================
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-incidencias-ecs}"
NAMESPACE_NAME="${NAMESPACE_NAME:-incidencias.local}"
LOG_GROUP="/ecs/incidencias"
SG_NAME="incidencias-ecs-sg"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
BACKEND_IMAGE="${BACKEND_IMAGE:-${ECR_URI}/incidencias-backend:latest}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-${ECR_URI}/incidencias-frontend:latest}"

echo "==> Cuenta AWS: ${AWS_ACCOUNT_ID} | Region: ${AWS_REGION} | Cluster: ${CLUSTER_NAME}"

# 1. CloudWatch Log Group (/ecs/incidencias)
if ! aws logs describe-log-groups --region "$AWS_REGION" --log-group-name-prefix "$LOG_GROUP" --query "logGroups[?logGroupName=='${LOG_GROUP}'].logGroupName" --output text | grep -q "$LOG_GROUP"; then
  aws logs create-log-group --region "$AWS_REGION" --log-group-name "$LOG_GROUP"
  aws logs put-retention-policy --region "$AWS_REGION" --log-group-name "$LOG_GROUP" --retention-in-days 7
fi

# 2. Cluster ECS con Container Insights y Service Connect Namespace
CLUSTER_STATUS=$(aws ecs describe-clusters --region "$AWS_REGION" --clusters "$CLUSTER_NAME" --query "clusters[0].status" --output text 2>/dev/null || echo "NONE")
if [ "$CLUSTER_STATUS" != "ACTIVE" ]; then
  aws ecs create-cluster \
    --region "$AWS_REGION" \
    --cluster-name "$CLUSTER_NAME" \
    --settings name=containerInsights,value=enabled >/dev/null
  sleep 10
fi
aws ecs update-cluster \
  --region "$AWS_REGION" \
  --cluster "$CLUSTER_NAME" \
  --settings name=containerInsights,value=enabled \
  --service-connect-defaults namespace="$NAMESPACE_NAME" >/dev/null

# 3. VPC por defecto, 2 subredes y Security Group (8080 publico, 3306 solo interno)
VPC_ID=$(aws ec2 describe-vpcs --region "$AWS_REGION" --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text)
SUBNETS=$(aws ec2 describe-subnets --region "$AWS_REGION" --filters Name=vpc-id,Values="$VPC_ID" --query "Subnets[0:2].SubnetId" --output text | tr '\t' ',')

SG_ID=$(aws ec2 describe-security-groups --region "$AWS_REGION" --filters Name=group-name,Values="$SG_NAME" Name=vpc-id,Values="$VPC_ID" --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || echo "None")
if [ "$SG_ID" = "None" ] || [ -z "$SG_ID" ]; then
  SG_ID=$(aws ec2 create-security-group --region "$AWS_REGION" --group-name "$SG_NAME" --description "ECS Fargate Incidencias EP3" --vpc-id "$VPC_ID" --query "GroupId" --output text)
  aws ec2 authorize-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" --protocol tcp --port 8080 --cidr 0.0.0.0/0 >/dev/null
  aws ec2 authorize-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" --protocol tcp --port 3306 --source-group "$SG_ID" >/dev/null
fi

NET_CFG="awsvpcConfiguration={subnets=[${SUBNETS}],securityGroups=[${SG_ID}],assignPublicIp=ENABLED}"

# 4. Renderizar y registrar Task Definitions
render_and_register() {
  local tpl="$1"
  local tmp="/tmp/$(basename "$tpl")"
  sed \
    -e "s|__AWS_ACCOUNT_ID__|${AWS_ACCOUNT_ID}|g" \
    -e "s|__AWS_REGION__|${AWS_REGION}|g" \
    -e "s|__BACKEND_IMAGE__|${BACKEND_IMAGE}|g" \
    -e "s|__FRONTEND_IMAGE__|${FRONTEND_IMAGE}|g" \
    -e "s|__MYSQL_USER__|${MYSQL_USER}|g" \
    -e "s|__MYSQL_PASSWORD__|${MYSQL_PASSWORD}|g" \
    -e "s|__MYSQL_ROOT_PASSWORD__|${MYSQL_ROOT_PASSWORD}|g" \
    "$tpl" > "$tmp"
  aws ecs register-task-definition --region "$AWS_REGION" --cli-input-json "file://${tmp}" --query "taskDefinition.taskDefinitionArn" --output text
  rm -f "$tmp"
}

echo "==> Registrando Task Definitions en ECS..."
MYSQL_TD=$(render_and_register "ecs/taskdef-mysql.json")
BACKEND_TD=$(render_and_register "ecs/taskdef-backend.json")
FRONTEND_TD=$(render_and_register "ecs/taskdef-frontend.json")

# 5. Crear o actualizar servicios ECS Fargate con Service Connect
upsert_service() {
  local svc_name="$1"
  local td_arn="$2"
  local desired="$3"
  local sc_json="$4"

  local status
  status=$(aws ecs describe-services --region "$AWS_REGION" --cluster "$CLUSTER_NAME" --services "$svc_name" --query "services[0].status" --output text 2>/dev/null || echo "NONE")
  if [ "$status" = "ACTIVE" ]; then
    aws ecs update-service \
      --region "$AWS_REGION" \
      --cluster "$CLUSTER_NAME" \
      --service "$svc_name" \
      --task-definition "$td_arn" \
      --desired-count "$desired" \
      --force-new-deployment >/dev/null
  else
    aws ecs create-service \
      --region "$AWS_REGION" \
      --cluster "$CLUSTER_NAME" \
      --service-name "$svc_name" \
      --task-definition "$td_arn" \
      --desired-count "$desired" \
      --launch-type FARGATE \
      --network-configuration "$NET_CFG" \
      --service-connect-configuration "$sc_json" >/dev/null
  fi
}

echo "==> Desplegando servicios con Service Connect (${NAMESPACE_NAME})..."
upsert_service "mysql" "$MYSQL_TD" 1 \
  "{\"enabled\":true,\"namespace\":\"${NAMESPACE_NAME}\",\"services\":[{\"portName\":\"mysql\",\"discoveryName\":\"mysql\",\"clientAliases\":[{\"port\":3306,\"dnsName\":\"mysql\"}]}]}"

upsert_service "incidencias-backend" "$BACKEND_TD" 2 \
  "{\"enabled\":true,\"namespace\":\"${NAMESPACE_NAME}\",\"services\":[{\"portName\":\"http\",\"discoveryName\":\"incidencias-backend\",\"clientAliases\":[{\"port\":8080,\"dnsName\":\"incidencias-backend\"}]}]}"

upsert_service "incidencias-frontend" "$FRONTEND_TD" 1 \
  "{\"enabled\":true,\"namespace\":\"${NAMESPACE_NAME}\",\"services\":[{\"portName\":\"http\",\"discoveryName\":\"incidencias-frontend\",\"clientAliases\":[{\"port\":8080,\"dnsName\":\"incidencias-frontend\"}]}]}"

# 6. CloudWatch Dashboard + Alarma 5XX + Topico SNS
echo "==> Configurando CloudWatch Dashboard, Alarma 5XX y SNS..."
aws cloudwatch put-dashboard \
  --region "$AWS_REGION" \
  --dashboard-name "Dashboard-Incidencias-EP3" \
  --dashboard-body "file://ecs/cloudwatch-dashboard.json" >/dev/null

TOPIC_ARN=$(aws sns create-topic --region "$AWS_REGION" --name "incidencias-alertas" --query "TopicArn" --output text)

aws cloudwatch put-metric-alarm \
  --region "$AWS_REGION" \
  --alarm-name "Incidencias-5XX-Alarm" \
  --alarm-description "Alerta si el backend supera 5 errores HTTP 5XX en 1 minuto" \
  --namespace "AWS/ECS" \
  --metric-name "HTTPCode_Target_5XX_Count" \
  --dimensions Name=ClusterName,Value="$CLUSTER_NAME" Name=TargetDiscoveryName,Value=incidencias-backend \
  --statistic Sum \
  --period 60 \
  --evaluation-periods 1 \
  --threshold 5 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions "$TOPIC_ARN" >/dev/null

echo "==> Despliegue ECS + Service Connect + CloudWatch completado."
