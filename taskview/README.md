# 📋 TaskView Community Edition — Guía de Puesta en Marcha y Primer Usuario

TaskView es una plataforma de **gestión de tareas, proyectos y flujos de trabajo orientada a equipos de desarrollo**. Diseñada como una alternativa self-hosted, privada y transparente a SaaS como Jira, Linear o Trello, con soporte nativo para tableros Kanban, sprints, seguimiento de tiempo, control de dependencias y un servidor **Model Context Protocol (MCP)** para agentes de inteligencia artificial.

---

## 🏗️ Arquitectura del Servicio

El servicio está desacoplado en una arquitectura multi-contenedor orquestada mediante [`docker-compose-taskview.yml`](../docker-compose-taskview.yml) sobre la red compartida `core_dev_network`:

```text
┌────────────────────────┐         ┌────────────────────────┐         ┌────────────────────────┐
│  Navegador Web         │         │  TaskView Web UI       │         │  TaskView API Server   │
│  Usuario / Dev         │ ───►    │  (Vue / Nginx SPA)     │ ───►    │  (Node.js / Express)   │
│  http://localhost:3080 │         │  core_taskview:3080    │         │  core_taskview_api:1401│
└────────────────────────┘         └────────────────────────┘         └───────────┬────────────┘
                                                                                  │
                                                                                  ▼
┌────────────────────────┐                                            ┌────────────────────────┐
│  TaskView Migration    │                                            │  TaskView Database     │
│  (Aplica Drizzle ORM)  │ ─────────────────────────────────────────► │  (PostgreSQL 17)       │
│  core_taskview_migration                                            │  core_taskview_db:5432 │
└────────────────────────┘                                            └────────────────────────┘
```

1. **`core_taskview_db`**: Base de datos dedicada PostgreSQL 17 (`taskviewdb`) con persistencia en `core_taskview_db_data`.
2. **`core_taskview_migration`**: Contenedor efímero que ejecuta automáticamente las migraciones Drizzle del esquema `tv_auth` y `tasks` al arrancar.
3. **`core_taskview_api`**: Backend Node.js / Express en el puerto `1401`.
4. **`core_taskview`**: Aplicación web frontend (SPA en Vue 3 y Nuxt UI) servida por Nginx en el puerto `3080`.

---

## 🚀 1. Puesta en Marcha

Desde la raíz del repositorio `.docker/`:

```bash
# Levantar el stack completo (Base de datos, migraciones, API y Web)
make taskview

# En caso de necesitar reconstrucción o actualizar variables
make taskview build

# Detener los contenedores sin borrar los datos
make taskview stop

# Apagar y desmontar los contenedores (conservando los volúmenes de datos)
make taskview down
```

---

## 🔑 2. Credenciales de la Primera Carga (Seed User)

Durante la inicialización automática de la base de datos, el contenedor de migraciones crea un **usuario raíz/administrador inicial**:

