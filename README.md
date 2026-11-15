# Note Shuffle

A KDE Plasma 6 desktop widget that shows one random piece at a time from your notes and quotes. Click it for the next one; it also changes on a timer. Each widget on the desktop has its own sources, so one can show poems and another art.

Planned (work in progress): a source can be a folder of Markdown notes, such as an Obsidian vault folder. A note is shown without its YAML front matter, with its first embedded image on top. Today the widget reads fortune files: plain text with entries separated by a line holding only `%` (see [creating_quotes.md](creating_quotes.md)).

This is a fork of [Quote of the Day](https://gitlab.com/plasma-qotd-widget/plasma-qotd-widget) by Prajjwal Devkota.

## Install

```bash
./install.sh             # install, or upgrade an installed copy
./install.sh --restart   # same, then restart plasmashell so running widgets load the new code
./uninstall.sh
./build.sh               # build/com.github.kobuster.noteshuffle.plasmoid, for installing elsewhere
```

Then right-click the desktop, choose Add Widgets, and drag "Note Shuffle" onto the desktop. Right-click the widget and choose Configure to pick sources, timer, font, colours and background opacity.

## License

GPL v3, like the original (see [LICENSE](LICENSE)). Modified by Kobuster from 2026-11-15 on: renamed, reduced to Plasma 6, file names with apostrophes fixed. The git history shows every change.
