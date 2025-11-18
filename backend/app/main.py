from fastapi import FastAPI

from .core.config import settings
from .api.v1.endpoints import health


app = FastAPI(title=settings.PROJECT_NAME)


# Rutas
app.include_router(health.router, prefix=settings.API_V1_STR)


@app.get("/")
async def root():
    return {
        "message": "SOC Auto-Reporter 360 API",
        "api_docs": "/docs",
        "health": f"{settings.API_V1_STR}/health",
    }