| Campo | Valor |
| :--- | :--- |
| **URL de Acceso** | [http://localhost:3080](http://localhost:3080) |
| **Email / Login** | `test@mail.dest` *(o el nombre de usuario `user`)* |
| **Contraseña Inicial** | `user1!#Q` |

---

## 📝 3. Paso a Paso para la Configuración Inicial

### Paso 1: Iniciar Sesión
1. Abre tu navegador e ingresa a [http://localhost:3080](http://localhost:3080).
2. En la pantalla de login, introduce:
   * **Login / Email:** `test@mail.dest`
   * **Password:** `user1!#Q`
3. Haz clic en **Sign In**.

---

### Paso 2: Personalizar tu Perfil y Asegurar tu Contraseña
> [!IMPORTANT]
> El usuario inicial tiene una contraseña genérica de semilla. Se recomienda actualizarla en tu primer ingreso:

1. En la barra lateral izquierda, haz clic en el icono de tu perfil o dirígete a **Settings** (Configuración) ➔ **Profile**.
2. **Actualizar Email y Nombre:**
   * Cambia `test@mail.dest` por tu correo real de desarrollo (ejemplo: `tu-email@gmail.com`).
   * Configura tu nombre visible y avatar.
3. **Actualizar Contraseña:**
   * Dirígete a la pestaña **Security** (o Seguridad).
   * Ingresa la contraseña actual (`user1!#Q`) y define tu nueva contraseña segura.
   * Guarda los cambios.

---

### Paso 3: Crear tu Organización o Workspace
1. En la parte superior de la barra lateral, haz clic en el selector de organizaciones.
2. Crea tu organización principal (por ejemplo: `Core Dev Team` o `Personal Projects`).
3. En **Settings ➔ Members**, podrás gestionar roles, permisos y colaboradores si deseas invitar miembros a tu equipo local.

---

### Paso 4: Crear tu Primer Proyecto (Goal) y Tablero Kanban
En TaskView, los proyectos se denominan **Goals**:

1. Haz clic en **+ New Goal** (o Nuevo Proyecto/Meta).
2. Asigna un nombre (ejemplo: `Infraestructura Docker`, `Web App 2026`).
3. Elige un color y define tus listas de tareas (**Task Lists**) o columnas Kanban:
   * `Backlog`
   * `En Progreso`
   * `En Revisión`
   * `Completado`
4. Puedes crear tareas asignando prioridades (Baja, Media, Alta), fechas límite, subtareas anidadas y etiquetas (**Tags**).

---

### Paso 5: Conexión con Asistentes de IA mediante MCP (Opcional)
TaskView incluye integración nativa con el protocolo **Model Context Protocol (MCP)**, permitiendo que agentes de IA (como Antigravity, Claude Code o Cursor) inspeccionen tus tareas, creen tickets y actualicen estados automáticamente:

1. En TaskView, ve a **Settings ➔ API Tokens**.
2. Haz clic en **Create Token** y asígnale un nombre (ej: `antigravity-agent`).
3. Copia el token generado con el prefijo `tvk_...`.
4. Para usarlo en cualquier cliente MCP, la configuración es:

```json
{
  "mcpServers": {
    "taskview": {
      "command": "npx",
      "args": ["-y", "taskview-mcp"],
      "env": {
        "TASKVIEW_URL": "http://localhost:1401",
        "TASKVIEW_TOKEN": "tvk_tu_token_aqui"
      }
    }
  }
}
```

---

## ⚙️ 4. Variables de Entorno Disponibles

En el archivo [`.env`](../.env) de la raíz se encuentran los parámetros que controlan este stack:

```env
# Taskview
TASKVIEW_PORT=3080                   # Puerto de acceso a la Web UI en el host
TASKVIEW_API_PORT=1401               # Puerto expuesto para la API HTTP y MCP
TASKVIEW_DB_USER=tvdbuser            # Usuario de la base de datos PostgreSQL
TASKVIEW_DB_PASSWORD=tvdbpass123     # Contraseña de la base de datos
TASKVIEW_DB_NAME=taskviewdb          # Nombre de la base de datos
TASKVIEW_JWT_SECRET=tu_clave_secreta # Clave secreta para firmar los tokens JWT
```

---

## 🩺 5. Diagnóstico y Troubleshooting

### ¿Cómo verificar el estado de los contenedores?
```bash
docker ps --filter "name=core_taskview"
```

### ¿Cómo consultar los logs del servidor API o de la Web?
```bash
# Ver logs del backend API
docker logs core_taskview_api --tail 50 -f

# Ver logs de la aplicación Web
docker logs core_taskview --tail 50 -f

# Ver logs del proceso de migraciones
docker logs core_taskview_migration
```

### ¿Qué hacer si la web muestra error de conexión con la API?
Asegúrate de que la variable `TASKVIEW_API_URL` apunte a `http://localhost:1401`. Puedes comprobar la configuración de runtime que carga el navegador ejecutando:
```bash
curl -s http://localhost:3080/config.js
```
Debe responder:
```javascript
window.__TASKVIEW_CONFIG__ = { apiUrl: "http://localhost:1401" };
```
