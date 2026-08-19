#!/bin/bash
set -euo pipefail

REPO="https://github.com/braiidev/my-tmux.git"
TMUX_DIR="$HOME/.config/tmux"
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> my-tmux installer"
echo ""

# [1] Verificar Git
if ! command -v git >/dev/null 2>&1; then
    echo "Git no está instalado."
    read -r -p "¿Deseas instalar Git? (s/n): " install_git

    if [[ "$install_git" != "s" ]]; then
        echo "Instalación cancelada."
        exit 0
    fi

    sudo apt update
    sudo apt install -y git
fi

echo "Git está instalado."

# [2] Verificar TMUX
if ! command -v tmux >/dev/null 2>&1; then
    echo "TMUX no está instalado."
    read -r -p "¿Deseas instalar TMUX? (s/n): " install_tmux

    if [[ "$install_tmux" != "s" ]]; then
        echo "Instalación de TMUX cancelada."
        exit 0
    fi

    sudo apt update
    sudo apt install -y tmux
fi

echo "TMUX está instalado."

# [3] Descargar repositorio temporal
echo ""
echo "==> Descargando my-tmux..."

git clone --depth 1 "$REPO" "$TMP_DIR/my-tmux"

# [4] Crear directorio de configuración
mkdir -p "$TMUX_DIR"

# [5] Backup de tmux.conf existente
if [[ -f "$TMUX_DIR/tmux.conf" ]]; then

    BACKUP="$TMUX_DIR/tmux.conf.bak"

    if [[ -e "$BACKUP" ]]; then
        BACKUP="$TMUX_DIR/tmux.conf.bak.$(date +%Y%m%d-%H%M%S)"
    fi

    cp "$TMUX_DIR/tmux.conf" "$BACKUP"

    echo ""
    echo "Backup realizado:"
    echo "  $BACKUP"
fi

# [6] Instalar archivos
echo ""
echo "==> Instalando archivos..."

cp -r "$TMP_DIR/my-tmux/." "$TMUX_DIR/"

# [7] Eliminar metadata Git por seguridad
rm -rf "$TMUX_DIR/.git"

echo ""
echo "========================================"
echo " my-tmux instalado correctamente"
echo "========================================"
echo ""
echo "Instalado en:"
echo "  $TMUX_DIR"
echo ""
echo "Archivos instalados:"
find "$TMUX_DIR" -maxdepth 1 -type f -printf "  %f\n"
echo ""
