#!/bin/bash

# ======================================================================
#  Suite Nmap Automatizada + SOC Auto-Reporter 360
#  Autor: Nacho Menárguez Fernández - Menarguez-IA-Solutions
# ======================================================================

# 🔐 Rutas seguras
if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    BASE_DIR="/home/$SUDO_USER/nacho/scripts"
else
    BASE_DIR="$HOME/nacho/scripts"
fi

INFORMES_DIR="$BASE_DIR/informes"
mkdir -p "$INFORMES_DIR"

# URL del backend SOC Auto-Reporter 360 (FastAPI)
BACKEND_URL="http://127.0.0.1:8000"

# 🎨 Estilos
verde="\e[32m"; rojo="\e[31m"; azul="\e[34m"; amarillo="\e[33m"; negrita="\e[1m"; reset="\e[0m"

# ======================================================================
#  Cabecera
# ======================================================================
mostrar_cabecera() {
    clear
    fecha=$(date "+%A %d de %B del %Y" | sed 's/^./\U&/')
    echo -e "${negrita}${azul}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       Bienvenido a la Suite Nmap Automatización            ║"
    echo "║       Empresa: Menarguez-IA-Solutions                      ║"
    echo "║       Desarrollador: Nacho Menarguez Fernández             ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo -e "║       📅 Fecha de hoy: ${amarillo}$fecha${azul}"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${reset}"
    sleep 1
}

# ======================================================================
#  Utilidades Nmap
# ======================================================================

usar_Pn=true
nivel_timing="-T3"
host_timeout=""

detectar_red() {
    ip -4 addr | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v ^127 | head -n 1
}

