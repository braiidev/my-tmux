#!/bin/bash
set -euo pipefail

TMUX_CONF_PATH="$HOME/.config/tmux/tmux.conf"

# [1] Verificar ZSH
if ! command -v zsh &> /dev/null; then
    echo "ZSH no está instalado."
    read -p "¿Deseas instalar ZSH? (s/n): " install_zsh
    if [[ "$install_zsh" != "s" ]]; then
        echo "Instalación de ZSH cancelada. Fin del programa."
        exit 0
    fi
    sudo apt update && sudo apt install -y zsh
fi
echo "ZSH está instalado."

# [2] Verificar TMUX
if ! command -v tmux &> /dev/null; then
    echo "TMUX no está instalado."
    read -p "¿Deseas instalar TMUX? (s/n): " install_tmux
    if [[ "$install_tmux" != "s" ]]; then
        echo "Instalación de TMUX cancelada. Fin del programa."
        exit 0
    fi
    sudo apt update && sudo apt install -y tmux
fi
echo "TMUX está instalado."

# [3] Verificar ~/.config/tmux/tmux.conf
mkdir -p "$(dirname "$TMUX_CONF_PATH")"

TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

cat > "$TEMP_FILE" <<'EOF'
# __ General __
set -g default-terminal "tmux-256color"
set -g escape-time 0
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows off
set -g mouse off
set -g status-interval 1

# __ Prefix: C-b → M-b __
# set -g prefix C-b
set -g prefix M-a
unbind M-Space
unbind C-b

# __ Command prompt with Alt+: __
bind -n M-: command-prompt

# __ Alias to commands __
set -g command-alias[100] split='split-window -v'
set -g command-alias[101] vsplit='split-window -h'
set -g command-alias[102] tnew='new-window'

# __ Pane navigations (hjkl) __
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R

# __ Pane resize (HJKL) __
bind -n M-H resize-pane -L
bind -n M-J resize-pane -D
bind -n M-K resize-pane -U
bind -n M-L resize-pane -R

# __ Window __
bind r command-prompt -I "#W" { rename-window -- "%%" }
bind w choose-window
bind s choose-tree -Zs

bind -n M-b previous-window
bind -n M-n next-window
bind -n M-X confirm-before -p "¿Cerrar '#W'? (y/N)" kill-window
bind -n M-c new-window -c "#{pane_current_path}"

bind -n M-x confirm-before -p "¿Cerrar #P? (y/N)" kill-pane
bind -n M-S split
bind -n M-s vsplit

bind R source-file ~/.config/tmux/tmux.conf

# __ Swap window/pane __
bind -n M-N swap-window -t +1
bind -n M-B swap-window -t -1
bind -n M-> swap-pane -t +1
bind -n M-< swap-pane -t -1
bind -n M-z resize-pane -Z

bind -n M-Escape detach-client

# __ Manage windows __
bind -n M-w new-session
bind -n M-W confirm-before -p "Cerrar sesion '#S'? (y/N)" "run-shell 'tmux switch-client -n 2>/dev/null; tmux kill-session -t \"#S\"'"
bind -n M-[ switch-client -p
bind -n M-] switch-client -n

# __ Status Config __
set -g status-position top
set -g status-style "bg=colour0,fg=colour7"
set -g status-justify left

# __ Status Left __
set -g status-left-length 80
set -g status-left "#[fg=colour4,bold]|#[fg=default] #S #{host_short} #{username} #[fg=colour4]|"

# __ Status right __
set -g status-right-length 30
set -g status-right "#[fg=colour4,bold]|#[fg=default] %a #[fg=colour6]%d#[fg=default] %b, %H:%M #[fg=colour4]|"

# __ Status content __
set -g window-status-format " #I:#W "
set -g window-status-current-format "#[fg=colour4,bold][#[fg=default]#I:#W#[fg=colour4]\]"

# __ Messages __
set -g message-style "bg=colour3,fg=colour7,bold"
set -g message-command-style "bg=colour3,fg=colour7"
EOF

if [[ ! -f "$TMUX_CONF_PATH" ]] || [[ ! -s "$TMUX_CONF_PATH" ]]; then
    echo "El archivo tmux.conf no existe o está vacío."
    cp "$TEMP_FILE" "$TMUX_CONF_PATH"
    echo "Archivo tmux.conf creado exitosamente."
    exit 0
fi

echo "El archivo tmux.conf ya existe y tiene contenido."

if diff -q "$TMUX_CONF_PATH" "$TEMP_FILE" > /dev/null; then
    echo "El contenido es idéntico. No se requiere ninguna modificación."
    exit 0
fi

echo "Se detectaron diferencias en el archivo tmux.conf."
echo ""
echo "=== Diferencias encontradas (líneas que se modificarían) ==="
diff -u "$TMUX_CONF_PATH" "$TEMP_FILE" || true
echo ""

read -p "¿Deseas actualizar el archivo tmux.conf con los cambios mostrados? (s/n): " update_conf

if [[ "$update_conf" == "s" ]]; then
    cp "$TMUX_CONF_PATH" "$TMUX_CONF_PATH.bak"
    echo "Backup guardado en $TMUX_CONF_PATH.bak"
    cp "$TEMP_FILE" "$TMUX_CONF_PATH"
    echo "Archivo tmux.conf actualizado exitosamente."
else
    echo "No se realizaron cambios en el archivo tmux.conf."
fi
