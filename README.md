# Diary

A simple one-page-per-day journal for Mac OS X 10.4 Tiger and 10.5 Leopard,
on PowerPC and Intel Macs. It's the sibling of the
[classic Mac OS](https://github.com/retrolemmy/Diary),
[AmigaOS 3.2](https://github.com/retrolemmy/Diary-Amiga) and
[Windows 98](https://github.com/retrolemmy/Diary-Win98) versions, and like
them it can keep its entries on a
[Diary Server](https://github.com/retrolemmy/Diary-Server), so all your
computers share one diary.

- One window: a month calendar and a list of all entries (newest first) on
  the left, the selected day on the right with `<`, `Today` and `>` buttons
- In the calendar, days with an entry are **bold**, today is framed and the
  open day is highlighted; the arrows switch months. Click a day (or a list
  entry) to open it
- **Find** (⌘F) searches every entry (ignoring case) and narrows the list to
  the matches; **Find Again** (⌘G) jumps to the next match, across entries;
  **Show All Entries** clears the search
- **Go** menu: Previous Day (⌘[), Next Day (⌘]), Today (⌘T)
- **Format** menu: Show Fonts (⌥⌘T), Bigger (⌘+), Smaller (⌘-); the font
  applies to the whole entry and is remembered
- The current entry is saved automatically when you switch days or quit; ⌘S
  saves at any time
- Entries are plain text files named `YYYY-MM-DD` (UTF-8) in
  `Documents/Diary Entries`, or in a **Diary Entries** folder next to the
  application if there is one. Entries from the classic Mac and Amiga
  versions can be copied in and read as they are. Clearing an entry
  completely deletes its file
- **File → Diary Server...** keeps the entries on a Diary Server instead
  (by name or IP address, optionally with `:port`, and the server's key if
  it has one). Search then runs on the server, and if an entry was changed
  on another computer since you opened it, Diary asks before saving over it

## Building

On Mac OS X 10.5 with Xcode 3.1 (or 10.4 with Xcode 2.5), in this folder:

```sh
make
```

This builds `Diary.app`, a Universal application (PowerPC and Intel) that
runs on 10.4 and later. It needs the 10.4u SDK, which is part of the Xcode
install; without it, `make` builds for the running system only. `make zip`
packs the app into `Diary.zip` for copying to other Macs.

There's no Xcode project and no nib file: the window and menus are built in
code (Objective-C 1.0, so it builds on Tiger too).

## Icon

`Diary.icns` is drawn by `tools/make_icns.py`, from the same pixel art as
the classic Mac version's icon:

```sh
python3 tools/make_icns.py Diary.icns
```

## License

No rights reserved: Diary is dedicated to the public domain under
[CC0 1.0](LICENSE). Use it for anything, no attribution needed.
