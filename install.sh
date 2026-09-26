#!/bin/sh
set -eu

REPO="https://github.com/braiidev/my-tmux.git"
TMUX_DIR="$HOME/.config/tmux"
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

pkg_install() {
    pkg="$1"
    if command -v apk >/dev/null 2>&1; then
        sudo apk add --no-cache "$pkg"
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq
        sudo apt-get install -y "$pkg"
    else
        echo "No sé instalar paquetes en este sistema."
        echo "Instalá $pkg manualmente y corré el instalador de nuevo."
        exit 1
    fi
}

# Pregunta por stdin, pero si el instalador llegó por `curl | sh` el stdin es
# el propio script y un `read` se comería el código. En ese caso se lee de
# /dev/tty; si tampoco hay terminal, se responde "no" y se sigue.
ask() {
    printf '%s' "$1"
    reply=""
    if [ -t 0 ]; then
        read -r reply
    elif [ -r /dev/tty ]; then
        read -r reply 2>/dev/null < /dev/tty || true
    fi
    [ "$reply" = "s" ]
}

echo "==> my-tmux installer"
echo ""

# [1] Verificar Git
if ! command -v git >/dev/null 2>&1; then
    echo "Git no está instalado."
    if ! ask "¿Deseas instalar Git? (s/n): "; then
        echo "Instalación cancelada."
        exit 0
    fi
    pkg_install git
fi

echo "Git está instalado."

# [2] Verificar TMUX
if ! command -v tmux >/dev/null 2>&1; then
    echo "TMUX no está instalado."
    if ! ask "¿Deseas instalar TMUX? (s/n): "; then
        echo "Instalación de TMUX cancelada."
        exit 0
    fi
    pkg_install tmux
fi

echo "TMUX está instalado."

# [3] Descargar repositorio temporal
echo ""
echo "==> Descargando my-tmux..."

# Sin `< /dev/null` git puede leer del stdin y vaciar el buffer del terminal
# (o, con `curl | sh`, comer el resto del script). Los `read` de más abajo se
# quedan sin entrada y el instalador se salta pasos.
git clone --depth 1 "$REPO" "$TMP_DIR/my-tmux" < /dev/null

# [4] Crear directorio de configuración
mkdir -p "$TMUX_DIR"

# [5] Backup de tmux.conf existente
if [ -f "$TMUX_DIR/tmux.conf" ]; then
    BACKUP="$TMUX_DIR/tmux.conf.bak"
    if [ -e "$BACKUP" ]; then
        BACKUP="$TMUX_DIR/tmux.conf.bak.$(date +%Y%m%d-%H%M%S)"
    fi
    cp "$TMUX_DIR/tmux.conf" "$BACKUP"
    echo ""
    echo "Backup realizado:"
    echo "  $BACKUP"
fi

# [6] Instalar archivos (incluye .git para el auto-update estilo ohmytmux)
echo ""
echo "==> Instalando archivos..."

cp -r "$TMP_DIR/my-tmux/." "$TMUX_DIR/"

# Los docs de desarrollo (dev/) no son configuracion: no van a ~/.config/tmux/
rm -rf "$TMUX_DIR/dev"

# [7] Dependencias de runtime: directorios de cache y estado
mkdir -p "$TMUX_DIR/cache"

# [7b] config LOCAL por máquina (machine.conf está gitignored: el pull no lo pisa)
if [ ! -f "$TMUX_DIR/machine.conf" ]; then
    cp "$TMUX_DIR/machine.conf.example" "$TMUX_DIR/machine.conf"
    echo "Creado $TMUX_DIR/machine.conf (editable con M-e dentro de tmux)."
fi

# [8] Configurar el prompt del shell (zsh + powerlevel10k) con colores armónicos.
# Solo actúa si el usuario confirma cada paso; si no, hace skip sin romper nada.
echo ""
echo "==> Configurando prompt del shell (zsh + p10k)..."
sh "$TMUX_DIR/zsh/setup_p10k.sh" || echo "  (config del prompt omitida)"

echo ""
echo "========================================"
echo " my-tmux instalado correctamente"
echo "========================================"
echo ""
echo "Instalado en:"
echo "  $TMUX_DIR"
echo ""
echo "Auto-update: al entrar a tmux verifica e instala versiones nuevas."
echo "  check manual:  M-a u  dentro de tmux"
echo "Config local por máquina (NUNCA pisada):"
echo "  editar:        M-e  dentro de tmux  ($TMUX_DIR/machine.conf)"
echo ""