resolver_ip() {
    if [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo "$1"
    else
        getent hosts "$1" | awk '{print $1}'
    fi
}

generar_args() {
    args="-sT $nivel_timing -p $1"
    $usar_Pn && args+=" -Pn"
    [ -n "$host_timeout" ] && args+=" --host-timeout $host_timeout"
    echo "$args"
}

# ======================================================================
#  Dashboard histórico (HTML clásico)
# ======================================================================

actualizar_index() {
    local index="$INFORMES_DIR/index.html"
    cat <<EOF > "$index"
<!DOCTYPE html>
<html lang='es'>
<head>
    <meta charset='UTF-8'>
    <title>Dashboard de Informes Nmap</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #eef2f5;
            margin: 0;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        header {
            background-color: #2980b9;
            color: #fff;
            padding: 20px;
            width: 100%;
            text-align: center;
            margin-bottom: 20px;
        }
        table {
            width: 80%;
            border-collapse: collapse;
            margin-bottom: 20px;
            background-color: #ffffff;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 12px 15px;
            text-align: center;
        }
        th {
            background-color: #2980b9;
            color: #fff;
        }
        tr:nth-child(even) {background-color: #f9f9f9;}
        tr:hover {background-color: #f1f1f1;}
        a {
            color: #3498db;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .footer {
            margin-top: 20px;
            font-size: 0.9em;
            text-align: center;
            color: #888;
        }
    </style>
</head>
<body>
    <header>
        <h1>Dashboard de Informes Nmap</h1>
        <p><strong>Menarguez-IA-Solutions</strong> desarrollado por <strong>Nacho Menarguez Fernández</strong></p>
    </header>
    <table>
        <thead>
            <tr>
                <th>Fecha</th>
                <th>Tipo</th>
                <th>Destino</th>
                <th>Script</th>
                <th>Informe</th>
            </tr>
        </thead>
        <tbody>
EOF

    for folder in "$INFORMES_DIR"/escaneo_*; do
        resumen="$folder/resumen.txt"
        [ -f "$resumen" ] || continue
        fecha=$(grep "Fecha:" "$resumen" | cut -d':' -f2-)
        tipo=$(grep "Tipo de escaneo" "$resumen" | cut -d':' -f2-)
        destino=$(grep "Destino" "$resumen" | cut -d':' -f2-)
        script=$(grep "Script NSE usado" "$resumen" | cut -d':' -f2-)
        html_relativo="$(basename "$folder")/resultado.html"
        echo "<tr><td>$fecha</td><td>$tipo</td><td>$destino</td><td>$script</td>
        <td><a href=\"$html_relativo\">Ver</a></td></tr>" >> "$index"
    done

    cat <<EOF >> "$index"
        </tbody>
    </table>

<h2>🛡️ Mitigaciones Recomendadas</h2>
<ul>
  <li><strong>HTTP/HTTPS:</strong> Verifica certificados SSL, actualiza el servidor web, y aplica encabezados de seguridad.</li>
  <li><strong>FTP:</strong> Evita FTP en texto plano, utiliza SFTP o FTPS.</li>
  <li><strong>MySQL:</strong> Restringe accesos remotos, usa contraseñas fuertes y roles mínimos necesarios.</li>
  <li><strong>MSRPC:</strong> Limita el acceso desde redes externas, habilita firewalls y segmentación de red.</li>
  <li><strong>SMB:</strong> Desactiva versiones antiguas como SMBv1, aplica parches de seguridad.</li>
  <li><strong>Puertos Abiertos:</strong> Cierra todos los que no sean estrictamente necesarios.</li>
</ul>

    <div class='footer'>
        Menarguez-IA-Solutions &copy; $(date +%Y) | Desarrollado por Nacho Menarguez Fernández
    </div>
</body>
</html>
EOF
}

# ======================================================================
#  Enviar XML al backend SOC y generar dashboard SOC local
# ======================================================================

enviar_xml_a_dashboard() {
    local xml="$1"
    local out_html="$2"
    local tmp_html="${out_html}.tmp"

    echo -e "${azul}→ Enviando XML al backend SOC Auto-Reporter 360...${reset}"

    # Llamada al endpoint /dashboard (FastAPI debe estar levantado)
    if ! curl -s -X POST -F "file=@${xml}" "$BACKEND_URL/dashboard" -o "$tmp_html"; then
        echo -e "${rojo}✖ Error al llamar a la API del dashboard.${reset}"
        rm -f "$tmp_html"
        return 1
    fi

    # Usamos Python para incrustar el CSS dentro del HTML (inline),
    # así el fichero se ve perfecto aunque se abra como file://
    python3 - "$tmp_html" "$out_html" "$BACKEND_URL/static/css/style.css" << 'PY'
import sys, pathlib, urllib.request, re

tmp, out, css_url = sys.argv[1:4]
tmp_path = pathlib.Path(tmp)
out_path = pathlib.Path(out)

html = tmp_path.read_text(encoding="utf-8", errors="ignore")

css = ""
try:
    with urllib.request.urlopen(css_url, timeout=5) as resp:
        css = resp.read().decode("utf-8", errors="ignore")
except Exception:
    css = ""

if css:
    style_block = "<style>\n" + css + "\n</style>\n"
    pattern = r'<link[^>]+href="/static/css/style.css"[^>]*>\s*'
    if re.search(pattern, html):
        html = re.sub(pattern, style_block, html, count=1)
    else:
        html = html.replace("</head>", style_block + "</head>")

out_path.write_text(html, encoding="utf-8")
PY

    rm -f "$tmp_html"

    if [ -s "$out_html" ]; then
        echo -e "${verde}✔ Dashboard SOC creado en: $out_html${reset}"
        xdg-open "$out_html" 2>/dev/null || \
            echo -e "${amarillo}ℹ No se pudo abrir el navegador automáticamente.${reset}"
    else
        echo -e "${rojo}✖ El dashboard SOC generado está vacío.${reset}"
    fi
}

# ======================================================================
#  Informe técnico detallado por escaneo
# ======================================================================

generar_tabla_puertos() {
  local xml="$1"
  awk '
    /<host>/ {ip=""}
    /<address addr="/ {match($0, /addr=\"([^\"]+)\"/, m); ip=m[1]}
    /<port protocol=/ {
      match($0, /portid=\"([0-9]+)\"/, p)
      match($0, /protocol=\"([a-z]+)\"/, proto)
      getline; getline; getline
      match($0, /name=\"([^\"]+)\"/, svc)
      print "<tr><td>" ip "</td><td>" p[1] "/" proto[1] "</td><td>open</td><td>" svc[1] "</td></tr>"
    }
  ' "$xml"
}

generar_informe() {
    local tipo="$1"; local destino="$2"; local script="$3"; local xml="$4"; local log="$5"; local tiempo="$6"

    timestamp=$(date +%Y-%m-%d_%H-%M-%S)
    folder="$INFORMES_DIR/escaneo_$timestamp"
    mkdir -p "$folder"
    mv "$xml" "$folder/resultado.xml"
    [ -f "$log" ] && mv "$log" "$folder/log.txt"

    abiertos=$(grep -c 'state state="open"' "$folder/resultado.xml" 2>/dev/null || echo 0)
    rtt_detectado=$(grep -q "RTTVAR has grown" "$folder/log.txt" 2>/dev/null && echo "Sí" || echo "No")

    os_detections=$(grep -oP '<osmatch name="\K[^"]+' "$folder/resultado.xml" 2>/dev/null | head -n 1)
    [ -z "$os_detections" ] && os_detections="No detectados"

    servicios_detections=$(grep -oP '<service name="\K\w+' "$folder/resultado.xml" 2>/dev/null | sort | uniq | paste -sd "," -)

    cat <<EOF > "$folder/resultado.html"
<!DOCTYPE html>
<html lang='es'>
<head>
  <meta charset='UTF-8'>
  <title>Informe Técnico - Escaneo Nmap</title>
  <style>
    body {
      font-family: 'Segoe UI', sans-serif;
      background: #f4f4f9;
      margin: 0;
      padding: 0 20px;
    }
    header {
      background: #2c3e50;
      color: white;
      padding: 20px;
      text-align: center;
    }
    h1 {
      margin-bottom: 5px;
    }
    .resumen {
      background: #ecf0f1;
      border: 1px solid #ccc;
      padding: 15px;
      margin: 20px 0;
      border-left: 5px solid #2980b9;
    }
    .resumen strong {
      color: #2c3e50;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
      background-color: #fff;
    }
    th, td {
      border: 1px solid #ccc;
      padding: 10px;
      text-align: left;
    }
    th {
      background-color: #2980b9;
      color: white;
    }
    .footer {
      margin-top: 30px;
      font-size: 0.9em;
      text-align: center;
      color: #888;
    }
  </style>
</head>
<body>
<header>
  <h1>🔎 Informe Técnico - Escaneo Nmap</h1>
  <p>Generado automáticamente el $(date '+%A %d de %B del %Y a las %H:%M:%S')</p>
</header>

<div class='resumen'>
  <p><strong>Tipo de Escaneo:</strong> ${tipo}</p>
  <p><strong>Destino:</strong> ${destino}</p>
  <p><strong>Duración:</strong> ${tiempo} segundos</p>
  <p><strong>Puertos Abiertos:</strong> ${abiertos}</p>
  <p><strong>RTTVAR detectado:</strong> ${rtt_detectado}</p>
  <p><strong>Script NSE usado:</strong> ${script:-Ninguno}</p>
  <p><strong>Sistemas Operativos Detectados:</strong> ${os_detections:-No detectados}</p>
  <p><strong>Servicios Detectados:</strong> ${servicios_detections:-No detectados}</p>
</div>

<h2>📋 Detalles de Puertos Abiertos</h2>
<table>
  <tr>
    <th>IP</th>
    <th>Puerto</th>
    <th>Estado</th>
    <th>Servicio</th>
  </tr>
$(generar_tabla_puertos "$folder/resultado.xml")
</table>

<h2>🛡️ Mitigaciones Recomendadas</h2>
<ul>
  <li><strong>HTTP/HTTPS:</strong> Verifica certificados SSL, actualiza el servidor web, y aplica encabezados de seguridad.</li>
  <li><strong>FTP:</strong> Evita FTP en texto plano, utiliza SFTP o FTPS.</li>
  <li><strong>MySQL:</strong> Restringe accesos remotos, usa contraseñas fuertes y roles mínimos necesarios.</li>
  <li><strong>MSRPC:</strong> Limita el acceso desde redes externas, habilita firewalls y segmentación de red.</li>
  <li><strong>SMB:</strong> Desactiva versiones antiguas como SMBv1, aplica parches de seguridad.</li>
  <li><strong>Puertos Abiertos:</strong> Cierra todos los que no sean estrictamente necesarios.</li>
</ul>

<div class='footer'>
  Menarguez-IA-Solutions &copy; $(date +%Y) | Generado por Nacho Menarguez Fernández
</div>
</body>
</html>
EOF

    cat <<EOF > "$folder/resumen.txt"
Menarguez-IA-Solutions
Fecha: $timestamp
Destino: $destino
Tipo de escaneo: $tipo
Script NSE usado: ${script:-Ninguno}
Puertos abiertos: ${abiertos}
RTTVAR detectado: ${rtt_detectado}
Duración: ${tiempo}s
Sistemas Operativos Detectados: ${os_detections:-No detectados}
Servicios Detectados: ${servicios_detections:-No detectados}
EOF

    # Permisos si se ejecuta como root
    if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
        chown -R "$SUDO_USER:$SUDO_USER" "$folder"
        chmod -R 755 "$folder"
    fi

    actualizar_index
    echo -e "${verde}✔ Informe generado en: $folder${reset}"

    echo -e "${negrita}${azul}\n📋 Resumen del escaneo:${reset}"
    echo -e "Destino objetivo: $destino"
    echo -e "Puertos abiertos: ${abiertos}"
    echo -e "RTTVAR detectado: ${rtt_detectado}"
    echo -e "Duración total: ${tiempo} segundos\n"

    # Enviar también al backend SOC y abrir dashboard bonito
    if pgrep -f "uvicorn app.main:app" >/dev/null 2>&1; then
        enviar_xml_a_dashboard "$folder/resultado.xml" "$folder/dashboard_soc.html"
    else
        echo -e "${amarillo}⚠ Backend SOC (uvicorn) no está ejecutándose. No se genera dashboard SOC.${reset}"
    fi
}

# ======================================================================
#  Modos de escaneo
# ======================================================================

# Función personalizada para escaneo básico

escaneo_basico() {
    echo -e "
${negrita}${azul}╔═══════════════════════════════════════╗"
    echo -e "║      Submenú - Escaneo de Red         ║"
    echo -e "╚═══════════════════════════════════════╝${reset}"
    echo "1) Escaneo rápido (ping + top ports)   [red completa]"
    echo "2) Escaneo completo (todos los puertos TCP)   [un solo host]"
    echo "3) Escaneo sigiloso (-sS)                      [un solo host]"
    echo "4) Escaneo agresivo (-A)                       [un solo host]"
    echo "5) Escaneo con detección de SO (-O)            [un solo host]"
    echo "6) Escaneo común + scripts NSE de vulnerabilidades [un solo host]"
    echo
    read -p "Selecciona el tipo de escaneo [1-6]: " tipo

    # Elegir objetivo según el tipo
    read -p "¿Deseas usar la red/IP detectada automáticamente? (s/n): " auto

    if [[ "$auto" =~ ^[sS]$ ]]; then
        if [[ "$tipo" -eq 1 ]]; then
            # Tipo 1: escaneo rápido a la red completa /24
            objetivo="$(detectar_red)/24"
        else
            # Tipos 2–6: sólo el host local detectado (sin /24)
            objetivo="$(detectar_red)"
        fi
    else
        if [[ "$tipo" -eq 1 ]]; then
            read -p "Introduce la red a escanear (ej: 10.0.2.15/24 o dominio): " objetivo
        else
            read -p "Introduce el HOST a escanear (ej: 10.0.2.15 o dominio): " objetivo
        fi
    fi

    salida="temp_$(date +%s)"
    SECONDS=0

    case "$tipo" in
        1) args="-sn --top-ports 100" ;;                             # red /24
        2) args="-p- -T4 --max-retries 1 --host-timeout 30s" ;;      # todos los puertos a 1 host
        3) args="-sS -T2 -Pn" ;;                                     # sigiloso
        4) args="-A -T4" ;;                                          # agresivo
        5) args="-O -T4" ;;                                          # detección de SO
        6) args="--top-ports 100 --script vulners,http-vuln*,ftp-vsftpd-backdoor" ;;
        *) echo -e "${rojo}Opción inválida${reset}"; return ;;
    esac

    echo -e "${azul}→ Ejecutando escaneo sobre $objetivo con opciones: $args ${reset}"
    nmap $args "$objetivo" -oX "$salida.xml" 2> >(grep -v "RTTVAR has grown") | tee "$salida.log"
    duracion=$SECONDS
    generar_informe "Escaneo Básico $tipo" "$objetivo" "" "$salida.xml" "$salida.log" "$duracion"
}

