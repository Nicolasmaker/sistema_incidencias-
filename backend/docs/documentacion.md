# Documento de Especificación: Sistema de Gestión de Incidencias

> **Organización:** CahuinLab’s  
> **Proyecto:** Aplicación Fullstack para Diagnóstico Cloud Native  
> **Modalidad:** Trabajo Grupal Colaborativo  

---

## 1. Contexto y Objetivos

Una organización pequeña llamada **cahuinLab’s** necesita una herramienta interna para registrar y dar seguimiento a incidencias técnicas sobre requerimientos de empleados: problemas de acceso, errores de aplicaciones, fallas de equipos, solicitudes de soporte y otros eventos similares con respecto a sus herramientas de trabajo.

El propósito central es **construir en equipo una aplicación fullstack sencilla** que permita diagnosticar las competencias previas necesarias para abordar posteriormente prácticas *cloud native* sobre un sistema real.

### Objetivos Específicos
* Levantamiento de requerimientos funcionales y no funcionales básicos.
* Identificación de actores, datos y reglas del problema.
* Diseño de una arquitectura fullstack simple.
* Justificación de decisiones arquitectónicas iniciales.
* Construcción de una interfaz web conectada a un backend.
* Implementación de una API con operaciones CRUD.
* Persistencia de datos en una base de datos.
* Trabajo colaborativo utilizando **Git**.
* Contenerización de los componentes del sistema.
* Despliegue de la solución completa con **Docker Compose**.
* Documentación técnica de ejecución y verificación de la aplicación.

---

## 2. Modalidad y Trabajo Colaborativo

El desarrollo de esta solución es **grupal**. Cada integrante del equipo debe participar activamente en el análisis, la implementación, la integración y la explicación de la solución. El repositorio debe reflejar contribuciones distribuidas entre todos los integrantes.

> **Nota:** Adicionalmente, cada estudiante debe contestar de forma individual y privada el cuestionario definido para esta actividad.

### Estrategia de Trabajo con Git
* **Rama Principal (`main`):** Protegida. La integración se realizará mediante *Pull Requests* revisados y aprobados por al menos un integrante distinto del autor.
* **Ramas de Trabajo:** Por funcionalidad (`feature/nombre-funcionalidad`), creadas a partir de `main`.
* **Convención de Commits:** Descriptivos (ej. `feat:`, `fix:`, `docs:`) que referencien el requerimiento funcional asociado cuando corresponda (ej. `feat: implementa RF-01`).
* **Evidencia:** El historial de commits debe demostrar aportes equitativos de todo el equipo.

---

## 3. Levantamiento de Requerimientos

### 3.1. Problema
La organización **cahuinLab’s** experimenta dificultades en la gestión y seguimiento de incidencias técnicas operativas reportadas por sus colaboradores. La falta de un canal centralizado provoca desorganización, pérdida de tiempo y baja visibilidad del estado real de las solicitudes.

Actualmente, el registro de fallas se realiza mediante canales informales (mensajería instantánea, correos o conversaciones verbales), lo que genera:
* Traspapelo de solicitudes y duplicidad de esfuerzos.
* Retrasos en los tiempos de respuesta.
* Imposibilidad de priorizar adecuadamente problemas críticos.

La aplicación resolverá esta problemática proveyendo un sistema centralizado e intuitivo que permita **registrar, actualizar, clasificar y visualizar el ciclo de vida completo de cada incidencia**.

### 3.2. Actores

#### Operador de Soporte
* **¿Qué necesita hacer?:** Registrar nuevas incidencias, consultar el listado general, ver detalles, actualizar información o estado, filtrar la lista y eliminar registros.
* **¿Qué información utiliza?:** Título del problema, descripción detallada, categoría (*Hardware, Software, Acceso*), prioridad (*Baja, Media, Alta, Crítica*), estado actual y fecha de creación.
* **¿Qué resultado espera?:** Un panel centralizado para priorizar y gestionar el flujo de resolución, con indicadores claros sobre el volumen de requerimientos pendientes y resueltos.

> **Nota de alcance:** Se define a un único actor (**Operador de Soporte**) que gestiona el ciclo completo en representación de los colaboradores. No se contempla un portal de autoservicio ni gestión de roles/autenticación.

---

### 3.3. Requerimientos Funcionales (RF)

| ID | Requerimiento | Descripción |
| :--- | :--- | :--- |
| **RF-01** | **Registrar incidencia** | El sistema debe permitir registrar una nueva incidencia especificando título, descripción, categoría y prioridad. |
| **RF-02** | **Listar incidencias** | El sistema debe mostrar un listado general de todas las incidencias con sus datos principales (título, categoría, prioridad, estado y fecha). |
| **RF-03** | **Ver detalle** | El sistema debe permitir seleccionar una incidencia para consultar su información completa. |
| **RF-04** | **Actualizar incidencia** | El sistema debe permitir modificar el título, descripción, categoría y prioridad de una incidencia existente. |
| **RF-05** | **Eliminar incidencia** | El sistema debe permitir remover una incidencia de la base de datos previa confirmación del operador. |
| **RF-06** | **Cambiar estado** | El sistema debe permitir modificar el estado de una incidencia (ej. `ABIERTA`, `EN PROCESO`, `RESUELTA`, `CERRADA`). |
| **RF-07** | **Búsqueda y filtrado** | El sistema debe permitir filtrar por estado, categoría o prioridad, además de buscar por texto en el título. |
| **RF-08** | **Resumen e indicadores** | El sistema debe desplegar un panel con contadores de incidencias agrupados por su estado actual. |

