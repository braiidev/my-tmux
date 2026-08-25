#!/bin/python3
import curses
import random
import time

# ---------- Configuración personalizable ----------
CHARACTERS = "アァカサタナハマヤャラワガザダバパイィキシチニヒミリヰギジヂビピウゥクスツヌフムユュルグズブヅプエェケセテネヘメレヱゲゼデベペオォコソトノホモヨョロヲゴゾドボポヴッン 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
MIN_SPEED = 1  # Frames que tarda en caer 1 fila (más alto = más lento)
MAX_SPEED = 4
TRAIL_LENGTH = 10  # Largo de la estela por columna
SPAWN_CHANCE = 0.5  # Probabilidad de que una columna esté "activa"
FRAME_DELAY = 0.1  # Delay entre frames (segundos)


class Column:
    """Representa una columna que cae, con su propia velocidad y estela."""

    __slots__ = ("x", "y", "speed", "counter", "trail", "active")

    def __init__(self, x, height):
        self.x = x
        self.reset(height, start_random=True)

    def reset(self, height, start_random=False):
        self.y = (
            random.randint(-height, 0)
            if not start_random
            else random.randint(-height, height)
        )
        self.speed = random.randint(MIN_SPEED, MAX_SPEED)
        self.counter = 0
        self.trail = []  # lista de caracteres para la estela
        self.active = random.random() < SPAWN_CHANCE

    def step(self, height):
        self.counter += 1
        if self.counter < self.speed:
            return
        self.counter = 0

        # Avanzar la cabeza y agregar carácter nuevo a la estela
        self.trail.insert(0, random.choice(CHARACTERS))
        if len(self.trail) > TRAIL_LENGTH:
            self.trail.pop()
        self.y += 1

        # Reiniciar cuando la estela completa salió de la pantalla
        if self.y - TRAIL_LENGTH > height:
            self.reset(height)


def build_color_pairs():
    """Crea un gradiente de verdes: blanco brillante (cabeza) -> verde intenso -> verde oscuro."""
    curses.start_color()
    curses.use_default_colors()
    curses.init_pair(1, curses.COLOR_WHITE, -1)  # cabeza
    curses.init_pair(2, curses.COLOR_GREEN, -1)  # cuerpo brillante
    curses.init_pair(3, curses.COLOR_GREEN, -1)  # cuerpo (se usa con A_DIM abajo)
    return {
        "head": curses.color_pair(1) | curses.A_BOLD,
        "bright": curses.color_pair(2) | curses.A_BOLD,
        "dim": curses.color_pair(3) | curses.A_DIM,
    }


def matrix_effect(stdscr):
    curses.curs_set(0)
    stdscr.nodelay(True)  # getch() no bloquea
    stdscr.timeout(0)

    has_color = curses.has_colors()
    colors = build_color_pairs() if has_color else None

    height, width = stdscr.getmaxyx()
    columns = [Column(x, height) for x in range(width)]

    while True:
        # Manejo de resize sin crashear
        new_height, new_width = stdscr.getmaxyx()
        if (new_height, new_width) != (height, width):
            height, width = new_height, new_width
            columns = [Column(x, height) for x in range(width)]
            stdscr.clear()

        stdscr.erase()  # más eficiente que clear(): evita parpadeo

        for col in columns:
            if not col.active:
                continue
            for i, ch in enumerate(col.trail):
                row = col.y - i
                if not (0 <= row < height):
                    continue
                if not has_color:
                    attr = curses.A_NORMAL
                elif i == 0:
                    attr = colors["head"]
                elif i < TRAIL_LENGTH // 3:
                    attr = colors["bright"]
                else:
                    attr = colors["dim"]
                try:
                    stdscr.addch(row, col.x, ch, attr)
                except curses.error:
                    pass  # esquina inferior derecha puede fallar, es normal en curses

            col.step(height)

        stdscr.refresh()

        key = stdscr.getch()
        if key == ord("q"):
            break

        time.sleep(FRAME_DELAY)


if __name__ == "__main__":
    try:
        curses.wrapper(matrix_effect)
    except KeyboardInterrupt:
        pass
