
# Bitbucket Workspace Sync

`bitbucket-workspace-sync.sh` es un **CLI avanzado** en Bash que clona **o** actualiza en paralelo todos los repositorios de un *workspace* de **Bitbucket Cloud** con optimizaciones de rendimiento y reportes detallados.

---

## ✨ Funciones clave

### 🚀 **Performance & Optimización**
* **Adaptive Parallelism**: Ajuste dinámico de workers ante rate limiting (HTTP 429)
* **HTTP/2 con keepalive**: Conexiones persistentes para reducir latencia
* **Caché de metadata**: Almacena lista de repos por 1 hora (evita llamadas API repetidas)
* **Priorización por tamaño**: Clona repos pequeños primero para feedback rápido
* **Git optimizado**: Partial clone (`--filter=blob:none`), sin compresión, buffers grandes
* **Shallow clone opcional**: Flag `-s` para clonar solo último commit (5-10x más rápido)

### 📊 **Reporting & Métricas**
* **Dashboard en tiempo real**: Archivo `.clone_progress` actualizado en vivo
* **Estadísticas avanzadas**: Min/Max/Avg/Median/StdDev de tiempos de clonación
* **Health Score**: Evaluación 0-100 del estado del workspace
* **Clasificación por categorías**: Agrupa repos por prefijo (theshire-, rivendell-, etc.)
* **Top N repos lentos**: Identifica cuellos de botella
* **Comparación histórica**: Compara rendimiento con ejecución anterior
* **Múltiples formatos**: Export a JSON, CSV, HTML, Markdown

### 🔔 **Alertas & Notificaciones**
* **Webhooks**: Integración con Slack/Microsoft Teams
* **Alertas inteligentes**: Notifica solo si errores >= umbral configurable
* **Niveles de severidad**: Info, Warning, Error con colores apropiados

### 🛠 **Core Features**
* Obtiene la lista completa de repos vía **API v2** (paginada)
* **Clona** los repos faltantes y **actualiza** los existentes con `git fetch && git merge --ff-only`
* Detecta *working tree* sucia (regex de exclusión configurable)
* Ejecución paralela controlada por `--jobs` (`xargs -P`)
* **Salida limpia por defecto**: sólo un resumen final  
  Activa `-v / --verbose` para ver el progreso repo‑a‑repo
* **Dry‑run**, métricas **JSON** opcionales (compactas `-m` o detalladas `-D`)
* **Compatibilidad Windows**: Configura automáticamente `core.longpaths` para rutas largas
* Manejo seguro del directorio de trabajo (evita errores `getcwd`)
* Todo en un único archivo Bash (requiere Bash ≥ 4.0)

---

## 📋 Requisitos mínimos

| Herramienta | Versión |
|-------------|---------|
| **Bash** | ≥ 4.0 |
| **git**  | cualquiera |

### ⚠️ Nota para Windows

El script configura automáticamente `git config --global core.longpaths true` para evitar errores como:
```
error: unable to create file ...: Filename too long
```

Si el script no puede configurarlo automáticamente, ejecútalo manualmente:
```bash
git config --global core.longpaths true
```
| **curl** | cualquiera |
| **jq**   | cualquiera |

### Instalación rápida

```bash
# macOS (Homebrew)
brew install bash git curl jq

# Debian / Ubuntu
sudo apt-get update && sudo apt-get install bash git curl jq
```

---

## 🚀 Primeros pasos

```bash
# Hazlo ejecutable
chmod +x bitbucket-workspace-sync.sh

# Clona/actualiza con 4 hilos y salida verbose
export BB_USERNAME="usuario"
export BB_APP_PASSWORD="app_password"

./bitbucket-workspace-sync.sh \
  -w <my_workspace> \
  -j 4 -v
```

> Ejecuta `./bitbucket-workspace-sync.sh -h` para ver la ayuda integrada.

---

## ⚙️ Flags / opciones

### Opciones Básicas
| Largo | Corto | Argumento | Valor por defecto | Descripción |
|-------|-------|-----------|-------------------|-------------|
| `--workspace` | `-w` | `<id>` | *(env `BB_WORKSPACE`)* | ID del workspace. |
| `--dir` | `-d` | `<ruta>` | `pwd/<workspace>` | Carpeta destino. |
| `--jobs` | `-j` | `<n>` | `4` | Procesos paralelos. |
| `--verbose` | `-v` | – | `false` | Muestra progreso repo‑a‑repo (**stderr**). |
| `--dry-run` | `-n` | – | `false` | Modo simulación; no ejecuta `git`. |
| `--help` | `-h` | – | – | Muestra ayuda y sale. |