escaneo_custom() {
    read -p "Red/IP a escanear: " ip
    ip_resuelta=$(resolver_ip "$ip")
    if [ -z "$ip_resuelta" ]; then
        echo -e "${rojo}Dirección inválida o no resolvible.${reset}"; read -p "Enter para seguir..."; return
    fi
    read -p "Puertos (ej: 22,80 o 1-1000): " puertos
    salida="temp_$(date +%s)"
    args=$(generar_args "$puertos")
    echo -e "${azul}→ Escaneando $ip_resuelta:$puertos...${reset}"
    SECONDS=0
    nmap $args "$ip_resuelta" -oX "$salida.xml" 2> >(grep -v "RTTVAR has grown") | tee "$salida.log"
    duracion=$SECONDS
    generar_informe "Escaneo Personalizado" "$ip" "" "$salida.xml" "$salida.log" "$duracion"
}

usar_script_nmap() {
    local common_scripts=(
        "http-enum"
        "ftp-anon"
        "ssl-cert"
        "default"
        "vulners"
        "http-title"
        "smb-os-discovery"
        "smb-enum-shares"
        "smb-vuln-ms17-010"
        "dns-brute"
    )

    echo -e "${amarillo}Listado de los 10 scripts NSE más utilizados:${reset}"
    for i in "${!common_scripts[@]}"; do
        printf "[%02d] %s\n" $((i+1)) "${common_scripts[$i]}"
    done
    echo "[11] Introducir nombre de script manualmente"

    read -p "Selecciona número o ingresa el nombre del script: " opt
    if [[ "$opt" -eq 11 ]]; then
        read -p "Introduzca el nombre del script: " script
    elif [[ "$opt" -ge 1 && "$opt" -le 10 ]]; then
        script="${common_scripts[$((opt-1))]}"
    else
        echo -e "${rojo}Opción inválida${reset}"
        return
    fi

    read -p "Destino: " ip
    ip_resuelta=$(resolver_ip "$ip")
    salida="temp_$(date +%s)"
    args=$(generar_args "1-1000")
    echo -e "${azul}→ Ejecutando $script sobre $ip_resuelta...${reset}"
    SECONDS=0
    nmap $args --script "$script" "$ip_resuelta" -oX "$salida.xml" 2> >(grep -v "RTTVAR has grown") | tee "$salida.log"
    duracion=$SECONDS
    generar_informe "Script NSE" "$ip" "$script" "$salida.xml" "$salida.log" "$duracion"
}

