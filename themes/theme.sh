#!/bin/sh
# Alterna entre los themes de tmux guardados en ~/.config/tmux/themes.
#   theme.sh apply  → aplica el theme activo (al arrancar, si existe current)
#   theme.sh cycle  → pasa al siguiente theme, lo guarda en current y lo aplica
DIR="$HOME/.config/tmux/themes"
CUR_FILE="$DIR/current"
LIST="clasico mono calido alto_contraste flatline"

apply() {
    [ -f "$CUR_FILE" ] && [ -s "$CUR_FILE" ] || return 0
    name=$(cat "$CUR_FILE")
    tmux source-file "$DIR/$name.conf" 2>/dev/null
}

cycle() {
    name=""
    if [ -f "$CUR_FILE" ] && [ -s "$CUR_FILE" ]; then
        cur=$(cat "$CUR_FILE")
        found=0
        for candidate in $LIST; do
            if [ "$found" -eq 1 ]; then
                name="$candidate"
                break
            fi
            [ "$candidate" = "$cur" ] && found=1
        done
    fi
    [ -n "$name" ] || name="${LIST%% *}"
    printf '%s\n' "$name" > "$CUR_FILE"
    tmux source-file "$DIR/$name.conf" 2>/dev/null
    tmux display-message "Tema: $name"
}

case "$1" in
    cycle) cycle ;;
    *) apply ;;
esac