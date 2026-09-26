# TODO

## Doing
- (vacío — esperando próxima task)

## Next
- [ ] v0.8 feat: revisar gestión de `#(sh ...)` vs `#(...)` en status-right si hace falta

## Done
- [x] v0.16 fix: restaurar el targeting original de las apps (main vacío, clock/tplay/monitor en 2/3/4)
- [x] v0.15 fix: `install.sh` se come el stdin — clone a `/dev/null` + `ask()` lee de `/dev/tty`
- [x] v0.14 fix: workspace-tmux de vuelta al repo, portable (apps solo si existen) + binding M-0 a prueba de fallos
- [x] v0.12 chore: docs de desarrollo a dev/, excluidos del install y del auto-update
- [x] v0.13 fix: prueba real de instalación en máquina nueva — desplegado en Raspberry Pi 192.168.1.55 (Raspbian 12 armhf)
- [x] v0.11 chore: fuera el script huérfano workspace-tmux (lanza tplay/monitor, máquina-específico)
- [x] v0.9 feat: feedback de update.sh (comprobando/actualizando/actualizado a vX)
- [x] v0.8 fix: main-pane al 70% en workspace (M-0) y bind M-h
- [x] v0.7 feat: config local machine.conf (M-e/$EDITOR) + modo compatible + screensaver + reorg tmux.conf
- [x] v0.6 fix: source de p10k_colors.zsh dentro del bloque p10k (awk vs sed)
- [x] v0.5 feat: prompt zsh+p10k sincronizado con el theme de tmux (colors zsh/)
- [x] v0.4 chore: cambios de layout previos (pane navigation/resize, status)