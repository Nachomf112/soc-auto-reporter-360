# backend/app/services/markdown_export.py

from app.models.nmap_models import NmapSummary


def build_markdown_report(summary: NmapSummary) -> str:
    """
    Genera un informe en Markdown a partir del NmapSummary.
    Pensado para pegarlo directamente en un ticket del SOC.
    """
    lines: list[str] = []

    lines.append("# Informe rápido Nmap - SOC Auto-Reporter 360\n")
    lines.append(f"- Hosts UP: **{summary.hosts_up}**")
    lines.append(f"- Hosts DOWN: **{summary.hosts_down}**\n")

    for host in summary.hosts:
        host_title = host.hostname or host.ip
        lines.append(f"## Host {host_title} ({host.ip})")
        lines.append("")
        lines.append("| Puerto | Protocolo | Servicio | Estado |")
        lines.append("|-------:|----------|----------|--------|")

        for p in host.ports:
            service = p.service or "-"
            lines.append(f"| {p.port} | {p.protocol} | {service} | {p.state} |")

        lines.append("")  # línea en blanco entre hosts

    return "\n".join(lines)
