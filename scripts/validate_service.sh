#!/bin/bash
# ==============================================================================
# Hook: ValidateService (AWS CodeDeploy)
# Verificación de salud y respuesta de la API backend
# ==============================================================================
set -e

echo "[CodeDeploy:ValidateService] Validando estado de salud del servicio..."

MAX_ATTEMPTS=15
DELAY=5
HEALTH_URL="http://localhost:8080/api/incidencias"

for i in $(seq 1 $MAX_ATTEMPTS); do
    echo "Intento $i de $MAX_ATTEMPTS: consultando $HEALTH_URL..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || echo "000")
    
    if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 204 ]; then
        echo "✅ [CodeDeploy:ValidateService] Servicio respondiendo con código HTTP $HTTP_CODE."
        exit 0
    fi
    
    sleep $DELAY
done

echo "❌ [CodeDeploy:ValidateService] El servicio no respondió satisfactoriamente dentro del tiempo límite."
exit 1
