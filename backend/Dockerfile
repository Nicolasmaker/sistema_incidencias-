# ==============================================================================
# Dockerfile Multietapa - Microservicio Backend (Spring Boot 4 / Java 21)
# ==============================================================================

# Etapa 1: Build y compilación del artefacto
FROM eclipse-temurin:21-jdk-jammy AS builder
WORKDIR /app

# Copiar configuración de dependencias y wrapper de Maven
COPY pom.xml mvnw ./
COPY .mvn .mvn
RUN chmod +x mvnw

# Copiar código fuente y compilar JAR
COPY src ./src
RUN ./mvnw clean package -DskipTests

# Etapa 2: Imagen de ejecución ligera
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Metadatos del contenedor
LABEL maintainer="Equipo DevOps Duoc UC"
LABEL description="Microservicio de Gestion de Incidencias"
LABEL version="1.0.0"

# Copiar el binario compilado desde la etapa de build
COPY --from=builder /app/target/grupo8-1.0.0.jar app.jar

# Exponer el puerto del microservicio
EXPOSE 8080

# Comando de inicio del contenedor
ENTRYPOINT ["java", "-jar", "app.jar"]
