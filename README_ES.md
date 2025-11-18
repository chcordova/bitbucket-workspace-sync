# Bitbucket Workspace Sync (Español)

[![Licencia: MIT](https://img.shields.io/badge/Licencia-MIT-yellow.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)

> 🚀 CLI de alto rendimiento para clonar/actualizar todos los repositorios de un workspace de Bitbucket Cloud en paralelo

[📖 English](README.md) | [📚 Documentación Completa](docs/README_FULL_ES.md)

---

## ✨ Características Principales

- 🔄 **Paralelismo Adaptativo**: Ajuste automático ante rate limiting
- 📊 **Métricas Avanzadas**: Estadísticas, health score, comparación histórica
- 🚀 **5-10x Más Rápido**: Modo shallow clone con flag `-s`
- 📈 **Múltiples Formatos**: Export a JSON, CSV, HTML, Markdown
- 🔔 **Alertas**: Integración con Slack/Teams
- 🪟 **Compatible Windows**: Soporte automático para rutas largas

---

## 🚀 Inicio Rápido

```bash
# 1. Descargar
curl -O https://raw.githubusercontent.com/chcordova/bitbucket-workspace-sync/master/bitbucket-workspace-sync.sh
chmod +x bitbucket-workspace-sync.sh

# 2. Configurar credenciales
export BB_USERNAME="tu_usuario"
export BB_APP_PASSWORD="tu_app_password"
export BB_WORKSPACE="tu_workspace"

# 3. Ejecutar
./bitbucket-workspace-sync.sh -j 4 -v
```

### Modo Rápido con Métricas
```bash
# Shallow clone (rápido) con métricas detalladas
./bitbucket-workspace-sync.sh -j 6 -v -s -D
```

---

## ⚙️ Uso

```bash
./bitbucket-workspace-sync.sh [opciones]

Opciones principales:
  -w, --workspace <id>   ID del workspace
  -j, --jobs <n>         Procesos paralelos (default: 4)
  -v, --verbose          Mostrar progreso por repo
  -s, --shallow          Shallow clone (5-10x más rápido)
  -D, --detailed         Generar métricas detalladas
  --format <fmt>         Formato: json|csv|html|markdown
  -h, --help             Mostrar ayuda
```

### Ejemplos Comunes

| Caso de Uso | Comando |
|-------------|---------|
| Clone/update básico | `./bitbucket-workspace-sync.sh -j 4 -v` |
| Shallow rápido | `./bitbucket-workspace-sync.sh -j 6 -v -s -D` |
| Export a CSV | `./bitbucket-workspace-sync.sh -D --format csv` |
| Dry-run (prueba) | `./bitbucket-workspace-sync.sh -n -v` |

---

## 📊 Rendimiento

Resultados reales con workspace de 347 repos:

| Modo | Tiempo | Mejora |
|------|--------|--------|
| **Clone Completo** | ~92 min | 1x |
| **Shallow Clone** (`-s`) | ~12 min | **7.6x más rápido** |

---

## 📋 Requisitos

| Herramienta | Versión |
|-------------|---------|
| **Bash** | ≥ 4.0 |
| **git** | cualquiera |
| **curl** | cualquiera |
| **jq** | cualquiera |

### Instalación Rápida

```bash
# macOS
brew install bash git curl jq

# Ubuntu/Debian
sudo apt-get install bash git curl jq

# Windows: Usar Git Bash + descargar jq
```

Ver [guía de instalación completa](docs/INSTALLATION.md)

---

## 🔐 Configuración de Credenciales

```bash
# Método 1: Variables de entorno
export BB_USERNAME="tu_usuario"
export BB_APP_PASSWORD="tu_app_password"
export BB_WORKSPACE="tu_workspace"

# Método 2: Archivo de credenciales
cp examples/credentials.example.txt credentials.txt
# Edita credentials.txt
source credentials.txt
```

**Crear App Password:**
1. Bitbucket → Settings → App passwords
2. Create app password
3. Seleccionar: `repository:read`
4. Copiar el password generado

---

## 📚 Documentación

- [📖 Guía de Instalación](docs/INSTALLATION.md)
- [📚 Documentación Completa](docs/README_FULL_ES.md)
- [🚀 Uso Avanzado](docs/ADVANCED_USAGE.md)
- [🔧 Solución de Problemas](docs/TROUBLESHOOTING.md)
- [📝 Changelog](CHANGELOG.md)

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Ver [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📜 Licencia

MIT © 2025 - Ver [LICENSE](LICENSE)

---

## 📞 Soporte

- 🐛 Reportar bugs: [Abrir issue](../../issues)
- 💡 Solicitar features: [Abrir issue](../../issues)
- 📖 [Documentación completa](docs/README_FULL_ES.md)

---

<div align="center">

### 👨‍💻 Desarrollado por Charles Córdova

[![GitHub](https://img.shields.io/badge/GitHub-chcordova-181717?style=flat&logo=github)](https://github.com/chcordova)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=flat&logo=linkedin)](https://linkedin.com/in/charlescordova)

Si este proyecto te resulta útil, considera darle una⭐

[🐛 Reportar Bug](../../issues) • [✨ Solicitar Feature](../../issues) • [💬 Discusiones](../../discussions)

</div>