-include .env
export

.PHONY: help network services floci taskview ui apps sonar sonar-scan all stop down clean

help:
	@echo "Comandos disponibles:"
	@echo "  make services     - Levanta Postgres, Mongo (ReplicaSet) y Redis"
	@echo "  make floci        - Levanta Floci (emulador AWS: SQS, SNS, DynamoDB)"
	@echo "  make taskview     - Levanta Taskview Community"
	@echo "  make ui           - Levanta pgAdmin 4, Mongo Express y Chat2DB"
	@echo "  make apps         - Levanta n8n"
	@echo "  make sonar        - Levanta el servidor SonarQube y su base de datos"
	@echo "  make sonar-scan   - Ejecuta el análisis de SonarScanner sobre el proyecto"
	@echo "  make all          - Levanta services, ui y apps"
	@echo "  make stop         - Pausa todos los contenedores sin eliminarlos"
	@echo "  make down         - Apaga y remueve los contenedores conservando los datos"
	@echo "  make clean        - Limpieza total (contenedores, huérfanos e imágenes dangling)"

# -----------------------------------------------------------
# Red Compartida
# -----------------------------------------------------------
network:
	@docker network inspect $(EXTERNAL_NETWORK) >/dev/null 2>&1 || \
		docker network create --driver bridge $(EXTERNAL_NETWORK) && \
		echo "Red $(EXTERNAL_NETWORK) verificada/creada"

# -----------------------------------------------------------
# Capa de Servicios Principales (DBs, Storage, Colas)
# -----------------------------------------------------------
services: network
	docker compose -f docker-compose-services.yml \
		$(if $(filter down,$(MAKECMDGOALS)),down,$(if $(filter stop,$(MAKECMDGOALS)),stop,up -d)) \
		$(if $(filter build,$(MAKECMDGOALS)),--build,)

# -----------------------------------------------------------
# Emulador AWS (Floci)
# -----------------------------------------------------------
floci: network
	docker compose -f docker-compose-floci.yml \
		$(if $(filter down,$(MAKECMDGOALS)),down,$(if $(filter stop,$(MAKECMDGOALS)),stop,up -d)) \
		$(if $(filter build,$(MAKECMDGOALS)),--build,)

# -----------------------------------------------------------
# Gestor de Tareas (Taskview)
# -----------------------------------------------------------
taskview: network
	docker compose -f docker-compose-taskview.yml \
		$(if $(filter down,$(MAKECMDGOALS)),down,$(if $(filter stop,$(MAKECMDGOALS)),stop,up -d)) \
		$(if $(filter build,$(MAKECMDGOALS)),--build,)

# -----------------------------------------------------------
# Capa de Interfaces Gráficas (pgAdmin, Mongo)
# -----------------------------------------------------------
ui: network
	docker compose -f docker-compose-ui.yml \
		$(if $(filter down,$(MAKECMDGOALS)),down,$(if $(filter stop,$(MAKECMDGOALS)),stop,up -d)) \
		$(if $(filter build,$(MAKECMDGOALS)),--build,)

# -----------------------------------------------------------
# Capa de Aplicaciones (n8n)
# -----------------------------------------------------------
apps: network
	docker compose -f docker-compose-apps.yml \
		$(if $(filter down,$(MAKECMDGOALS)),down,$(if $(filter stop,$(MAKECMDGOALS)),stop,up -d)) \
		$(if $(filter build,$(MAKECMDGOALS)),--build,)

# -----------------------------------------------------------
# Capa de Auditoría y Calidad (SonarQube)
# -----------------------------------------------------------
sonar: network
	docker compose -f docker-compose-sonar.yml \
		$(if $(filter down,$(MAKECMDGOALS)),down,$(if $(filter stop,$(MAKECMDGOALS)),stop,up -d sonar_db sonarqube))

sonar-scan: network
	docker compose -f docker-compose-sonar.yml run --rm sonar_scanner

# -----------------------------------------------------------
# Comandos Globales
# -----------------------------------------------------------
all: services ui apps

stop:
	-docker compose -f docker-compose-ui.yml stop
	-docker compose -f docker-compose-apps.yml stop
	-docker compose -f docker-compose-sonar.yml stop
	-docker compose -f docker-compose-floci.yml stop
	-docker compose -f docker-compose-taskview.yml stop
	-docker compose -f docker-compose-services.yml stop

down:
	-docker compose -f docker-compose-ui.yml down
	-docker compose -f docker-compose-apps.yml down
	-docker compose -f docker-compose-sonar.yml down
	-docker compose -f docker-compose-floci.yml down
	-docker compose -f docker-compose-taskview.yml down
	-docker compose -f docker-compose-services.yml down

clean:
	-docker compose -f docker-compose-ui.yml down -v --remove-orphans
	-docker compose -f docker-compose-apps.yml down -v --remove-orphans
	-docker compose -f docker-compose-sonar.yml down -v --remove-orphans
	-docker compose -f docker-compose-floci.yml down -v --remove-orphans
	-docker compose -f docker-compose-taskview.yml down -v --remove-orphans
	-docker compose -f docker-compose-services.yml down -v --remove-orphans
	-docker image prune -f
	-docker container prune -f

%:
	@: