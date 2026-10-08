# 🛡️ Integración de SonarQube en Proyectos

Esta carpeta contiene la infraestructura y las plantillas estándar para realizar **análisis estático de código, detección de vulnerabilidades y medición de cobertura de pruebas** en cualquier microservicio o aplicación local utilizando SonarQube Community.

---

## 🏗️ Arquitectura y Flujo de Trabajo

El flujo de análisis opera a través de la red compartida `core_dev_network`:

1. **Tu Proyecto** ejecuta sus pruebas unitarias generando un reporte en formato LCOV (`coverage/lcov.info`).
2. **SonarScanner CLI** se ejecuta como un contenedor efímero, monta tu código fuente y el reporte de cobertura, y lo envía al servidor SonarQube.
3. **Servidor SonarQube (`core_sonarqube`)** procesa las métricas y actualiza el Quality Gate accesible en `http://localhost:9000`.

```text
┌────────────────────────┐         ┌────────────────────────┐         ┌────────────────────────┐
│  Proyecto / Código     │         │   SonarScanner CLI     │         │  SonarQube Server      │
│  pnpm test:cov         │ ───►    │   (Contenedor Docker)  │ ───►    │  (http://localhost:9000│
│  (coverage/lcov.info)  │         │   core_dev_network     │         │  core_sonarqube:9000)  │
└────────────────────────┘         └────────────────────────┘         └────────────────────────┘
```

---

## 🚀 1. Puesta en Marcha del Servidor SonarQube

Antes de ejecutar análisis, debes tener levantado el servidor SonarQube y su base de datos PostgreSQL dedicada:

1. **Levantar el servicio:**
   Desde la carpeta `.docker/`, ejecuta:

   ```bash
   make sonar
   ```

