# SOC Auto-Reporter 360

Herramienta de **Blue Team** para analizar resultados de **Nmap** y logs de autenticación (`auth.log`),
obtener métricas rápidas de exposición y ataques, y generar un **informe ejecutivo** listo para pegar
en un ticket de SOC o presentar a dirección.

Proyecto pensado para:

- Uso en **hackathons** de ciberseguridad / IA.
- Portfolio técnico de **Ignacio Menárguez (Menarguez-IA-Solutions)**.
- Base para futuras integraciones con IA y dashboards más avanzados.

---

## 🧩 Funcionalidades previstas

Versión inicial:

- API en **Python + FastAPI**.
- Endpoint de salud (`/api/v1/health`).
- Módulos para:
  - Analizar resultados de Nmap (XML/gnmap).
  - Analizar `auth.log` (intentos fallidos, usuarios atacados, logins OK).
  - Generar informes HTML con estructura ejecutiva.

Roadmap:

- ✔️ Estructura de proyecto y API base.
- ⏳ Parseo de Nmap y `auth.log`.
- ⏳ Plantillas HTML para informes.
- ⏳ Integración con IA (resumen ejecutivo y priorización de riesgos).
- ⏳ Exportación a PDF / Markdown.

---

## 🛠️ Tecnologías

- **Backend**: FastAPI, Pydantic, pydantic-settings.
- **Servidor ASGI**: Uvicorn.
- **Lenguaje**: Python 3.11+.
- **Infraestructura prevista**: despliegue sencillo en contenedor o VM.

---

## 📂 Estructura del proyecto

La estructura detallada está en [`STRUCTURE.md`](./STRUCTURE.md), pero a alto nivel:

```text
backend/     # API (FastAPI) y lógica de negocio
data/        # Datos de ejemplo (Nmap, auth.log)
reports/     # Informes generados (HTML, Markdown, PDF)
docs/        # Documentación (arquitectura, endpoints, notas de hackathon)
frontend/    # (Opcional) UI separada si se desarrolla más adelante