### Optimización de Performance
| Largo | Corto | Argumento | Valor por defecto | Descripción |
|-------|-------|-----------|-------------------|-------------|
| `--shallow` | `-s` | – | `false` | Shallow clone (solo último commit, 5-10x más rápido). |
| `--no-adaptive` | – | – | `false` | Desactiva adaptive parallelism (auto-reduce workers). |

### Métricas y Reportes
| Largo | Corto | Argumento | Valor por defecto | Descripción |
|-------|-------|-----------|-------------------|-------------|
| `--metrics` | `-m` | – | `false` | Genera JSON compacto de métricas. |
| `--detailed` | `-D` | – | `false` | Métrica detallada con estadísticas (implica `--metrics`). |
| `--no-metrics` | – | – | **activado** | Desactiva métricas. |
| `--format` | – | `<fmt>` | `json` | Formato de export: `json`, `csv`, `html`, `markdown`. |

### Alertas y Notificaciones
| Largo | Corto | Argumento | Valor por defecto | Descripción |
|-------|-------|-----------|-------------------|-------------|
| `--webhook` | – | `<url>` | *(env `BB_ALERT_WEBHOOK`)* | Webhook URL para alertas (Slack/Teams). |

### Configuración Avanzada
| Largo | Corto | Argumento | Valor por defecto | Descripción |
|-------|-------|-----------|-------------------|-------------|
| `--ignore` | `-i` | "`<regex>`" | Ver *Default ignore* ↓ | Regex para ignorar cambios locales. |

### *Default ignore*

```regex
\.DS_Store$|\.idea/|\.vscode/|\.classpath$|\.project$|\.settings/
```

—


## 🖥️ Ejemplos de uso

### Uso Básico
| Caso | Comando |
|------|---------|
| Clonado inicial | `./bitbucket-workspace-sync.sh -w myteam -d ~/code/myteam` |
| Ejecución en CI (silencioso) | `./bitbucket-workspace-sync.sh -j 8` |
| Dry‑run | `./bitbucket-workspace-sync.sh -n -v` |
| Carpeta destino distinta | `./bitbucket-workspace-sync.sh -d /srv/repos` |

### Performance Optimizado
| Caso | Comando |
|------|---------|
| **Clone rápido (shallow)** | `./bitbucket-workspace-sync.sh -w myteam -j 4 -v -s` |
| Con adaptive parallelism | `./bitbucket-workspace-sync.sh -w myteam -j 6 -v -s -D` |
| Sin adaptive (forzar workers) | `./bitbucket-workspace-sync.sh -j 8 --no-adaptive` |

### Métricas y Reportes
| Caso | Comando |
|------|---------|
| Métricas compactas JSON | `./bitbucket-workspace-sync.sh -m` |
| **Métricas detalladas** (recomendado) | `./bitbucket-workspace-sync.sh -D` |
| Export a CSV | `./bitbucket-workspace-sync.sh -D --format csv` |
| Export a HTML | `./bitbucket-workspace-sync.sh -D --format html` |
| Export a Markdown | `./bitbucket-workspace-sync.sh -D --format markdown` |

### Alertas y Monitoreo
| Caso | Comando |
|------|---------|
| Con alertas a Slack | `./bitbucket-workspace-sync.sh -D --webhook https://hooks.slack.com/...` |
| Con alertas a Teams | `./bitbucket-workspace-sync.sh -D --webhook https://outlook.office.com/...` |
| Verificar archivo de progreso existe | `ls -la \| grep clone` |
| Monitorear progreso en vivo (Linux/macOS) | `watch -n1 cat ./myteam/.clone_progress` |
| Monitorear progreso en vivo (Git Bash/Windows) | `while true; do clear; cat .clone_progress 2>/dev/null \|\| echo "Esperando archivo..."; sleep 1; done` |

### Avanzado
| Caso | Comando |
|------|---------|
| Regex de exclusión personalizada | `./bitbucket-workspace-sync.sh -i ".log$\|/target/"` |
| Todo optimizado + HTML report | `./bitbucket-workspace-sync.sh -w myteam -j 4 -v -s -D --format html` |