2. **Acceder a la interfaz web:**
   * Abre en tu navegador: [http://localhost:9000](http://localhost:9000)
   * Credenciales por defecto:
     * **Usuario:** `admin`
     * **Contraseña:** `admin` *(en el primer inicio te pedirá cambiarla)*.

3. **Generar un Token de Análisis:**
   * En SonarQube, dirígete a: **Mi Cuenta (esquina superior derecha) ➔ Security ➔ Generate Tokens**.
   * Nombre: `local-scanner` (o el nombre de tu preferencia).
   * Tipo: `User Token` o `Project Analysis Token`.
   * Copia el token generado (ejemplo: `squ_a1b2c3d4e5f6...`).

> [!NOTE]
> SonarQube utiliza Elasticsearch internamente. Si el contenedor no inicia en Linux, es posible que requieras aumentar el límite de mapas de memoria del kernel ejecutando:
>
> ```bash
> sudo sysctl -w vm.max_map_count=262144
> ```
>
> Para hacerlo permanente, agrega `vm.max_map_count=262144` en `/etc/sysctl.conf`.

---

## 📋 2. Integración en un Proyecto (Microservicio o Frontend)

Sigue estos pasos para incorporar el escaneo en el repositorio de tu proyecto:

### Paso 1 - Copiar los archivos plantilla

Copia los dos archivos de esta carpeta a la raíz del proyecto que deseas analizar:

```bash
# Desde la raíz de tu proyecto:
cp /ruta/a/.docker/sonar/sonar-project.properties .
cp /ruta/a/.docker/sonar/run-sonar.sh .
chmod +x run-sonar.sh
```

---

### Paso 2 - Configurar `sonar-project.properties`

Edita el archivo copiado en tu proyecto para adaptarlo:

```properties
# -----------------------------------------------------------
# Identificación del Proyecto
# -----------------------------------------------------------
sonar.projectKey=mi-servicio-api
sonar.projectName=Mi Servicio API
sonar.projectVersion=1.0

# -----------------------------------------------------------
# Conexión al servidor SonarQube (dentro de core_dev_network)
# -----------------------------------------------------------
sonar.host.url=http://core_sonarqube:9000

# Token generado en SonarQube (o sobreescribir vía variable SONAR_TOKEN)
sonar.token=tu_token_aqui

# -----------------------------------------------------------
# Rutas de Código y Pruebas
# -----------------------------------------------------------
sonar.sources=src
sonar.tests=test
sonar.test.inclusions=**/*.spec.ts,**/*.test.ts
sonar.exclusions=**/__mocks__/**,**/__stubs__/**,node_modules/**,dist/**,coverage/**

# -----------------------------------------------------------
# Reporte de Cobertura LCOV
# -----------------------------------------------------------
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.sourceEncoding=UTF-8
```

---

### Paso 3 - Configurar el script de cobertura en `package.json`

El script `run-sonar.sh` invoca `pnpm test:cov`. Asegúrate de tener configurado este comando en tu `package.json` para que genere el archivo `coverage/lcov.info`.

#### Si usas Vitest

En `package.json`:

```json
{
  "scripts": {
    "test:cov": "vitest run --coverage"
  }
}
```

En `vitest.config.ts`:

```ts
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8', // o 'istanbul'
      reporter: ['text', 'lcov', 'html'],
      reportsDirectory: './coverage'
    }
  }
});
```

#### Si usas Jest

En `package.json`:

```json
{
  "scripts": {
    "test:cov": "jest --coverage"
  }
}
```

En `jest.config.js`:

```js
module.exports = {
  coverageReporters: ['text', 'lcov', 'html'],
  coverageDirectory: 'coverage'
};
```

---

## ⚡ 3. Ejecución del Análisis

Tienes dos métodos principales para disparar el análisis:

### Opción A - Desde el propio proyecto (Recomendado)

Ejecuta el script bash directamente en la raíz de tu proyecto:

```bash
./run-sonar.sh
```

O suministrando el token dinámicamente como variable de entorno sin necesidad de escribirlo en el archivo de propiedades:

```bash
SONAR_TOKEN=squ_tu_token_secreto ./run-sonar.sh
```

El script se encargará automáticamente de:

1. Comprobar que `node_modules` exista (si falta, ejecuta `pnpm install`).
2. Ejecutar las pruebas con cobertura y asignar 8 GB de memoria a Node (`NODE_OPTIONS="--max-old-space-size=8192"`).
3. Verificar que `coverage/lcov.info` se haya generado correctamente.
4. Sondear que el servidor SonarQube esté activo en `http://localhost:9000`.
5. Ejecutar el escáner mediante Docker conectado a `core_dev_network`.

---

### Opción B - Desde `.docker/` con el Makefile

Si tu proyecto es el directorio padre de `.docker/` (o si configuraste el volumen en `docker-compose-sonar.yml`):

```bash
make sonar-scan
```

---

## 📊 4. Métricas e Interpretación de Resultados

Al terminar el escaneo, ingresa a [http://localhost:9000](http://localhost:9000) y verás:

* **Quality Gate:** Estado global (**Passed** en verde o **Failed** en rojo).
* **Bugs y Vulnerabilidades:** Errores potenciales de lógica o fallos de seguridad (OWASP Top 10, CWE).
* **Security Hotspots:** Fragmentos de código sensibles que requieren revisión manual del desarrollador.
* **Code Smells:** Deuda técnica, malas prácticas de refactorización y complejidad ciclomática.
* **Coverage:** Porcentaje exacto de líneas y ramas cubiertas por los tests unitarios.
* **Duplications:** Porcentaje de código duplicado susceptible de extracción.

---

## 🔧 5. Solución de Problemas Frecuentes (Troubleshooting)

### Error - SonarQube no respondió a tiempo

* Verifica que los contenedores de SonarQube estén corriendo con `docker ps`.
* Si están caídos, revisa los logs:

  ```bash
  docker logs -f core_sonarqube
  ```

* Recuerda que SonarQube puede tardar entre 30 y 60 segundos en iniciar completamente la primera vez.

### Error - No se encontró coverage/lcov.info

* Asegúrate de que `pnpm test:cov` genera la carpeta `coverage/` y dentro el archivo `lcov.info`.
* Revisa que el reporter `lcov` esté activado en tu configuración de Vitest o Jest.

### Error - Could not resolve host core_sonarqube

* El escáner Docker debe ejecutarse dentro de la red compartida `core_dev_network`.
* Ejecuta `make network` en `.docker/` para asegurar que la red existe.

### Error - JavaScript heap out of memory

* Proyectos con suites de pruebas extensas pueden agotar la memoria de Node.
* El script `run-sonar.sh` ya incluye `export NODE_OPTIONS="--max-old-space-size=8192"`. Si aún necesitas más memoria, aumenta ese valor a `12288` (12 GB) o `16384` (16 GB).