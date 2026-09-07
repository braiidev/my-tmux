#!/usr/bin/env python3
"""
Matrix screensaver - curses based.
Columnas de caracteres cayendo, con estela verde y cabeza blanca.
Longitud de estela: 5-12 caracteres. Loop infinito hasta presionar 'q'.
"""

import curses
import random
import time

CHARS = "アイウエオカキクケコサシスセソタチツテト0123456789qwertyuioplkjhgfdsazxcvbnmQWERTYUIOPLKJHGFDSAZXCVBNM"

MIN_LEN = 5
MAX_LEN = 10
SPEED = 0.01  # segundos entre frames
COLUMNS = 0.1
GLITCH = 0.25
MINMAX = [3, 6]


class Column:
    """Representa una columna que puede estar 'activa' (cayendo) o 'apagada' (espacio)."""

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
        self.speed_offset = random.randint(
            MINMAX[0], MINMAX[1]
        )  # algunas columnas caen "más lento"

    def step(self, height, frame):
        if not self.active:
            # pequeña probabilidad por frame de reactivarse (evita que la
            # pantalla se "muera" cuando todas las columnas quedan inactive)
            if random.random() < 0.01:
                self.reset(height)
            return

        # velocidad variable: algunas columnas caen cada frame, otras cada 2-3
        if frame % (self.speed_offset + 1) != 0:
            return

        self.y += 1
        # mutación ocasional de caracteres para efecto "glitch"
        if random.random() < GLITCH:
            idx = random.randrange(self.length)
            self.chars[idx] = random.choice(CHARS)
        if self.y - self.length > height:
            self.reset(height)

    def draw(self, stdscr, x, height):
        if not self.active:
            return
        for i in range(self.length):
            row = self.y - i
            if 0 <= row < height:
                ch = self.chars[i]
                if i == 0:
                    # cabeza: blanco brillante
                    attr = curses.color_pair(2) | curses.A_BOLD
                elif i < 3:
                    attr = curses.color_pair(1) | curses.A_BOLD
                else:
                    attr = curses.color_pair(1)
                try:
                    stdscr.addstr(row, x, ch, attr)
                except curses.error:
                    pass  # esquina inferior derecha de la terminal


def main(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(True)
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_CYAN, -1)
    curses.init_pair(2, curses.COLOR_WHITE, -1)

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
            col.draw(stdscr, x, height)

        stdscr.refresh()
        time.sleep(SPEED)
        frame += 1


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        pass
