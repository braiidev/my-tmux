# my-tmux

Script de instalación y configuración de `tmux` (con chequeo de `zsh`) para setup rápido en máquinas nuevas.

## Para quién es

Para provisioning de una máquina Ubuntu nueva y quiere el mismo entorno de terminal sin reconfigurar todo a mano.

## Instalación

```bash
curl -fsSL https://raw.githubusercontent.com/braiidev/my-tmux/main/install.sh -o /tmp/install.sh
bash /tmp/install.sh
```

## Qué mejora respecto de tmux sin configurar

| Comportamiento | Default de tmux | Con este script |
|---|---|---|
| Prefix | `Ctrl-b` | `Alt-a` |
| Navegación entre panes | `Ctrl-b` + flecha | `Alt-h/j/k/l` (vim-style) |
| Resize de panes | `Ctrl-b` + `Ctrl-flecha` | `Alt-H/J/K/L` |
| Split horizontal/vertical | `Ctrl-b %` / `Ctrl-b "` | `Alt-s` / `Alt-S` |
| Cerrar pane/window | sin confirmación | `Alt-x` / `Alt-X` con confirm-before |
| Crear Sesion | :new-session | `Alt-w` |
| Cerrar Sesion | :kill-session | `Alt-W` con confirm-before y vuelve a sesion anterior si es necesario |
| Navegar entre sesiones | `Ctrl-b` + `(` o `)` | `Alt-[` o `Alt-]` |
| Status bar | básica, abajo | arriba, con host, user y hora |
| Detach | `Ctrl-b d` | `Alt-Escape` |
| Config existente | se pisa sin avisar | detecta diffs, pide confirmación y hace backup `.bak` |

## Comandos agregados (`command-alias`)

- `:split` → split horizontal
- `:vsplit` → split vertical
- `:tnew` → nueva window
