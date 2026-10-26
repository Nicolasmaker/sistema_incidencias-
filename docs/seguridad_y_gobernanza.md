# Manual de Seguridad, Gobernanza y Protección de Infraestructura

> **Proyecto:** Sistema de Gestión de Incidencias  
> **Área:** DevOps & Cloud Architecture  
> **Referencia:** Módulo 4 de Políticas de Seguridad  

---

## 1. Gestión Segura de Secretos y Parámetros
* **Cero Secretos en Texto Plano:** Queda estrictamente prohibido versionar claves, contraseñas o tokens en el código fuente o repositorios de Git.
* **Almacenamiento de Credenciales:**
  * **GitHub Secrets:** Utilizado para variables de pipeline como `AWS_ROLE_ARN`, `AWS_REGION` y nombres de buckets.
  * **AWS Secrets Manager:** Utilizado para credenciales de base de datos MySQL (`DB_USERNAME`, `DB_PASSWORD`) y endpoints privados.
* **Inyección en Tiempo de Ejecución:** Los servicios y contenedores consumen secretos directamente a través del SDK o variables inyectadas por el entorno de ejecución, nunca mediante archivos de configuración en el repositorio.

---

## 2. Autenticación Federada mediante GitHub OIDC
* Para erradicar el riesgo de credenciales estáticas de larga duración (`AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`), se implementa **OpenID Connect (OIDC)** entre GitHub Actions y AWS IAM.
* **Configuración del Rol IAM:**
  * El rol asume permisos temporales vía `sts:AssumeRoleWithWebIdentity`.
  * La directiva de confianza restringe estrictamente el acceso a la organización y repositorio del proyecto:
    ```json
    "condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike": { "token.actions.githubusercontent.com:sub": "repo:Nicolasmaker/sistema_incidencias-:*" }
    }
    ```

---

## 3. Cifrado en Reposo de Artefactos (AWS KMS)
* Todos los buckets de Amazon S3 vinculados al flujo de despliegue y pipelines (artefactos de CodePipeline/CodeDeploy y frontend) cuentan con cifrado del lado del servidor habilitado mediante **AWS KMS** (`aws:kms`).
* Se utiliza rotación anual automática de claves (`enable_key_rotation = true`).

---

## 4. Políticas de Protección de Ramas (`main` y `develop`)
Para garantizar la estabilidad y cumplimiento de Gitflow, la rama `main` y la rama `develop` cuentan con las siguientes reglas obligatorias en GitHub:

1. **Pull Requests Obligatorios:**
   * Bloqueo estricto de `push` directo a las ramas `main` y `develop`.
   * Todo cambio debe incorporarse a través de un Pull Request.
2. **Revisiones de Código Obligatorias (Code Review):**
   * Se requiere la aprobación de al menos 1 revisor antes de permitir el merge.
   * Nuevos commits descartan automáticamente las aprobaciones previas (*Dismiss stale pull request approvals when new commits are pushed*).
3. **Chequeos de Estado Exitosos (Status Checks):**
   * El workflow de validación CI y `action-tf-plan.yaml` deben finalizar con éxito antes de habilitar el botón de merge.
4. **Política de Merge en Releases:**
   * No se permite *Squash Merge* al integrar ramas de lanzamiento `release/v<number>` hacia `main` o `develop`; se debe preservar la historia completa mediante *Fast-Forward* o merge commit estándar.
