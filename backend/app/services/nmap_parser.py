import xml.etree.ElementTree as ET

from app.models.nmap_models import NmapSummary, HostSummary, PortInfo


def parse_nmap_xml(xml_bytes: bytes) -> NmapSummary:
    """
    Parsea un fichero XML de Nmap (-oX) y devuelve un resumen estructurado.
    """
    root = ET.fromstring(xml_bytes)

    hosts: list[HostSummary] = []
    hosts_up = 0
    hosts_down = 0

    for host in root.findall("host"):
        status_el = host.find("status")
        state = status_el.get("state") if status_el is not None else "unknown"

        if state == "up":
            hosts_up += 1
        else:
            hosts_down += 1

        # IP
        addr_el = host.find("address[@addrtype='ipv4']")
        if addr_el is None:
            addr_el = host.find("address[@addrtype='ipv6']")

        ip = addr_el.get("addr") if addr_el is not None else "unknown"

        # Hostname
        hostname_el = host.find("hostnames/hostname")
        hostname = hostname_el.get("name") if hostname_el is not None else None

        # Puertos
        ports_list: list[PortInfo] = []
        ports_el = host.find("ports")
        if ports_el is not None:
            for port_el in ports_el.findall("port"):
                port_id = int(port_el.get("portid"))
                protocol = port_el.get("protocol")

                state_el = port_el.find("state")
                port_state = (
                    state_el.get("state") if state_el is not None else "unknown"
                )

                service_el = port_el.find("service")
                service_name = (
                    service_el.get("name") if service_el is not None else None
                )

                ports_list.append(
                    PortInfo(
                        port=port_id,
                        protocol=protocol,
                        service=service_name,
                        state=port_state,
                    )
                )

        hosts.append(
            HostSummary(
                ip=ip,
                hostname=hostname,
                ports=ports_list,
            )
        )

    # Ajustar con runstats si hace falta
    runstats = root.find("runstats")
    if runstats is not None:
        hosts_el = runstats.find("hosts")
        if hosts_el is not None:
            hosts_up = int(hosts_el.get("up", hosts_up))
            hosts_down = int(hosts_el.get("down", hosts_down))

    return NmapSummary(
        hosts_up=hosts_up,
        hosts_down=hosts_down,
        hosts=hosts,
    )


def generate_nmap_markdown(summary: NmapSummary) -> str:
    """
    Genera un informe en Markdown a partir del resumen NmapSummary.
    Listo para pegar en un ticket del SOC.
    """
    lines: list[str] = []

    # Cabecera
    lines.append("# Informe rápido Nmap - SOC Auto-Reporter 360\n")
    lines.append(f"- Hosts UP: **{summary.hosts_up}**")
    lines.append(f"- Hosts DOWN: **{summary.hosts_down}**\n")

    # Detalle por host
    for host in summary.hosts:
        titulo_host = host.hostname or host.ip
        lines.append(f"## Host {titulo_host} ({host.ip})\n")
        lines.append("| Puerto | Protocolo | Servicio | Estado |")
        lines.append("|--------|-----------|----------|--------|")

        for p in host.ports:
            service = p.service or "-"
            lines.append(
                f"| {p.port} | {p.protocol} | {service} | {p.state} |"
            )

        lines.append("")  # línea en blanco entre hosts

    return "\n".join(lines)
