#!/usr/bin/env python3
"""Generates Diary.icns: the same red leather diary as the classic Mac
version's icon (drawn on a 32x32 and a 16x16 grid), scaled up as pixel art
for 128x128. Run:  python3 tools/make_icns.py Diary.icns
"""

import struct
import sys

COLOURS = {
    'K': (0x00, 0x00, 0x00),    # black outline
    'R': (0xCC, 0x00, 0x00),    # red leather cover
    'H': (0xFF, 0x66, 0x66),    # cover highlight
    'D': (0x66, 0x00, 0x00),    # dark red spine / strap
    'W': (0xFF, 0xFF, 0xFF),    # page white
    'G': (0xCC, 0xCC, 0xCC),    # page edge lines
    'Y': (0xFF, 0xCC, 0x00),    # gold
    'O': (0xCC, 0x99, 0x00),    # dark gold
    'B': (0x00, 0x66, 0xFF),    # ribbon
}


def new_grid(n):
    return [['.'] * n for _ in range(n)]


def rect(g, top, left, bottom, right, c):
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            g[y][x] = c


def frame(g, top, left, bottom, right, c):
    for x in range(left, right + 1):
        g[top][x] = g[bottom][x] = c
    for y in range(top, bottom + 1):
        g[y][left] = g[y][right] = c


def large():
    g = new_grid(32)
    # Page block peeking out at the right and bottom
    rect(g, 3, 5, 29, 27, 'W')
    frame(g, 3, 5, 29, 27, 'K')
    for y in range(5, 28, 2):
        g[y][26] = 'G'
    for x in range(7, 26, 2):
        g[28][x] = 'G'
    # Cover
    rect(g, 1, 3, 27, 25, 'R')
    frame(g, 1, 3, 27, 25, 'K')
    for x in range(9, 25):
        g[2][x] = 'H'
    for y in range(2, 27):
        g[y][9] = 'H'
    # Spine
    rect(g, 2, 4, 26, 7, 'D')
    for x in range(4, 8):
        g[5][x] = g[23][x] = 'Y'
    for y in range(2, 27):
        g[y][8] = 'K'
    # Gold label with two text lines
    rect(g, 6, 12, 12, 22, 'W')
    frame(g, 6, 12, 12, 22, 'O')
    for x in range(14, 21):
        g[8][x] = 'G'
    for x in range(14, 19):
        g[10][x] = 'G'
    # Strap across the right edge with a gold clasp
    rect(g, 15, 19, 19, 27, 'D')
    frame(g, 15, 19, 19, 27, 'K')
    rect(g, 14, 20, 20, 23, 'Y')
    frame(g, 14, 20, 20, 23, 'K')
    g[17][21] = g[17][22] = 'O'
    # Ribbon bookmark with a notched end
    rect(g, 28, 11, 31, 13, 'B')
    g[31][12] = '.'
    for y in (30, 31):
        g[y][10] = g[y][14] = 'K'
    return g


def small():
    g = new_grid(16)
    rect(g, 2, 3, 15, 14, 'W')
    frame(g, 2, 3, 15, 14, 'K')
    rect(g, 0, 1, 13, 12, 'R')
    frame(g, 0, 1, 13, 12, 'K')
    rect(g, 1, 2, 12, 3, 'D')
    for y in range(1, 13):
        g[y][4] = 'K'
    rect(g, 3, 6, 5, 10, 'W')
    frame(g, 3, 6, 5, 10, 'O')
    rect(g, 7, 10, 9, 14, 'D')
    frame(g, 7, 10, 9, 14, 'K')
    rect(g, 7, 10, 9, 11, 'Y')
    g[14][7] = g[15][7] = 'B'
    return g


def scaled(g, factor):
    return [[c for c in row for _ in range(factor)] for row in g for _ in range(factor)]


def packbits(channel):
    """The icns RLE, using literal runs only (which every decoder reads)."""
    out = bytearray()
    for i in range(0, len(channel), 128):
        chunk = channel[i:i + 128]
        out.append(len(chunk) - 1)
        out += chunk
    return bytes(out)


def rgb(g):
    pixels = [COLOURS.get(c, (0, 0, 0)) for row in g for c in row]
    return b''.join(packbits(bytes(p[i] for p in pixels)) for i in range(3))


def mask(g):
    return bytes(0 if c == '.' else 255 for row in g for c in row)


def element(kind, data):
    return kind.encode() + struct.pack('>I', len(data) + 8) + data


def main():
    big, sml = large(), small()
    huge = scaled(big, 4)
    body = (element('is32', rgb(sml)) + element('s8mk', mask(sml))
            + element('il32', rgb(big)) + element('l8mk', mask(big))
            + element('it32', b'\0\0\0\0' + rgb(huge)) + element('t8mk', mask(huge)))
    with open(sys.argv[1], 'wb') as f:
        f.write(b'icns' + struct.pack('>I', len(body) + 8) + body)


main()
