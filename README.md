# Quote of the Day Plasmoid

A KDE Plasma widget that displays random quotes from a directory. Supports both Plasma 5 and Plasma 6.

I wanted something like this for a while, figured I'd just use an LLM to generate one - vibe coded with a bit of review of the shell scripts.  Does what I need it to do.  You can change the quotes file to any text file formatted as a `fortune` file.

## Installation

```bash
./install.sh
```

The installer auto-detects your Plasma version and installs the widget.

## Usage

1. Right-click desktop → "Add Widgets..."
2. Search for "Quote of the Day"
3. Drag to desktop

## Configuration

Right-click widget → Configure:
- **Quotes Folder**: Directory with .txt files (default: ~/Documents/Quotes)
- **Rotation Interval**: Time between quote changes (10s - 24h, default: 2 minutes)
- **Background Opacity**: 0-100%
- **Font**: Typography settings
- **Colors**: Text, outline, and background

## Uninstall

```bash
./uninstall.sh
```

## Debug

```bash
./debug.sh       # Show diagnostics
./test-widget.sh # Test in window
./watch-logs.sh  # Monitor logs
./validate.sh    # Validate package
```

## License

GPL v3
