# SOC Auto-Reporter 360

Herramienta para **analistas SOC y Blue Team** que convierte informes Nmap (`-oX`) en:

- Un **dashboard visual** en HTML con:
  - Hosts UP / DOWN
  - Tabla de hosts y puertos
  - Informe rápido en **Markdown** listo para pegar en un ticket del SOC
- Un flujo automatizado desde un **script Nmap en Bash** (`nmap_suite.sh`) que:
  - Lanza el escaneo
  - Genera el informe técnico clásico en HTML
  - Envía el XML al backend FastAPI
  - Abre el dashboard HTML estático generado

Desarrollado por **Nacho Menárguez Fernández – Menarguez-IA-Solutions**.

---

## 🧩 Arquitectura

- **Backend API**: FastAPI  
  Endpoint `/api/v1/nmap/upload` que recibe el XML (`multipart/form-data`) y devuelve un resumen JSON.

- **Dashboard**:  
  Ruta `/dashboard` (Jinja2 + HTML + CSS) donde se muestran:
  - Hosts UP / DOWN
  - Tabla de puertos por host
  - Informe rápido en Markdown

- **Script Bash**: `scripts/nmap_suite.sh`  
  Menú interactivo que:
  - Ejecuta distintos tipos de escaneo Nmap
  - Guarda XML/LOG
  - Genera informe técnico HTML clásico
  - Llama al backend, guarda `dashboard_soc.html` y lo abre en el navegador.

---

## 🚀 Requisitos

### Backend (FastAPI)

- Python 3.10+
- Entorno virtual recomendado

Instalación:

```bash
pip install -r requirements.txt

## 🚀 Quickstart

```bash
# 1) Clonar el repo
git clone https://github.com/Nachomf112/soc-auto-reporter-360.git
cd soc-auto-reporter-360

# 2) Crear entorno virtual e instalar dependencias
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 3) Arrancar el backend
cd backend
uvicorn app.main:app --reload

