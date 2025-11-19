from fastapi import FastAPI, Request, UploadFile, File
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from .core.config import settings
from .api.v1.endpoints import health, nmap

app = FastAPI(title=settings.PROJECT_NAME)

# Templates y estáticos para el dashboard
# (rutas relativas al directorio "backend" desde donde lanzas uvicorn)
templates = Jinja2Templates(directory="app/templates")
app.mount("/static", StaticFiles(directory="app/static"), name="static")

# Rutas API (JSON)
app.include_router(health.router, prefix=settings.API_V1_STR)
app.include_router(nmap.router, prefix=settings.API_V1_STR + "/nmap")


# Root JSON
@app.get("/")
async def root():
    return {
        "message": "SOC Auto-Reporter 360 API",
        "api_docs": "/docs",
        "health": f"{settings.API_V1_STR}/health",
    }


# Dashboard bonito (GET: muestra página vacía)
@app.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request):
    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "scan": None,
            "markdown": None,   # <- aún no hay informe
        },
    )


# Dashboard (POST: recibe XML, lo parsea y pinta resultados)
@app.post("/dashboard", response_class=HTMLResponse)
async def dashboard_upload(request: Request, file: UploadFile = File(...)):
    # imports locales para evitar problemas de rutas/ciclos
    from .services.nmap_parser import parse_nmap_xml
    from .services.markdown_export import build_markdown_report

    # Leemos el XML subido
    content = await file.read()

    # Parseamos el XML a nuestro modelo NmapSummary
    summary = parse_nmap_xml(content)

    # Generamos el informe Markdown
    markdown = build_markdown_report(summary)

    # Renderizamos el dashboard con datos + informe Markdown
    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "scan": summary,
            "markdown": markdown,
        },
    )