---

### 3.4. Requerimientos No Funcionales (RNF)

* **RNF-01 (Ejecución y reproducibilidad):** La solución completa (*frontend, backend y base de datos*) debe ser capaz de iniciarse localmente mediante el comando `docker compose up` siguiendo las instrucciones del `README.md`.
* **RNF-02 (Persistencia de datos):** La información debe almacenarse en una base de datos utilizando volúmenes de Docker, evitando la pérdida de datos al reiniciar los contenedores.
* **RNF-03 (Usabilidad y diseño adaptativo):** La interfaz web debe ser intuitiva, responsiva y ofrecer mensajes claros de confirmación o error ante las acciones del usuario.
* **RNF-04 (Desacoplamiento arquitectónico):** Solución dividida en Frontend y Backend API, donde la interfaz consuma el backend mediante peticiones HTTP/REST estandarizadas.
* **RNF-05 (Manejo estandarizado de errores):** La API backend debe retornar códigos de estado HTTP válidos (200, 201, 400, 404, 500) y respuestas JSON comprensibles.

---

### 3.5. Reglas de Negocio (RN)

1. **RN-01 (Estado inicial automático):** Toda incidencia recién creada debe asignarse automáticamente con el estado `ABIERTA`.
2. **RN-02 (Campos obligatorios):** No se permitirá guardar ni actualizar incidencias que omitan título, descripción, categoría o prioridad.
3. **RN-03 (Transición de cierre):** Una incidencia sólo podrá ser marcada como `CERRADA` si previamente estuvo en estado `EN PROCESO` o `RESUELTA`.
4. **RN-04 (Inmutabilidad de fecha):** La fecha y hora de creación debe ser asignada automáticamente por el servidor y no podrá ser modificada manualmente.

---

### 3.6. Criterios de Aceptación

#### Criterio 1 — Para RF-01 (Registrar incidencia)
* **Dado que** el operador ingresó al formulario de registro y completó todos los campos obligatorios (*título, descripción, categoría y prioridad*),
* **Cuando** presiona el botón *"Guardar incidencia"*,
* **Entonces** la incidencia queda persistida en la base de datos, el sistema muestra un mensaje de éxito, y la nueva incidencia se visualiza al inicio del listado principal con estado `ABIERTA`.

#### Criterio 2 — Para RF-06 (Cambiar estado de incidencia)
* **Dado que** existe una incidencia en el listado con estado `ABIERTA`,
* **Cuando** el operador selecciona la opción de cambiar estado a `EN PROCESO`,
* **Entonces** el estado se actualiza en el backend, la interfaz refleja inmediatamente el cambio sin necesidad de recargar la página, y el contador de incidencias *"En Proceso"* del panel de resumen se incrementa en 1.

#### Criterio 3 — Para RF-07 (Búsqueda y filtrado)
* **Dado que** existen incidencias registradas de distintas categorías (*Hardware, Software, Acceso*),
* **Cuando** el operador selecciona el filtro por categoría `Hardware`,
* **Entonces** el listado se actualiza mostrando únicamente las incidencias de tipo `Hardware` y se ocultan temporalmente las demás.

---

## 4. Alcance del Proyecto

### 🟢 Dentro del Alcance (In-Scope)
* Desarrollo de una interfaz web (Frontend) interactiva.
* Desarrollo de una API REST (Backend) con operaciones CRUD completas.
* Base de datos relacional o no relacional contenerizada con volúmenes de persistencia.
* Módulo de filtrado, búsqueda básica y contadores de resumen.
* Contenerización individual mediante `Dockerfile` y orquestación unificada con `docker-compose`.
* Documentación técnica de ejecución e instalación.

### 🔴 Fuera del Alcance (Out-of-Scope)
* Autenticación y autorización de usuarios (Login, roles, JWT).
* Recuperación de contraseña o gestión de cuentas de usuario.
* Envío de notificaciones por correo electrónico, SMS o mensajería (Slack/Teams).
* Arquitectura basada en microservicios o colas de mensajería asíncronas.
* Carga y almacenamiento de archivos adjuntos (imágenes, logs).
* Despliegue productivo en la nube (AWS, GCP, Azure).

---

## 5. Arquitectura y Decisiones Técnicas

### 5.1. Stack Tecnológico

* **Backend:** Java 21 + Spring Boot 4.x
* **Frontend:** React con Vite
* **Persistencia:** MySQL
* **Infraestructura Local:** Docker + Docker Compose

---

### 5.2. Estructura del Proyecto

```text
GRUPO8 (Backend)
├── .mvn/wrapper
└── src
    ├── main
    │   ├── java/com/sistemaIncidencias/grupo8
    │   │   ├── controller
    │   │   ├── models
    │   │   ├── repository
    │   │   └── services
    │   └── resources
    └── test/java/com/sistemaIncidencias/grupo8

frontend (Frontend)
├── public
└── src
    ├── components/    # Formularios, listado, filtros, panel de resumen
    ├── pages/         # Vistas principales: listado, detalle, registro
    ├── services/      # Consumo de la API REST vía fetch/axios
    └── App.jsx