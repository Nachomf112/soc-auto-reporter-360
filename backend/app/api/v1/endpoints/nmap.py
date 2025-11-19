from fastapi import APIRouter, UploadFile, File, HTTPException

from app.services.nmap_parser import parse_nmap_xml
from app.models.nmap_models import NmapSummary

router = APIRouter()


@router.post("/upload", response_model=NmapSummary, tags=["nmap"])
async def upload_nmap_scan(file: UploadFile = File(...)):
    """
    Sube un fichero XML de Nmap (-oX) y devuelve un resumen:
    - hosts up / down
    - hosts con sus puertos abiertos/cerrados
    """
    if not file.filename.lower().endswith(".xml"):
        raise HTTPException(
            status_code=400,
            detail="Por ahora solo acepto ficheros Nmap XML (.xml).",
        )

    content = await file.read()

    try:
        summary = parse_nmap_xml(content)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=400,
            detail=f"Error al parsear el XML de Nmap: {exc}",
        ) from exc

    return summary
