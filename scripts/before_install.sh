#!/bin/bash
# ==============================================================================
# Hook: BeforeInstall (AWS CodeDeploy)
# Limpieza previa y detención de instancias anteriores
# ==============================================================================
set -e

echo "[CodeDeploy:BeforeInstall] Preparando entorno de despliegue..."

# Detener el servicio previo si existe
if systemctl is-active --quiet sistema-incidencias; then
    echo "[CodeDeploy:BeforeInstall] Deteniendo servicio previo sistema-incidencias..."
    systemctl stop sistema-incidencias || true
fi

# Crear directorio de aplicación si no existe
mkdir -p /opt/sistema-incidencias
mkdir -p /var/log/sistema-incidencias

echo "[CodeDeploy:BeforeInstall] Entorno preparado correctamente."
