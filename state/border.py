#!/usr/bin/env python3
import argparse
import os
import sqlite3
import subprocess
import sys

DB_PATH = os.path.expanduser("~/.config/tmux/data/mem.db")
TABLE = "config"
KEY = "pane_border_status"
DEFAULT_VAL = "off"


def get_db_connection():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    # Crear tabla si no existe
    conn.execute(
        f"CREATE TABLE IF NOT EXISTS {TABLE} (key TEXT PRIMARY KEY, value TEXT)"
    )
    conn.commit()
    return conn


def read_state():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(f"SELECT value FROM {TABLE} WHERE key = ?", (KEY,))
    row = cur.fetchone()
    conn.close()
    return row["value"] if row else DEFAULT_VAL


def toggle_state():
    current = read_state()
    new_val = "off" if current == "top" else "top"

    conn = get_db_connection()
    cur = conn.cursor()
    # Insertar o actualizar (UPSERT)
    cur.execute(
        f"INSERT OR REPLACE INTO {TABLE} (key, value) VALUES (?, ?)", (KEY, new_val)
    )
    conn.commit()
    conn.close()

    # Aplicar cambio en tmux inmediatamente
    subprocess.run(["tmux", "set", "pane-border-status", new_val], check=False)
    # print(f"Estado cambiado a: {new_val}")


def main():
    parser = argparse.ArgumentParser(description="Gestor de estados Tmux (SQLite)")
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("border-read", help="Lee el estado actual")
    subparsers.add_parser("border-toggle", help="Alterna el estado")

    args = parser.parse_args()

    if args.command == "border-read":
        print(read_state())
    elif args.command == "border-toggle":
        toggle_state()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
