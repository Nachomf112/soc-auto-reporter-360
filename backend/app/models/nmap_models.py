from typing import List, Optional

from pydantic import BaseModel


class PortInfo(BaseModel):
    port: int
    protocol: str
    service: Optional[str] = None
    state: str


class HostSummary(BaseModel):
    ip: str
    hostname: Optional[str] = None
    ports: List[PortInfo] = []


class NmapSummary(BaseModel):
    hosts_up: int
    hosts_down: int
    hosts: List[HostSummary]


class NmapSummaryWithMarkdown(NmapSummary):
    """Extiende el resumen normal añadiendo el informe en Markdown."""
    markdown: str
