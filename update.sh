#!/bin/sh
# Auto-update de my-tmux (estilo Clock/Player).
#
#   check           verifica nueva versión (máx 1 vez/hora) y, si hay, baja + recarga
#   check --force   fuerza verificación ignorando el límite horario
#   pull            fuerza git pull --ff-only + recarga
#
# Acopla con run-shell en tmux.conf; requiere instalación con .git (install.sh).
# Compatible con ash/busybox (Alpine): no usa bash.

DIR="$HOME/.config/tmux"
MARKER="$DIR/cache/update-check"
TTL_HOURS=3600

_outdated() {
    [ -f "$MARKER" ] || return 1
    last=$(cat "$MARKER" 2>/dev/null)
    [ -n "$last" ] || return 1
    now=$(date +%s)
    [ $((now - last)) -lt "$TTL_HOURS" ]
}

_mark() {
    mkdir -p "$DIR/cache"
    date +%s >"$MARKER" 2>/dev/null
    return 0
}

_msg() {
    tmux display-message "my-tmux: $1" 2>/dev/null || printf 'my-tmux: %s\n' "$1" >&2
}

_behind() {
    git -C "$DIR" rev-list --count HEAD..origin/main 2>/dev/null
}

_update() {
    if ! git -C "$DIR" fetch origin >/dev/null 2>&1; then
        return
    fi
    count=$(_behind)
    [ -n "$count" ] || return
    if [ "$count" -le 0 ]; then
        return
    fi
    _msg "hay $count commits nuevos — actualizando..."
    if git -C "$DIR" pull --ff-only; then
        _msg "actualizado — recargando config"
        tmux source-file "$DIR/tmux.conf"
    else
        _msg "pull falló; revisá $DIR"
    fi
}

_check() {
    case "${2:-}" in
        --force)
            _mark
            _update
            ;;
        *)
            if _outdated; then
                :
            else
                _mark
                _update
            fi
            ;;
    esac
}

case "${1:-check}" in
    pull)
        _mark
        _update
        ;;
    check)
        _check "$@"
        ;;
    *)
        echo "uso: update.sh {check [--force] | pull}"
        ;;
esac