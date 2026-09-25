# Tmux Conf
### Ceder la configuracion a Python3.

- Panel para gestionar tmux.conf

Crear un script que gestione tmux.conf dinamicamente desde una db en la misma carpeta .config/tmux


#### Layout permite configurar y registrar:
- Keybidings
- Status Bar
- Panel Status
- Show network
- Show sound
- Show datetime
- Format datetime
- Colors
- Config Status Bar Left
- Config Status Bar Center
- Config Status Bar Right


> El plan es usar un keybind nativo de tmux.conf como "bind P run-shell ~/.config/tmux/tmux-config.py" para abrir "new-window".
> tmux-config.py es un tipo "curses" navegable simple con "toggles" a configurar y boton guardar cambios
> Usa una db simple de sqlite3 en ~/.config/tmux/data/mem.db
