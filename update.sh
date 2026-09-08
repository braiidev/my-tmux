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

_version() {
    git -C "$DIR" describe --tags --abbrev=0 2>/dev/null || echo "sin-tag"
}

_msg() {
    # Mensaje visible ~5s en la línea de estado de tmux.
    ( tmux display-message -d 5000 "my-tmux: $1" 2>/dev/null ) \
        || tmux display-message "my-tmux: $1" 2>/dev/null \
        || printf 'my-tmux: %s\n' "$1" >&2
}

_behind() {
    git -C "$DIR" rev-list --count HEAD..origin/main 2>/dev/null
}

_update() {
    force="${1:-}"
    if [ "$force" = "--force" ]; then
        _msg "comprobando actualización..."
    fi
    if ! git -C "$DIR" fetch origin >/dev/null 2>&1; then
        _msg "no pude contactar el repo (sin conexión)"
        return
    fi
    count=$(_behind)
    [ -n "$count" ] || return
    if [ "$count" -le 0 ]; then
        if [ "$force" = "--force" ]; then
            _msg "sin novedades — ya estás en $(_version)"
        fi
        return
    fi
    _msg "actualizando... ($(_version) → +$count commits)"
    if git -C "$DIR" pull --ff-only; then
        _msg "actualizado a $(_version) — config recargada"
        tmux source-file "$DIR/tmux.conf"
    else
        _msg "pull falló; revisá $DIR"
    fi
}

_check() {
    case "${2:-}" in
        --force)
            _mark
            _update --force
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