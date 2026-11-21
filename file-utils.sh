# -----------------------------------------------------------------------------
# print_env_config
#
# Description:
#   Prints the configuration files required to understand and reproduce the
#   project's development environment.
#
#   The function is intentionally limited to configuration and package-definition
#   files. It does not inspect source code, tests, documentation, data, or
#   generated files.
#
# Files inspected:
#
#   Project root:
#     - default.nix
#     - .envrc
#     - *.sh              (shell scripts located directly in the root)
#     - DESCRIPTION       (R package)
#     - pyproject.toml     (Python package)
#     - docker-compose.yml
#     - docker-compose.yaml
#     - Dockerfile
#
#   Nix directory:
#     - nix/*.nix
#
#   All existing matching files are printed. Missing files are silently skipped,
#   allowing the function to be used across R and Python projects.
#
# Output:
#   Each file is printed with a header containing its path, making the output
#   suitable for copying into a chat, issue, debugging session, or documentation.
#
# Requirements:
#   - Bash
#   - cat
#
# Usage:
#   print_env_config
#
# Example:
#   $ print_env_config
#
# -----------------------------------------------------------------------------
print_env_config() {

    echo "============================================================"
    echo " PROJECT ENVIRONMENT CONFIGURATION"
    echo "============================================================"
    echo

    # -------------------------------------------------------------------------
    # Nix configuration
    # -------------------------------------------------------------------------
    echo "==================== NIX FILES ============================="
    echo

    if [[ -f "default.nix" ]]; then
        echo "===== default.nix ====="
        cat "default.nix"
        echo
    fi

    if [[ -d "nix" ]]; then
        for file in nix/*.nix; do
            [[ -f "$file" ]] || continue

            echo "===== $file ====="
            cat "$file"
            echo
        done
    fi

    # -------------------------------------------------------------------------
    # Direnv configuration
    # -------------------------------------------------------------------------
    echo "==================== DIRENV ================================"
    echo

    if [[ -f ".envrc" ]]; then
        echo "===== .envrc ====="
        cat ".envrc"
        echo
    fi

    # -------------------------------------------------------------------------
    # Root shell scripts
    # -------------------------------------------------------------------------
    echo "==================== SHELL SCRIPTS ========================="
    echo

    [[ -f "Makefile" ]] || continue
    echo "===== Makefile ====="
    cat "Makefile"
    echo

    for file in ./*.sh; do
        [[ -f "$file" ]] || continue

        echo "===== $file ====="
        cat "$file"
        echo
    done

    # -------------------------------------------------------------------------
    # Package definition
    # -------------------------------------------------------------------------
    echo "==================== PACKAGE ==============================="
    echo

    # R package
    if [[ -f "DESCRIPTION" ]]; then
        echo "===== DESCRIPTION (R) ====="
        cat "DESCRIPTION"
        echo
    fi

    # Python package
    if [[ -f "pyproject.toml" ]]; then
        echo "===== pyproject.toml (Python) ====="
        cat "pyproject.toml"
        echo
    fi

    # -------------------------------------------------------------------------
    # Docker configuration
    # -------------------------------------------------------------------------
    echo "==================== DOCKER ================================="
    echo

    if [[ -f "docker-compose.yml" ]]; then
        echo "===== docker-compose.yml ====="
        cat "docker-compose.yml"
        echo
    fi

    if [[ -f "docker-compose.yaml" ]]; then
        echo "===== docker-compose.yaml ====="
        cat "docker-compose.yaml"
        echo
    fi

    if [[ -f "Dockerfile" ]]; then
        echo "===== Dockerfile ====="
        cat "Dockerfile"
        echo
    fi

    # -------------------------------------------------------------------------
    # End marker
    # -------------------------------------------------------------------------
    echo "============================================================"
    echo " END CONFIGURATION"
    echo "============================================================"
}


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
