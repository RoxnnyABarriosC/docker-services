# 🦙 Inteligencia Artificial Local (Ollama + LLaMA 3.2 + Open WebUI)

Entorno aislado y ligero para **emulación de Inteligencia Artificial local** compatible con la API de OpenAI, orquestado mediante [`docker-compose-ai.yml`](../docker-compose-ai.yml) sobre la red compartida `core_dev_network`.

---

## 🏗️ Arquitectura del Servicio

```text
┌─────────────────────────┐         ┌─────────────────────────┐
│   Navegador Web         │         │   Open WebUI            │
│   http://localhost:3001 │ ───►    │   (UI estilo ChatGPT)   │
└─────────────────────────┘         │   core_open_webui:8080  │
                                    └────────────┬────────────┘
                                                 │
                                                 ▼
┌─────────────────────────┐         ┌─────────────────────────┐
│   Apps / n8n / Código   │ ───►    │   Ollama Server         │
│   http://localhost:11434│         │   (API OpenAI / LLaMA)  │
│   (ó core_ollama:11434) │         │   core_ollama:11434     │
└─────────────────────────┘         └────────────┬────────────┘
                                                 │
                                                 ▼
                                    ┌─────────────────────────┐
                                    │   Volumen Persistente   │
                                    │   core_ollama_data      │
                                    └─────────────────────────┘
```

1. **`core_ollama`**: Servidor de inferencia local. Expone la API nativa de Ollama y la API compatible con OpenAI en el puerto `11434`.
2. **`core_open_webui`**: Interfaz visual moderna (opcional/incluida) en el puerto `3001` para interactuar mediante chat, gestionar prompts y descargar modelos visualmente.

---

## ⚡ Recomendación de Modelos (CPU + 64 GB RAM)

En una máquina con **64 GB de RAM** y procesador **AMD Ryzen (inferencia en CPU sin GPU dedicada)**, la memoria RAM es más que suficiente, pero la velocidad de generación de texto (tokens por segundo) depende de los hilos de la CPU:

| Modelo | Tamaño en Disco / RAM | Velocidad en CPU | Uso Recomendado |
| :--- | :--- | :--- | :--- |
| **`llama3.2:3b`** ⭐ *(Recomendado)* | **~2.0 GB** | **~25 - 35 tokens/s** | **Ideal para emular IA:** rápido, inteligente, excelente siguiendo instrucciones y formateando JSON. |
| **`llama3.2:1b`** | **~1.3 GB** | **~45 - 60 tokens/s** | Ultra-ligero, instantáneo. Ideal para tests unitarios, mocks de API y pipelines automatizados. |
| **`llama3.1:8b`** | **~4.7 GB** | **~6 - 10 tokens/s** | Razonamiento profundo y mayor vocabulario. Apto para tareas complejas sin saturar la RAM. |
| **`qwen2.5-coder:3b`** | **~1.9 GB** | **~25 - 35 tokens/s** | Especializado en código, generación de scripts y funciones. |

> [!TIP]
> **¿Por qué evitar modelos de 70B en CPU?** Aunque caben en tus 64 GB de RAM, en CPU generarían apenas 1-2 tokens por segundo. Con `llama3.2:3b` obtienes respuestas casi instantáneas con un consumo mínimo de recursos.

---

## 🚀 1. Puesta en Marcha

Desde la raíz de `.docker/`:

```bash
# Levantar Ollama y Open WebUI
make ai
```

Para verificar que los contenedores están corriendo:
```bash
docker ps --filter "name=core_ollama" --filter "name=core_open_webui"
```

---

## 📥 2. Descargar e Inicializar el Modelo Ligero

Puedes descargar el modelo directamente ejecutando dentro del contenedor de Ollama:

```bash
# Opción recomendada: LLaMA 3.2 (3B)
docker exec -it core_ollama ollama pull llama3.2:3b

# O la versión ultra-ligera (1B):
docker exec -it core_ollama ollama pull llama3.2:1b
```

Para probarlo directamente en la terminal:
```bash
docker exec -it core_ollama ollama run llama3.2:3b
```

---

## 🌐 3. Acceso Web y Pruebas

- **Open WebUI (Chat Web):** [http://localhost:3001](http://localhost:3001)
  *(El primer usuario que se registra en la interfaz local queda configurado como Administrador).*
- **Ollama API:** [http://localhost:11434](http://localhost:11434)

---

## 🔌 4. Integración y Emulación como OpenAI

Ollama incluye emulación directa de la **OpenAI API**. Cualquier SDK o herramienta (como **n8n**, scripts en Python o Node.js) puede conectarse apuntando a la URL base de Ollama:

### Conexión desde el Host (tu máquina)
- **Base URL:** `http://localhost:11434/v1`
- **API Key:** `ollama` (o cualquier texto, no se valida)
- **Model:** `llama3.2:3b`

### Conexión desde otros contenedores en la red `core_dev_network` (ej. n8n)
- **Base URL:** `http://core_ollama:11434/v1`
- **API Key:** `ollama`
- **Model:** `llama3.2:3b`

### Ejemplo con `curl`:
```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ollama" \
  -d '{
    "model": "llama3.2:3b",
    "messages": [
      {"role": "user", "content": "¿Cuál es la capital de Francia? Responde en una sola palabra."}
    ],
    "temperature": 0.2
  }'
```

---

## 🛑 5. Detener o Limpiar

```bash
# Pausar contenedores sin borrar datos
make ai down

# O usando el comando global
make stop
```
