# ------------------------------------------------------------------------------
# print_files
#
# @description
#   Prints the contents of one or more text files matching a shell pattern.
#   Optionally searches recursively to a specified directory depth.
#
# @usage
#   print_files [options] <pattern>
#
# @arguments
#   pattern
#       Shell pattern to match files.
#
# @options
#   -d, --depth <n>
#       Maximum recursion depth.
#       Default: 1
#
#   -h, --help
#       Show this help message.
#
# @examples
#   print_files "*.sh"
#   print_files ~/bin/*.sh
#   print_files -d 2 "*.R"
#   print_files --depth 3 "*.qmd"
#
# @returns
#   0 on success.
# ------------------------------------------------------------------------------

print_files() {

    local depth=1
    local pattern

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--depth)
                depth="$2"
                shift 2
                ;;
            -h|--help)
                cat << EOF
print_files

Description
    Prints the contents of text files matching a pattern.

Usage
    print_files [options] <pattern>

Options
    -d, --depth <n>   Maximum recursion depth (default: 1)
    -h, --help        Show this help.

Examples
    print_files "*.sh"
    print_files ~/bin/*.sh
    print_files -d 2 "*.R"
    print_files --depth 3 "*.qmd"

Output format

========== filename ==========
<file contents>

Notes
    - Hidden files are ignored.
    - Common editor temporary files (*.swp, *.swo, *~) are ignored.

EOF
                return 0
                ;;
            *)
                pattern="$1"
                shift
                ;;
        esac
    done

    [[ -z "$pattern" ]] && {
        echo "Usage: print_files [options] <pattern>"
        echo "Run 'print_files --help' for more information."
        return 1
    }

    find . \
        -maxdepth "$depth" \
        -type f \
        -name "$pattern" \
        ! -path '*/.*' \
        ! -name "*.swp" \
        ! -name "*.swo" \
        ! -name "*~" |
    sort |
    while IFS= read -r file; do

        echo
        echo "========== $file =========="
        cat "$file"

    done
}

# ------------------------------------------------------------------------------
# copy_as_md
#
# @description
#   Copia uno o más archivos a un directorio reemplazando su extensión por .md.
#   El contenido del archivo no se modifica; únicamente cambia el nombre del
#   archivo copiado.
#
# @usage
#   copy_as_md <destino> <archivos...>
#
# @arguments
#   destino
#       Directorio donde serán copiados los archivos.
#
#   archivos...
#       Uno o más archivos a copiar. Se acepta expansión del shell (*).
#
# @examples
#   copy_as_md cp-markdown investigation-phases/*.qmd
#
#   copy_as_md cp-markdown index.qmd investigation-phases/*.qmd
#
#   copy_as_md docs *.Rmd
#
# @options
#   -h, --help
#       Muestra esta ayuda.
#
# @returns
#   0 si la operación fue exitosa.
#   1 si faltan argumentos.
# ------------------------------------------------------------------------------

copy_as_md() {

    # Mostrar ayuda
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        cat << EOF
copy_as_md

Descripción
    Copia uno o más archivos a un directorio cambiando su extensión a .md.

Uso
    copy_as_md <destino> <archivos...>

Ejemplos
    copy_as_md cp-markdown investigation-phases/*.qmd
    copy_as_md cp-markdown index.qmd investigation-phases/*.qmd
    copy_as_md docs *.Rmd

Opciones
    -h, --help      Mostrar esta ayuda.

Notas
    - La carpeta destino se crea automáticamente si no existe.
    - Solo cambia la extensión del archivo copiado.
    - El contenido del archivo permanece intacto.
EOF
        return 0
    fi

    # Guardamos la carpeta destino antes de excluirla
    # Del resto de la función
    local dest="$1"

    # Todos los argumentos se corren una posición
    # Sacando a la carpeta del conteo
    shift

    # Validamos que los argumentos no estén vacíos
    # Por tanto esta es una manera abreviada de escribir un if
    # -z valida si el largo del string guardado en $dest es 0
    # $# valida si el número de archivos a copiar es 0
    [[ -z "$dest" || $# -eq 0 ]] && {
        echo "Uso: copy_as_md <destino> <archivos...>"
        echo "Ejecute 'copy_as_md --help' para más información."
        return 1
    }

    # Creamos la carpeta
    # no error if existing, make parent directories as needed
    mkdir -p "$dest"

    # Declaramos las variables a ser creadas en el loop
    # Como variables locales para mantener a bash limpio
    local file base

    # Ponemos $@ entre "" para evitar que bash interprete los
    # espacios que tienen los archivos como si fueran más parámetros
    for file in "$@"; do

        # -f valida si el archivo a ser copiado existe
        # de no existir saltemos todo lo que sigue
        [[ -f "$file" ]] || continue

        # Elimina desde el inicio hasta el último "/"
        # para quedarnos solo con el nombre del archivo
        # al eliminar el path de donde se encuentra
        base="${file##*/}"

        # Elimina desde el último "." hasta el final
        # para quitar la extensión original
        base="${base%.*}"

        # Aplica el cp que necesitamos en formato .md
        cp "$file" "$dest/$base.md"

    done

    echo "Copiados $# archivos a '$dest'."
}
