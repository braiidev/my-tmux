# my-tmux

Configuración personal de `tmux` para Ubuntu, distribuida como un setup portable para máquinas nuevas.

Incluye `tmux.conf` y scripts auxiliares para el status bar.

## Para quién es

Para quien quiere provisionar rápidamente una máquina Ubuntu y disponer del mismo entorno de terminal sin reconfigurar `tmux` manualmente.

## Instalación

La instalación requiere `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/braiidev/my-tmux/main/install.sh | bash
```

El instalador:

1. Verifica que `git` esté instalado.
2. Verifica que `tmux` esté instalado.
3. Pregunta antes de instalar cualquier dependencia faltante.
4. Descarga la configuración desde este repositorio.
5. Instala los archivos en `~/.config/tmux/`.
6. Si ya existe `tmux.conf`, crea un backup antes de reemplazarlo.

La configuración instalada no contiene el directorio `.git`. El repositorio de GitHub funciona como fuente de distribución, mientras que `~/.config/tmux/` contiene únicamente los archivos instalados.

## Estructura instalada

```text
~/.config/tmux/
├── tmux.conf
├── red.sh
├── sound.sh
└── ...
```

## Qué mejora respecto de tmux sin configurar

| Comportamiento            | Default de tmux               | Con my-tmux                            |
| ------------------------- | ----------------------------- | -------------------------------------- |
| Prefix                    | `Ctrl-b`                      | `Alt-a`                                |
| Navegación entre panes    | `Ctrl-b` + flecha             | `Alt-h/j/k/l` (vim-style)              |
| Resize de panes           | `Ctrl-b` + `Ctrl-flecha`      | `Alt-H/J/K/L`                          |
| Split horizontal/vertical | `Ctrl-b %` / `Ctrl-b "`       | `Alt-s` / `Alt-S`                      |
| Cerrar pane/window        | sin confirmación              | `Alt-x` / `Alt-X` con `confirm-before` |
| Crear sesión              | `:new-session`                | `Alt-w`                                |
| Cerrar sesión             | `:kill-session`               | `Alt-W` con confirmación               |
| Navegar entre sesiones    | `Ctrl-b` + `(` o `)`          | `Alt-[` / `Alt-]`                      |
| Status bar                | básica, abajo                 | arriba, con información del sistema    |
| Detach                    | `Ctrl-b d`                    | `Alt-Escape`                           |
| Configuración existente   | depende de instalación manual | backup automático antes de reemplazar  |

## Status Bar

La configuración incluye scripts independientes para mostrar información del sistema.

Ejemplos:

```text
WIFI: MyHomeNetwork
ETH
OFFLINE
```

Estado del sonido:

```text
SOUND ON
SOUND OFF
```

Los scripts pueden utilizarse individualmente desde el terminal o integrarse en el `status-right` / `status-left` de `tmux`.

## Scripts

Los scripts están diseñados con una responsabilidad específica.

Cada script puede evolucionar independientemente de la configuración principal de `tmux`.

## Comandos agregados (`command-alias`)

* `:split` → split horizontal
* `:vsplit` → split vertical
* `:tnew` → nueva window

## Recargar configuración

Dentro de `tmux`:

```text
Alt-r
```

También puedes ejecutar:

```bash
tmux source-file ~/.config/tmux/tmux.conf
```


