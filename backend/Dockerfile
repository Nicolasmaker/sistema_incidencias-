# ==============================================================================
# Dockerfile Multietapa Seguro - Microservicio Backend (Spring Boot 4 / Java 21)
# Incluye usuario no-root y metadatos para observabilidad (EP2 & EP3)
# ==============================================================================

# Etapa 1: Build y compilacion del artefacto
FROM eclipse-temurin:21-jdk-jammy AS builder
WORKDIR /app

COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN chmod +x mvnw

COPY src ./src
RUN ./mvnw -B clean package -DskipTests

# Etapa 2: Imagen de ejecucion ligera y endurecida (non-root)
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

LABEL maintainer="Equipo DevOps Duoc UC"
LABEL description="Microservicio de Gestion de Incidencias con Observabilidad"
LABEL version="1.1.0"

# Crear usuario de sistema sin privilegios (IE5 - Cumplimiento de seguridad)
RUN groupadd --system --gid 1001 appgroup \
    && useradd --system --uid 1001 --gid appgroup --no-create-home --shell /sbin/nologin appuser

COPY --from=builder --chown=appuser:appgroup /app/target/grupo8-1.0.0.jar app.jar

USER 1001:1001

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD ["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/8080 && printf 'GET /actuator/health/liveness HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n' >&3 && grep -q '200' <&3"]

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
