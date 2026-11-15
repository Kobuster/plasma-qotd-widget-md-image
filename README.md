# Note Shuffle

A KDE Plasma 6 desktop widget that shows one random piece at a time from your notes and quotes. Click it for the next one; it also changes on a timer. Each widget on the desktop has its own sources, so one can show poems and another art.

Sources, chosen per widget in its settings:

- **A folder**: every `.md` note inside it, subfolders included (hidden folders such as `.obsidian` and `.trash` are skipped). A note is shown without its YAML front matter; its first embedded image (`![[name.jpg]]` or `![](path.jpg)`) goes on top, the rest is rendered as Markdown. Obsidian syntax is translated: `[[links]]` become plain text, `==highlights==` bold, `%%comments%%` hidden, single line breaks kept.
- **A Markdown file**: that one note.
- **A text file**: quotes in fortune format, entries separated by a line holding only `%` (see [creating_quotes.md](creating_quotes.md)). Entries may use Markdown.

Set the Obsidian vault folder in the settings so images embedded by name are found anywhere in the vault, as Obsidian finds them.

Click the widget for the next piece. Pieces come in shuffled order; all are shown once before any repeats. Click `…` (bottom right) to open the current note or quote file in its default app. Right-click for: Next Piece, Open in Default App, Open in Obsidian, Open Containing Folder, Reload from Disk. The sources are rescanned on a timer, so new notes show up by themselves.

This is a fork of [Quote of the Day](https://gitlab.com/plasma-qotd-widget/plasma-qotd-widget) by Prajjwal Devkota.

## Install

```bash
./install.sh             # install, or upgrade an installed copy
./install.sh --restart   # same, then restart plasmashell so running widgets load the new code
./uninstall.sh
./build.sh               # build/com.github.kobuster.noteshuffle.plasmoid, for installing elsewhere
```

Then right-click the desktop, choose Add Widgets, and drag "Note Shuffle" onto the desktop. Right-click the widget and choose Configure to pick sources, the vault folder, timers, image height, text alignment, font, colours and background opacity.

## License

GPL v3, like the original (see [LICENSE](LICENSE)). Modified by Kobuster from 2026-11-15 on: renamed, reduced to Plasma 6, Markdown notes and folders with images added, file names with apostrophes and spaces fixed. The git history shows every change.
