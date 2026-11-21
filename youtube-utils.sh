# -----------------------------------------------------------------------------
# youtube-utils.sh
#
# Funciones Bash para descargar videos y audio de YouTube usando yt-dlp.
#
# Encapsulan los pasos necesarios para sortear los bloqueos anti-bot de YouTube:
#   - Uso de cookies de sesión (youtube-AF-cookies.txt).
#   - Motor de JavaScript moderno (Deno) y componentes remotos de Node (ejs:npm).
#   - Cliente de reproducción "tv/web_embedded" y salto de la página web.
#
# Las funciones comprueban automáticamente si hay una versión más reciente de
# yt-dlp y de Deno y, de ser así, las actualizan antes de descargar.
#
# Requisitos:
#   - Bash
#   - yt-dlp (binario en /usr/local/bin/yt-dlp)
#   - Deno (opcional, requerido para resolver los desafíos JS de YouTube)
#   - ffmpeg (para fusionar video y audio en mp4)
#   - cookies.txt exportadas (ver --help o _check_cookies)
#
# Uso (añadir a ~/.bashrc):
#   source ~/bash-utils/youtube-utils.sh
# -----------------------------------------------------------------------------

YTDLP_BIN="/usr/local/bin/yt-dlp"

# El archivo de cookies vive junto a este módulo y está en .gitignore.
COOKIES_FILE="$(dirname "${BASH_SOURCE[0]}")/youtube-AF-cookies.txt"

# Variables de estado internas pobladas por _parse_opts.
list_formats=0
subs_lang=""
thumbnail=0
playlist=0
playlist_items=""
sponsorblock=0
notify=0
no_update=0
mp3=0
show_help=0
YT_URL=""


# ------------------------------------------------------------------------------
# _ytdlp_installed_version
#
# Devuelve la versión instalada de yt-dlp, o cadena vacía si no está instalado.
# ------------------------------------------------------------------------------
_ytdlp_installed_version() {
    command -v yt-dlp >/dev/null 2>&1 || return 1
    yt-dlp --version 2>/dev/null
}


# ------------------------------------------------------------------------------
# _ytdlp_latest_version
#
# Devuelve la última versión publicada de yt-dlp (tag_name en GitHub).
# Cadena vacía si no se puede consultar (sin conexión).
# ------------------------------------------------------------------------------
_ytdlp_latest_version() {
    curl -fsSL --max-time 15 \
        https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest 2>/dev/null \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p'
}


# ------------------------------------------------------------------------------
# _deno_installed_version
#
# Devuelve la versión instalada de Deno, o cadena vacía si no está instalado.
# ------------------------------------------------------------------------------
_deno_installed_version() {
    command -v deno >/dev/null 2>&1 || return 1
    deno --version 2>/dev/null | sed -n 's/^deno \([0-9.]*\).*/\1/p'
}


# ------------------------------------------------------------------------------
# _deno_latest_version
#
# Devuelve la última versión publicada de Deno (tag_name en GitHub, sin "v").
# Cadena vacía si no se puede consultar.
# ------------------------------------------------------------------------------
_deno_latest_version() {
    curl -fsSL --max-time 15 \
        https://api.github.com/repos/denoland/deno/releases/latest 2>/dev/null \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' \
        | tr -d 'v'
}


# ------------------------------------------------------------------------------
# _ensure_latest
#
# Compara las versiones instaladas de yt-dlp y Deno con las últimas publicadas
# y las actualiza automáticamente si hay una versión más reciente.
#
# - yt-dlp: descarga el binario oficial desde GitHub a /usr/local/bin (sudo).
# - deno:   usa `deno upgrade`, o el script de instalación si no está presente.
#
# Si no hay conexión, la consulta falla silenciosamente y no hace nada.
# ------------------------------------------------------------------------------
_ensure_latest() {

    local installed latest

    # -------------------------------------------------------------------------
    # yt-dlp
    # -------------------------------------------------------------------------
    installed="$(_ytdlp_installed_version)"
    latest="$(_ytdlp_latest_version)"

    if [[ -n "$latest" && "$latest" != "$installed" ]]; then
        echo "Actualizando yt-dlp: ${installed:-no instalado} -> $latest"
        sudo curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" \
            -o "$YTDLP_BIN" \
            && sudo chmod a+rx "$YTDLP_BIN" \
            && sudo ln -sf "$YTDLP_BIN" /usr/bin/yt-dlp
        echo
    fi

    # -------------------------------------------------------------------------
    # Deno
    # -------------------------------------------------------------------------
    installed="$(_deno_installed_version)"
    latest="$(_deno_latest_version)"

    if [[ -n "$latest" && "$latest" != "$installed" ]]; then
        if [[ -z "$installed" ]]; then
            echo "Deno no está instalado. Instalando..."
            curl -fsSL https://deno.land/install.sh | sh
        else
            echo "Actualizando Deno: $installed -> $latest"
            deno upgrade
        fi
        echo
    fi

}