---

## 🔐 Credenciales

Antes de ejecutar, exporta:

```bash
export BB_USERNAME="tu_usuario"
export BB_APP_PASSWORD="tu_app_password"
export BB_WORKSPACE="mi_workspace"   # opcional si usas -w
```

Variables opcionales:

| Variable | Propósito |
|----------|-----------|
| `BB_IGNORE_PATTERN` | Sobrescribe el regex de exclusión. |
| `BB_ALERT_WEBHOOK` | URL del webhook para alertas (Slack/Teams). |

---

## 🔄 Lógica de actualización

1. **No existe la carpeta** → `git clone`.
2. Existe pero **no es repo Git** → se renombra y se clona de nuevo.
3. *Working tree* sucia → **omitido**.
4. Detecta rama principal (`origin/HEAD`, `main`, `master`).
5. `git fetch` + `git merge --ff-only`.  
   *Sin cambio en HEAD* → **unchanged**; si avanza → **updated**.

---

## 📊 Métricas JSON

### Compactas (`-m`)
```json
{
  "timestamp": "2025-11-14T22:51:52Z",
  "workspace": "myteam",
  "total": 347,
  "cloned": 12,
  "updated": 25,
  "clean": 308,
  "dirty": 2,
  "errors": 0,
  "duration_sec": 845
}
```

### Detalladas (`-D`) - Incluye Estadísticas Avanzadas
```json
{
  "timestamp": "2025-11-14T22:51:52Z",
  "workspace": "myteam",
  "totals": {
    "cloned": 12,
    "updated": 25,
    "unchanged": 308,
    "dirty": 2,
    "skipped": 0,
    "errors": 0
  },
  "duration_sec": 845,
  "timing_stats": {
    "min_sec": 18,
    "max_sec": 402,
    "avg_sec": 95,
    "median_sec": 52,
    "std_dev": 78.5,
    "slowest_repos": [
      {"repo": "theshire-accounts", "sec": 402},
      {"repo": "theshire-customers", "sec": 397},
      {"repo": "rivendell-commons", "sec": 349}
    ]
  },
  "categories": {
    "theshire": 145,
    "rivendell": 89,
    "devops": 56
  },
  "health_score": 96,
  "repos": [
    {"repo": "devops-java", "result": "CLONED", "sec": 43},
    {"repo": "theshire-gates", "result": "UPDATED", "sec": 39}
  ]
}
```

### Formatos Adicionales

**CSV** (`--format csv`): Importable en Excel/Google Sheets  
**HTML** (`--format html`): Report visual con gráficos  
**Markdown** (`--format markdown`): Documentación legible

---

## 🛠 Solución de problemas

| Síntoma | Solución |
|---------|----------|
| `HTTP 401/403` | Verifica usuario/app‑password y scopes (`repository:read`). |
| `HTTP 429` (rate limit) | El script ajusta workers automáticamente. Si persiste, reduce `-j`. |
| `fatal: not a git repository` | Carpeta corrupta; el script la renombra y reclona. |
| Repos siguen *dirty* | Ajusta `--ignore` o limpia tus cambios. |
| `mapfile: command not found` | Bash 3 (macOS); instala Bash 4 (`brew install bash`). |
| `getcwd: Operation not permitted` | Ejecutaste en carpeta sin permisos; el script hace `cd` seguro. |
| Clones muy lentos | Usa `-s` (shallow) o reduce `-j` para evitar throttling. |
| Cache desactualizado | Elimina `.repo_cache.json` para forzar refresh. |
| Webhook no funciona | Verifica formato URL (Slack vs Teams tienen formatos distintos). |

## 🔍 Monitoreo y Debugging

### Ver progreso en tiempo real
```bash
# En una terminal separada
watch -n1 cat /ruta/workspace/.clone_progress
```

### Analizar repos lentos
```bash
# Ver top 10 más lentos del último reporte
jq '.timing_stats.slowest_repos' clone_metrics-*.json
```

### Comparar rendimiento histórico
```bash
# El script compara automáticamente con ejecución anterior
# Busca archivos: clone_metrics-*.json
```

---

## 📜 Licencia

Publicado bajo la **licencia MIT**.  
¡Úsalo, compártelo y envía PRs! 🙌
