#!/usr/bin/env python3
"""
Screensaver estilo "matrix" para tmux, con curses.

Adopta los colores del theme de tmux activo (~/.config/tmux/themes/current):
  - cabeza de cada columna   -> rol "texto" (blanco suele ser)
  - cuerpo/estela de la columna -> rol "nav"  (el acento del theme)
Si no se puede leer el theme, usa defaults estilo clasico (nav=6 cyan, texto=7 blanco).

Caracteres: ASCII y símbolos seguros (sin katakana/ideogramas; terminales sin
fuente CJK rompían la renderización).

Uso: python3 screensaver.py  — termina con 'q' o Ctrl-C.
"""

import curses
import random
import sys
import time

# Caracteres de las columnas. Solo ASCII + símbolos comunes monoespa.
CHARS = (
    "0123456789"
    "abcdefghijklmnopqrstuvwxyz"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    "+-*/=<>#|"
)

MIN_LEN = 5
MAX_LEN = 10
SPEED = 0.01  # segundos entre frames
COLUMNS = 0.1  # probabilidad de que una columna arranque activa al resetear
GLITCH = 0.25  # probabilidad de mutar un caracter por frame
MINMAX = [3, 6]  # rango de offset de velocidad por columna

# Defaults del theme clasico (si el parseo falla).
DEFAULT_NAV = 6  # cyan
DEFAULT_TEXTO = 7  # white


def resolve_theme_dir():
    """Directorio del repo (dev = ~/Dev/workspace-tmux, instalado = ~/.config/tmux)."""
    return __file__.rsplit("/", 1)[0] or "."


def read_theme_colors():
    """
    Lee el theme activo y devuelve (nav, texto) como números de color ANSI 0-7.
    Falla suave: ante cualquier problema devuelve los defaults del clasico.
    """
    theme_dir = resolve_theme_dir()
    current_file = theme_dir + "/themes/current"
    try:
        with open(current_file) as fh:
            name = fh.read().strip()
    except OSError:
        name = "clasico"

    conf_file = f"{theme_dir}/themes/{name}.conf"
    nav, texto = DEFAULT_NAV, DEFAULT_TEXTO
    try:
        with open(conf_file) as fh:
            for line in fh:
                if line.lstrip().startswith("#") and "marco=" in line:
                    # Formato: # marco=MAGENTA(5) texto=WHITE(7) clima=GREEN(2) helpers=MAGENTA(5) nav=MAGENTA(5)
                    parts = line.split("#")[-1].split()
                    for part in parts:
                        key, _, val = part.partition("=")
                        num = ""
                        for ch in val:
                            if ch.isdigit():
                                num += ch
                            elif num:
                                break
                        if key == "nav" and num:
                            nav = int(num)
                        elif key == "texto" and num:
                            texto = int(num)
                    break  # solo nos importa la primera linea de metadatos
    except OSError:
        pass

    # Sanitizar: solores ANSI 0-7 (colours base); si salió algo raro -> default.
    nav = nav if 0 <= nav <= 7 else DEFAULT_NAV
    texto = texto if 0 <= texto <= 7 else DEFAULT_TEXTO
    return nav, texto


class Column:
    """Una columna activa (cayendo) o apagada (vacía)."""

    __slots__ = ("active", "y", "length", "chars", "speed_offset")

    def __init__(self, height):
        self.active = False
        self.y = 0
        self.length = MIN_LEN
        self.chars = []
        self.speed_offset = 0
        self.reset(height)

    def reset(self, height, force_inactive=False):
        self.active = False if force_inactive else random.random() < COLUMNS
        self.length = random.randint(MIN_LEN, MAX_LEN)
        self.y = -random.randint(0, height // 2)
        self.chars = [random.choice(CHARS) for _ in range(self.length)]
        self.speed_offset = random.randint(MINMAX[0], MINMAX[1])

    def step(self, height, frame):
        if not self.active:
            # probabilidad por frame de revivir (evita pantalla muerta)
            if random.random() < 0.01:
                self.reset(height)
            return

        # velocidad variable: cada 1..3 frames baja un renglón
        if frame % (self.speed_offset + 1) != 0:
            return

        self.y += 1
        if random.random() < GLITCH:
            idx = random.randrange(self.length)
            self.chars[idx] = random.choice(CHARS)
        if self.y - self.length > height:
            self.reset(height)

    def draw(self, stdscr, x, height, pairs):
        if not self.active:
            return
        for i in range(self.length):
            row = self.y - i
            if 0 <= row < height:
                ch = self.chars[i]
                if i == 0:
                    attr = pairs["cabeza"] | curses.A_BOLD
                elif i < 3:
                    attr = pairs["cuerpo"] | curses.A_BOLD
                else:
                    attr = pairs["cuerpo"]
                try:
                    stdscr.addstr(row, x, ch, attr)
                except curses.error:
                    pass  # esquina inferior derecha


def main(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(True)
    curses.start_color()
    curses.use_default_colors()

    nav, texto = read_theme_colors()
    # Los values son colores ANSI 0-7, coinciden con curses.COLOR_* (0-7).
    curses.init_pair(1, nav, -1)      # cuerpo / estela
    curses.init_pair(2, texto, -1)    # cabeza
    pairs = {"cuerpo": curses.color_pair(1), "cabeza": curses.color_pair(2)}

    height, width = stdscr.getmaxyx()
    columns = [Column(height) for _ in range(width)]

    stdscr.clear()
    frame = 0

    while True:
        key = stdscr.getch()
        if key in (ord("q"), ord("Q")):
            break

        new_height, new_width = stdscr.getmaxyx()
        if (new_height, new_width) != (height, width):
            height, width = new_height, new_width
            columns = [Column(height) for _ in range(width)]
            stdscr.clear()

        stdscr.erase()
        for x, col in enumerate(columns):
            col.step(height, frame)
            col.draw(stdscr, x, height, pairs)

        stdscr.refresh()
        time.sleep(SPEED)
        frame += 1


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        pass