# ------------------------------------------------------------------------------
# _print_cookies_help
#
# Imprime las instrucciones para (re)generar el archivo de cookies.
# ------------------------------------------------------------------------------
_print_cookies_help() {
    cat << EOF
Cómo renovar las cookies de YouTube
===================================

1. Instala la extensión "Get cookies.txt LOCALLY" en Chromium.
2. Abre YouTube con la sesión iniciada.
3. Haz clic en la extensión y pulsa "Export".
4. Guarda el archivo sobrescribiendo:

   ~/bash-utils/youtube-AF-cookies.txt

Nota: las cookies caducan si cierras sesión o con el paso del tiempo. Si
yt-dlp muestra el error "Sign in to confirm you're not a bot", renueva el
archivo siguiendo estos pasos.
EOF
}


# ------------------------------------------------------------------------------
# _check_cookies
#
# Verifica que el archivo de cookies exista. Si falta, imprime las
# instrucciones de renovación y devuelve 1.
# ------------------------------------------------------------------------------
_check_cookies() {
    if [[ ! -f "$COOKIES_FILE" ]]; then
        echo "Error: no se encontró el archivo de cookies:" >&2
        echo "  $COOKIES_FILE" >&2
        echo >&2
        _print_cookies_help >&2
        return 1
    fi
}


# ------------------------------------------------------------------------------
# _parse_opts
#
# Parsea las opciones comunes a download_video y download_audio. Almacena los
# resultados en variables globales para que _run_ytdlp construya el comando.
#
# La URL (primer argumento posicional no reconocido) se guarda en YT_URL.
# ------------------------------------------------------------------------------
_parse_opts() {

    list_formats=0
    subs_lang=""
    thumbnail=0
    playlist=0
    playlist_items=""
    sponsorblock=0
    notify=0
    no_update=0
    mp3=0
    show_help=0
    YT_URL=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -F|--list-formats)
                list_formats=1
                shift
                ;;
            -s|--subs)
                if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                    subs_lang="$2"
                    shift 2
                else
                    subs_lang="es,en"
                    shift
                fi
                ;;
            -t|--thumbnail)
                thumbnail=1
                shift
                ;;
            -p|--playlist)
                playlist=1
                if [[ -n "${2:-}" && "${2:0:1}" != "-" ]]; then
                    playlist_items="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --sponsorblock)
                sponsorblock=1
                shift
                ;;
            -n|--notify)
                notify=1
                shift
                ;;
            --no-update)
                no_update=1
                shift
                ;;
            --mp3)
                mp3=1
                shift
                ;;
            -h|--help)
                show_help=1
                shift
                ;;
            *)
                YT_URL="$1"
                shift
                ;;
        esac
    done

}


# ------------------------------------------------------------------------------
# _usage_video
# ------------------------------------------------------------------------------
_usage_video() {
    cat << EOF
download_video

Description
    Descarga un video de YouTube en la máxima calidad disponible (hasta 4K),
    fusionando el mejor video y audio en un solo archivo .mp4.

Usage
    download_video [opciones] <url>

Options
    -F, --list-formats     Lista los formatos disponibles sin descargar.
    -s, --subs [lang]      Descarga subtítulos (default: es,en).
    -t, --thumbnail        Guarda la miniatura e incrusta metadatos.
    -p, --playlist [rango] Descarga una playlist (ej: -p 1-5).
    --sponsorblock         Marca los segmentos patrocinados.
    -n, --notify           Notificación al terminar (notify-send).
    --no-update            Omite la verificación/actualización de yt-dlp y Deno.
    -h, --help             Muestra esta ayuda.

Examples
    download_video "https://www.youtube.com/watch?v=..."
    download_video -s -t "https://www.youtube.com/watch?v=..."
    download_video -p 1-5 "https://www.youtube.com/playlist?list=..."
    download_video -F "https://www.youtube.com/watch?v=..."
EOF
}


# ------------------------------------------------------------------------------
# _usage_audio
# ------------------------------------------------------------------------------
_usage_audio() {
    cat << EOF
download_audio

Description
    Descarga solo el audio de un video de YouTube en el mejor formato nativo
    (m4a/opus, sin re-codificar). Con --mp3 convierte a MP3.

Usage
    download_audio [opciones] <url>

Options
    --mp3                  Convierte el audio a MP3.
    -F, --list-formats     Lista los formatos disponibles sin descargar.
    -s, --subs [lang]      Descarga subtítulos (default: es,en).
    -p, --playlist [rango] Descarga una playlist (ej: -p 1-5).
    --sponsorblock         Marca los segmentos patrocinados.
    -n, --notify           Notificación al terminar (notify-send).
    --no-update            Omite la verificación/actualización de yt-dlp y Deno.
    -h, --help             Muestra esta ayuda.

Examples
    download_audio "https://www.youtube.com/watch?v=..."
    download_audio --mp3 "https://www.youtube.com/watch?v=..."
EOF
}


