# Evaluación Parcial N°1 - Ingeniería DevOps

Este repositorio contiene la base de nuestro pipeline de despliegue para la Evaluación Parcial N°1.

## 1. Estrategia de Ramas (Branching Strategy)
Para este proyecto hemos elegido utilizar **GitFlow**.

**Justificación:**
Elegimos GitFlow porque nos proporciona una estructura clara y segura para trabajar en paralelo. Al separar las ramas de `main` (producción) y `develop` (desarrollo), nos aseguramos de que el código en `main` siempre sea estable y desplegable. Las ramas de `feature` nos permiten trabajar en nuevas características sin interrumpir el flujo principal, y las ramas `hotfix` nos dan la flexibilidad de resolver errores críticos en producción rápidamente.

## 2. Convenciones y Buenas Prácticas

### Naming de Ramas (Branch Naming)
Todas las ramas deben seguir este formato:
- **Features:** `feature/<nombre-descriptivo-en-minusculas>` (ej. `feature/add-healthcheck`)
- **Hotfixes:** `hotfix/<nombre-del-bug>` (ej. `hotfix/fix-db-connection`)

### Mensajes de Commit
Utilizaremos **Conventional Commits** para mantener un historial limpio y entendible:
- `feat: [descripción]` -> Para nuevas funcionalidades.
- `fix: [descripción]` -> Para solucionar errores.
- `docs: [descripción]` -> Cambios en la documentación (ej. README).
- `chore: [descripción]` -> Tareas de mantenimiento o configuración (ej. actualizar dependencias).

### Flujo de Merge y Revisión (Pull Requests)
1. **NUNCA** hacer *push* directo a `main` ni a `develop`.
2. Todo código nuevo debe subirse mediante un **Pull Request (PR)** hacia la rama `develop`.
3. Para que un PR sea aprobado, debe:
   - Pasar las validaciones de GitHub Actions (si aplican).
   - Ser revisado por al menos 1 compañero de equipo (Code Review).
4. El método de *merge* recomendado es **Squash and Merge** para mantener el historial de `develop` limpio.

### Estructura de Carpetas
- `/Grupo8`: Contiene el código fuente del microservicio.
- `/.github/workflows`: Contiene los scripts de automatización (CI/CD).
