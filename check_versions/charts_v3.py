#!/usr/bin/python3
import argparse
from itertools import islice
import re
from rich.console import Console
from rich.table import Table
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("path")
    args = parser.parse_args()
    return Path(args.path)


def get_charts_attr(filepath):
    n = 3
    charts = []
    with open(filepath, 'r') as f:
        for n_lines in iter(lambda: tuple(islice(f, n)), ()):
            charts.append(n_lines)
    return charts


def render_table(charts):
    table = Table(title="Charts Version")
    table.add_column("Chart", justify="center", style="cyan", no_wrap=True)
    table.add_column("Type", justify="center", style="cyan", no_wrap=True)
    table.add_column("Version", justify="center", style="cyan", no_wrap=True)

    for c in charts:
        table.add_row(c[0], re.search(r'^charts-[a-zA-z]*', c[1]).group(0), re.search(r'release_[0-9].*', c[2]).group(0))
    
    console = Console()
    console.print(table)

if __name__ == "__main__":
    filename=parse_args()
    render_table(get_charts_attr(filename))