# ------------------------------------------------------------------------------
# _run_ytdlp <format> <mode> <url>
#
# Construye y ejecuta el comando yt-dlp con las opciones comunes y las
# seleccionadas mediante _parse_opts.
#
#   mode: "video" o "audio" (controla el merge a mp4 y la conversión a mp3).
# ------------------------------------------------------------------------------
_run_ytdlp() {

    local format="$1"
    local mode="$2"
    local url="$3"

    local -a args=(
        --cookies "$COOKIES_FILE"
        --remote-components ejs:npm
        --extractor-args "youtube:player_client=tv,web_embedded;player_skip=webpage"
        --force-overwrites
        -f "$format"
        -o "%(title)s [%(id)s].%(ext)s"
    )

    if [[ "$mode" == "video" ]]; then
        args+=(--merge-output-format mp4)
    fi

    [[ -n "$subs_lang" ]] && args+=(--write-subs --write-auto-subs --sub-langs "$subs_lang")
    [[ "$thumbnail" -eq 1 ]] && args+=(--write-thumbnail --embed-metadata)
    [[ "$playlist" -eq 1 ]] && args+=(--yes-playlist)
    [[ -n "$playlist_items" ]] && args+=(--playlist-items "$playlist_items")
    [[ "$sponsorblock" -eq 1 ]] && args+=(--sponsorblock-mark all)
    [[ "$mode" == "audio" && "$mp3" -eq 1 ]] && args+=(-x --audio-format mp3)

    if [[ "$list_formats" -eq 1 ]]; then
        "$YTDLP_BIN" \
            --cookies "$COOKIES_FILE" \
            --remote-components ejs:npm \
            --extractor-args "youtube:player_client=tv,web_embedded;player_skip=webpage" \
            -F "$url"
        return $?
    fi

    local rc=0

    if [[ "$notify" -eq 1 ]] && command -v notify-send >/dev/null 2>&1; then
        local title title_file
        title_file="$(mktemp)"
        "$YTDLP_BIN" "${args[@]}" --print after_move:title "$url" >"$title_file"
        rc=$?
        title="$(tail -1 "$title_file")"
        rm -f "$title_file"

        if [[ $rc -eq 0 ]]; then
            notify-send "yt-dlp" "Descarga completada: ${title:-$url}"
        else
            notify-send -u critical "yt-dlp" "Descarga fallida (código $rc): ${title:-$url}"
        fi
    else
        "$YTDLP_BIN" "${args[@]}" "$url"
        rc=$?
    fi

    return $rc
}


# ------------------------------------------------------------------------------
# download_video
#
# @description
#   Descarga un video de YouTube en la máxima calidad disponible (hasta 4K),
#   fusionando el mejor video y audio en un .mp4. Usa cookies de sesión y
#   actualiza yt-dlp/Deno si hay una versión más reciente.
#
# @usage
#   download_video [opciones] <url>
#
# @options
#   Ver 'download_video --help'.
#
# @returns
#   0 en éxito, distinto de 0 en error.
# ------------------------------------------------------------------------------
download_video() {

    _parse_opts "$@"

    [[ "$show_help" -eq 1 ]] && { _usage_video; return 0; }

    if [[ -z "$YT_URL" ]]; then
        echo "Uso: download_video [opciones] <url>" >&2
        echo "Ejecute 'download_video --help' para más información." >&2
        return 1
    fi

    [[ "$no_update" -eq 0 ]] && _ensure_latest
    _check_cookies || return 1

    _run_ytdlp "bestvideo*+bestaudio/best" "video" "$YT_URL"
}


# ------------------------------------------------------------------------------
# download_audio
#
# @description
#   Descarga solo el audio de un video de YouTube en el mejor formato nativo
#   (m4a/opus). Con --mp3 lo convierte a MP3. Usa cookies de sesión y actualiza
#   yt-dlp/Deno si hay una versión más reciente.
#
# @usage
#   download_audio [opciones] <url>
#
# @options
#   Ver 'download_audio --help'.
#
# @returns
#   0 en éxito, distinto de 0 en error.
# ------------------------------------------------------------------------------
download_audio() {

    _parse_opts "$@"

    [[ "$show_help" -eq 1 ]] && { _usage_audio; return 0; }

    if [[ -z "$YT_URL" ]]; then
        echo "Uso: download_audio [opciones] <url>" >&2
        echo "Ejecute 'download_audio --help' para más información." >&2
        return 1
    fi

    [[ "$no_update" -eq 0 ]] && _ensure_latest
    _check_cookies || return 1

    _run_ytdlp "bestaudio[ext=m4a]/bestaudio/best" "audio" "$YT_URL"
}
