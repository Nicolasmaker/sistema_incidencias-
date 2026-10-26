#!/bin/bash
# ==============================================================================
# Hook: ApplicationStart (AWS CodeDeploy)
# Inicio del microservicio Spring Boot / Contenedor
# ==============================================================================
set -e

echo "[CodeDeploy:ApplicationStart] Iniciando aplicación..."

cd /opt/sistema-incidencias

# Si se usa systemd para el servicio backend
if [ -f /etc/systemd/system/sistema-incidencias.service ]; then
    systemctl daemon-reload
    systemctl start sistema-incidencias
else
    # Ejecución directa en segundo plano
    nohup java -jar /opt/sistema-incidencias/backend.jar > /var/log/sistema-incidencias/app.log 2>&1 &
    echo $! > /opt/sistema-incidencias/app.pid
fi

echo "[CodeDeploy:ApplicationStart] Aplicación iniciada."
