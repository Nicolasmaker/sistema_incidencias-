# ==============================================================================
# Dockerfile Seguro - Frontend Web (Nginx Unprivileged - Non-Root)
# ==============================================================================
FROM nginxinc/nginx-unprivileged:1.27-alpine

LABEL maintainer="Equipo DevOps Duoc UC"
LABEL description="Frontend Web - Sistema de Gestion de Incidencias"
LABEL version="1.1.0"

COPY --chown=101:101 nginx.conf /etc/nginx/conf.d/default.conf
COPY --chown=101:101 index.html style.css app.js /usr/share/nginx/html/

USER 101

EXPOSE 8080 8081

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/healthz || exit 1
