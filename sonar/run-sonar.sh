#!/bin/bash

set -e

echo "🚀 Iniciando proceso de análisis con SonarQube..."

# 1. Validar e instalar dependencias si faltan
if [ ! -d node_modules ]; then
  echo "📦 node_modules no encontrado. Ejecutando pnpm install..."
  pnpm install
fi

# 2. Ejecutar pruebas con cobertura
echo "🧪 Ejecutando pruebas unitarias con cobertura..."
export NODE_OPTIONS="--max-old-space-size=8192"

pnpm test:cov || {
  echo "⚠️ Advertencia: Algunas pruebas fallaron, pero se continuará con el análisis."
}

# 3. Validar archivo de reporte LCOV
if [ ! -f coverage/lcov.info ]; then
  echo "❌ Error: No se encontró coverage/lcov.info. Revisa la configuración de tests."
  exit 1
fi

# 4. Comprobar disponibilidad del servidor SonarQube
echo "⏳ Esperando a que SonarQube esté disponible en http://localhost:9000..."

SONAR_READY=false
for i in $(seq 1 30); do
  STATUS=$(curl -s http://localhost:9000/api/system/status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d':' -f2 | tr -d '"' || true)
  if [ "$STATUS" = "UP" ]; then
    echo "✅ SonarQube está listo."
    SONAR_READY=true
    break
  fi
  echo "   Intento $i/30: Estado = ${STATUS:-DOWN}. Esperando 5s..."
  sleep 5
done

if [ "$SONAR_READY" = false ]; then
  echo "❌ Error: SonarQube no respondió a tiempo. Asegúrate de haber ejecutado 'make sonar' en .docker/"
  exit 1
fi

# 5. Ejecutar escáner conectándose a la red core_dev_network
echo "🔍 Ejecutando SonarScanner..."
docker run --rm \
  --name sonar_scanner_run \
  --network core_dev_network \
  -v "$(pwd):/usr/src" \
  -w /usr/src \
  sonarsource/sonar-scanner-cli:latest

echo "✅ Análisis completado con éxito. Revisa los resultados en http://localhost:9000"