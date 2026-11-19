#!/usr/bin/env bash
# ==============================================================================
# Script de Auditoria Automatizada de Seguridad y Cumplimiento (IE5 & IE6)
# Detiene el pipeline (exit 1) ante cualquier hallazgo critico.
# ==============================================================================
set -euo pipefail

MIN_COVERAGE="${MIN_COVERAGE:-50}"
ERRORS=0

echo "=================================================================="
echo "  AUDITORIA AUTOMATIZADA DE CUMPLIMIENTO Y SEGURIDAD (EP3)"
echo "=================================================================="

# ------------------------------------------------------------------------------
# 1. Escaneo de secretos en texto plano (codigo fuente, configs y k8s)
# ------------------------------------------------------------------------------
echo "[1/4] Verificando ausencia de secretos en texto plano..."
SECRET_PATTERNS='(AKIA[0-9A-Z]{16}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----|ghp_[A-Za-z0-9]{36}|SPRING_DATASOURCE_PASSWORD\s*=\s*[^$\{[:space:]]+|spring\.datasource\.password\s*=\s*[^$\{[:space:]]+|MYSQL_ROOT_PASSWORD\s*:\s*[^$\{[:space:]]+)'

# Buscar en backend/src, k8s (excluyendo *.example), frontend y docker-compose.yml
MATCHES=$(grep -rnE "$SECRET_PATTERNS" \
  backend/src/main \
  frontend \
  docker-compose.yml \
  k8s/00-namespaces.yaml \
  k8s/01-configmap.yaml \
  k8s/03-mysql.yaml \
  k8s/04-backend.yaml \
  k8s/05-frontend.yaml \
  k8s/06-observability.yaml 2>/dev/null || true)

if [ -n "$MATCHES" ]; then
  echo "ERROR CRITICO [SEC-01]: Se detectaron posibles secretos o credenciales en texto plano:"
  echo "$MATCHES"
  ERRORS=$((ERRORS + 1))
else
  echo "OK [SEC-01]: Sin secretos en texto plano detectados."
fi

# ------------------------------------------------------------------------------
# 2. Auditoria de seguridad en Dockerfiles (usuario no-root y HEALTHCHECK)
# ------------------------------------------------------------------------------
echo "[2/4] Auditando seguridad de Dockerfiles..."
for df in backend/Dockerfile frontend/Dockerfile; do
  if [ ! -f "$df" ]; then
    echo "ERROR CRITICO [DOC-01]: No existe $df"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  if ! grep -qE '^USER[[:space:]]+[^0r]' "$df"; then
    echo "ERROR CRITICO [DOC-02]: $df debe ejecutarse con un usuario no-root (USER)."
    ERRORS=$((ERRORS + 1))
  fi
  if ! grep -qE '^HEALTHCHECK' "$df"; then
    echo "ERROR CRITICO [DOC-03]: $df debe incluir una directiva HEALTHCHECK."
    ERRORS=$((ERRORS + 1))
  fi
done
if [ "$ERRORS" -eq 0 ]; then
  echo "OK [DOC]: Dockerfiles cumplen con usuario no-root y HEALTHCHECK."
fi

# ------------------------------------------------------------------------------
# 3. Auditoria de manifiestos Kubernetes (seguridad, recursos y observabilidad)
# ------------------------------------------------------------------------------
echo "[3/4] Auditando manifiestos Kubernetes en k8s/..."
for manifest in k8s/04-backend.yaml k8s/05-frontend.yaml; do
  if ! grep -q "runAsNonRoot: true" "$manifest"; then
    echo "ERROR CRITICO [K8S-01]: $manifest no define runAsNonRoot: true."
    ERRORS=$((ERRORS + 1))
  fi
  if ! grep -q "limits:" "$manifest"; then
    echo "ERROR CRITICO [K8S-02]: $manifest no define resources.limits."
    ERRORS=$((ERRORS + 1))
  fi
  if ! grep -q "livenessProbe:" "$manifest" || ! grep -q "readinessProbe:" "$manifest"; then
    echo "ERROR CRITICO [K8S-03]: $manifest debe definir livenessProbe y readinessProbe."
    ERRORS=$((ERRORS + 1))
  fi
  if ! grep -q 'prometheus.io/scrape: "true"' "$manifest"; then
    echo "ERROR CRITICO [K8S-04]: $manifest no habilita anotaciones de observabilidad Prometheus."
    ERRORS=$((ERRORS + 1))
  fi
done
if [ "$ERRORS" -eq 0 ]; then
  echo "OK [K8S]: Manifiestos cumplen politicas de seguridad, limites y observabilidad."
fi

# ------------------------------------------------------------------------------
# 4. Validacion de cobertura minima de pruebas (JaCoCo XML)
# ------------------------------------------------------------------------------
echo "[4/4] Validando umbral minimo de cobertura JaCoCo (>= ${MIN_COVERAGE}%)..."
JACOCO_XML="backend/target/site/jacoco/jacoco.xml"
if [ -f "$JACOCO_XML" ]; then
  COVERAGE=$(python3 - "$JACOCO_XML" <<'PYEOF'
import sys, xml.etree.ElementTree as ET
tree = ET.parse(sys.argv[1])
root = tree.getroot()
for c in root.findall("counter"):
    if c.attrib.get("type") == "INSTRUCTION":
        missed = int(c.attrib["missed"])
        covered = int(c.attrib["covered"])
        total = missed + covered
        pct = (covered * 100.0 / total) if total > 0 else 0.0
        print(f"{pct:.2f}")
        break
PYEOF
)
  echo "Cobertura actual de instrucciones JaCoCo: ${COVERAGE}%"
  IS_BELOW=$(python3 -c "print(1 if float('${COVERAGE}') < float('${MIN_COVERAGE}') else 0)")
  if [ "$IS_BELOW" -eq 1 ]; then
    echo "ERROR CRITICO [QA-01]: Cobertura (${COVERAGE}%) inferior al minimo permitido (${MIN_COVERAGE}%)."
    ERRORS=$((ERRORS + 1))
  else
    echo "OK [QA-01]: Cobertura (${COVERAGE}%) cumple el umbral minimo (${MIN_COVERAGE}%)."
  fi
else
  echo "ADVERTENCIA [QA-01]: No se encontro $JACOCO_XML (ejecute ./mvnw test antes de auditar cobertura)."
fi

echo "=================================================================="
if [ "$ERRORS" -gt 0 ]; then
  echo "RESULTADO: AUDITORIA FALLIDA ($ERRORS hallazgos criticos). PIPELINE DETENIDO."
  exit 1
else
  echo "RESULTADO: AUDITORIA APROBADA. Cumplimiento normativo verificado."
  exit 0
fi