escaneo_bypass() {
    echo -e "${azul}→ Intentando un escaneo bypass en el sistema${reset}"
    read -p "Introduce la IP objetivo: " ip
    ip_resuelta=$(resolver_ip "$ip")

    if [ -z "$ip_resuelta" ]; then
        echo -e "${rojo}Dirección inválida o no resolvible.${reset}"; read -p "Enter para seguir..."; return
    fi

    salida="temp_bypass_$(date +%s)"
    SECONDS=0
    args="-f -D RND -sS -Pn --top-ports 100"
    echo -e "${azul}→ Ejecutando escaneo bypass sobre $ip_resuelta...${reset}"
    nmap $args "$ip_resuelta" -oX "$salida.xml" 2> >(grep -v "RTTVAR has grown") | tee "$salida.log"
    duracion=$SECONDS
    generar_informe "Escaneo Bypass" "$ip" "" "$salida.xml" "$salida.log" "$duracion"
}

tuning_config() {
    read -p "¿Usar -Pn? (y/n) [actual: $usar_Pn]: " opt
    case "$opt" in y|Y) usar_Pn=true ;; n|N) usar_Pn=false ;; esac
    read -p "Nivel timing (0–5) [actual: $nivel_timing]: " t
    nivel_timing="-T${t:-3}"
    read -p "Timeout por host (ej: 30s, 1m): " host_timeout
}

# ======================================================================
#  Bucle principal del menú
# ======================================================================

while true; do
    mostrar_cabecera
    echo "╔═════════════════════════════════════════════╗"
    echo "║ [1] Escaneo básico                          ║"
    echo "║ [2] Escaneo personalizado                   ║"
    echo "║ [3] Usar script NSE                         ║"
    echo "║ [4] Escaneo con bypass                      ║"
    echo "║ [5] Ver dashboard de informes (HTML clásico)║"
    echo "║ [6] Configuración avanzada                  ║"
    echo "║ [7] Salir                                   ║"
    echo "╚═════════════════════════════════════════════╝"
    read -p "Selecciona opción: " op
    case "$op" in
        1) escaneo_basico ;;
        2) escaneo_custom ;;
        3) usar_script_nmap ;;
        4) escaneo_bypass ;;
        5) xdg-open "$INFORMES_DIR/index.html" 2>/dev/null || echo -e "${rojo}No se puede abrir.${reset}" ;;
        6) tuning_config ;;
        7) echo -e "${amarillo}👋 ¡Hasta luego, Nacho!${reset}"; exit 0 ;;
        *) echo -e "${rojo}Opción inválida${reset}" ;;
    esac
    read -p "Presiona Enter para continuar..."
done
