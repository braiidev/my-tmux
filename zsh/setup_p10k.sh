#!/bin/sh
# setup_p10k.sh — configura el prompt de zsh (powerlevel10k) para que use los
# colores del tema de tmux. Se llama desde install.sh.
#
# Flujo en cascada (si en CUALQUIER paso respondés "no", hace skip a todo lo
# que sigue y sale sin tocar nada más):
#   1) zsh        — existe? No → preguntar instalar (s/n). "no" → FIN.
#   2) oh-my-zsh  — ya instalado? No → preguntar instalar (s/n). "no" → FIN.
#   3) p10k       — preguntar instalar (s/n). "sí" → instalar + inyectar config
#                   armónica. "no" → FIN.
#
# POSIX /bin/sh, compatible ash/busybox (Alpine).

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
COLORS_SOURCE='[[ -f ~/.config/tmux/zsh/p10k_colors.zsh ]] && source ~/.config/tmux/zsh/p10k_colors.zsh'
OMZ_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
P10K_URL="https://github.com/romkatv/powerlevel10k.git"
P10K_DEST="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

say() { printf 'setup-zsh: %s\n' "$*"; }

ask() {
    # $1 = pregunta. Devuelve 0 si "s", 1 si "no".
    printf '%s (s/n): ' "$1"
    read -r ans
    case "$ans" in
        s|S|y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# [1] zsh
# ---------------------------------------------------------------------------
if ! command -v zsh >/dev/null 2>&1; then
    say "zsh no está instalado."
    if ! ask "¿Deseas instalar zsh?"; then
        say "Instalación de zsh omitida — se salta toda la config del prompt."
        exit 0
    fi
    if command -v apk >/dev/null 2>&1; then
        sudo apk add --no-cache zsh || { echo "No pude instalar zsh."; exit 1; }
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq
        sudo apt-get install -y zsh || { echo "No pude instalar zsh."; exit 1; }
    else
        echo "No sé instalar zsh en este sistema; instálalo manualmente y corré de nuevo."
        exit 1
    fi
    say "zsh instalado."
else
    say "zsh está instalado."
fi

# ---------------------------------------------------------------------------
# [2] oh-my-zsh
# ---------------------------------------------------------------------------
if [ -d "$HOME/.oh-my-zsh" ]; then
    say "oh-my-zsh está instalado."
else
    say "oh-my-zsh no está instalado."
    if ! ask "¿Deseas instalar oh-my-zsh?"; then
        say "Instalación de oh-my-zsh omitida — se salta la config del prompt."
        exit 0
    fi
    if command -v sh >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
        sh -c "$(curl -fsSL "$OMZ_URL")" || { echo "No pude instalar oh-my-zsh."; exit 1; }
    else
        echo "Falta curl/sh; instalá oh-my-zsh manualmente y corré de nuevo."
        exit 1
    fi
    say "oh-my-zsh instalado."
fi

# ---------------------------------------------------------------------------
# [3] powerlevel10k
# ---------------------------------------------------------------------------
if ! ask "¿Deseas instalar/configurar powerlevel10k (p10k) para el prompt?"; then
    say "p10k omitido — no se toca el prompt del shell."
    exit 0
fi

say "Instalando/configurando powerlevel10k..."

# 3a) Instalar p10k si no está
if [ ! -d "$P10K_DEST" ]; then
    if command -v git >/dev/null 2>&1; then
        git clone --depth 1 "$P10K_URL" "$P10K_DEST" || { echo "No pude clonar p10k."; exit 1; }
    else
        echo "Falta git; instalalo y corré de nuevo."
        exit 1
    fi
    say "powerlevel10k clonado en $P10K_DEST."
else
    say "powerlevel10k ya está presente."
fi

# 3b) Setear ZSH_THEME en .zshrc si no usa p10k.
# El tema se lee al sourcear oh-my-zsh.sh, así que p10k debe quedar ANTES de ese
# source. Reglas:
#   - ya es p10k            -> nada
#   - hay ZSH_THEME distinta -> reemplazarla por p10k (in-place)
#   - no hay ZSH_THEME       -> insertar antes del source de oh-my-zsh
if [ -f "$HOME/.zshrc" ]; then
    if grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"; then
        :
    elif grep -q '^[[:space:]]*ZSH_THEME=' "$HOME/.zshrc"; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.my-tmux.bak"
        sed 's/^[[:space:]]*ZSH_THEME="[^"]*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' \
            "$HOME/.zshrc" > "$HOME/.zshrc.my-tmux"
        mv "$HOME/.zshrc.my-tmux" "$HOME/.zshrc"
        say "ZSH_THEME reemplazado por p10k en ~/.zshrc (backup: .zshrc.my-tmux.bak)."
    else
        cp "$HOME/.zshrc" "$HOME/.zshrc.my-tmux.bak"
        # Insertar antes de `source $ZSH/oh-my-zsh.sh` si existe; si no, al final.
        if grep -q 'oh-my-zsh.sh' "$HOME/.zshrc"; then
            sed 's#^[[:space:]]*source[[:space:]]*.*oh-my-zsh\.sh#ZSH_THEME="powerlevel10k/powerlevel10k"\n&#' \
                "$HOME/.zshrc" > "$HOME/.zshrc.my-tmux"
        else
            printf 'ZSH_THEME="powerlevel10k/powerlevel10k"\n' > "$HOME/.zshrc.my-tmux"
            cat "$HOME/.zshrc" >> "$HOME/.zshrc.my-tmux"
        fi
        mv "$HOME/.zshrc.my-tmux" "$HOME/.zshrc"
        say "ZSH_THEME=p10k insertado en ~/.zshrc (backup: .zshrc.my-tmux.bak)."
    fi
else
    echo "ADVERTENCIA: no existe ~/.zshrc; crealo y seteá ZSH_THEME='powerlevel10k/powerlevel10k'."
fi

# 3c) Inyectar el source armónico en .p10k.zsh (o crearlo).
# Debe ir DENTRO del bloque `() { ... }`, justo antes del `p10k reload`, para
# que el reload aplique los colores del tema de inmediato.
P10K_FILE="$HOME/.p10k.zsh"

if [ -f "$P10K_FILE" ]; then
    if grep -q 'p10k_colors.zsh' "$P10K_FILE"; then
        say ".p10k.zsh ya tiene el source de colores — sin cambios."
    else
        cp "$P10K_FILE" "$P10K_FILE.bak"
        # Insertar el source dentro del bloque, justo antes del `p10k reload`,
        # para que el reload aplique los colores del tema de inmediato.
        if grep -q 'p10k reload' "$P10K_FILE"; then
            awk '
                /p10k reload/ && !done {
                    print "# my-tmux: colores del prompt segun tema activo de tmux"
                    print "source ~/.config/tmux/zsh/p10k_colors.zsh"
                    done = 1
                }
                { print }
            ' "$P10K_FILE" > "$P10K_FILE.my-tmux"
            mv "$P10K_FILE.my-tmux" "$P10K_FILE"
        else
            # Caso raro sin reload: append al final (igual las variables globales
            # se leen en cada render del prompt).
            printf '\n# my-tmux: colores del prompt según el tema de tmux activo\nsource ~/.config/tmux/zsh/p10k_colors.zsh\n' >> "$P10K_FILE"
        fi
        say "Inyectado source de colores en .p10k.zsh (backup: .p10k.zsh.bak)."
    fi
elif [ -f "$HOME/.zshrc" ]; then
    # No hay .p10k.zsh: generamos uno mínimo armónico (base clásica).
    cat > "$P10K_FILE" <<'EOF'
# Generado por setup_p10k.sh (my-tmux). Corré `p10k configure` para personalizar.
() {
  emulate -L zsh
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'
  typeset -g POWERLEVEL9K_MODE=ascii
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time time)
  typeset -g POWERLEVEL9K_BACKGROUND=0
  (( ! $+functions[p10k] )) || p10k reload
}
EOF
    printf '\n# my-tmux: colores del prompt según el tema de tmux activo\nsource ~/.config/tmux/zsh/p10k_colors.zsh\n' >> "$P10K_FILE"
    say "Creado .p10k.zsh mínimo con el source de colores."
fi

say "Done. Abrí una shell nueva (o source ~/.zshrc) para ver el prompt armonizado."
