# Dictionary Lookup System

This document describes the architecture and usage of the Dictionary Lookup system used in the Plasma QOTD Widget.

## Overview

The dictionary lookup functionality is provided by a self-contained Python script that abstracts the complexity of online APIs and offline dictionary management. It provides a unified JSON interface for the QML widget to consume.

**Script Location:** `package/contents/scripts/dictionary_lookup.py`

## Usage

The script is executed via the command line.

```bash
python3 dictionary_lookup.py [QUERY] [OPTIONS]
```

### Arguments

| Argument | Description | Default |
| :--- | :--- | :--- |
| `query` | The word to define. | (Required) |
| `--mode` | Lookup mode: `online` or `offline`. | `online` |
| `--langs` | Comma-separated list of languages to attempt lookup for (ISO 2-letter codes, e.g., `en,de`). | `en` |
| `--desktop-lang`| The target language for translations (defaults to system locale). | System Locale |
| `--download-dir`| Directory to store/read offline dictionaries. | `~/.stardict/dic` |
| `--test` | Run internal self-tests. | |

### Examples

**Online Lookup (English):**
```bash
python3 package/contents/scripts/dictionary_lookup.py "serendipity"
```

**Offline Lookup (English -> German):**
```bash
python3 package/contents/scripts/dictionary_lookup.py "sky" --mode offline --langs en --desktop-lang de
```
*Note: This will automatically download the `eng-deu` dictionary if missing.*

**Offline Monolingual (English):**
```bash
python3 package/contents/scripts/dictionary_lookup.py "hello" --mode offline --langs en --desktop-lang en
```
*Note: Uses a fallback download (Webster's 1913) as FreeDict lacks pure English dictionaries.*

## JSON API

The script outputs a standard JSON object to `stdout`.

```json
{
  "query": "hello",
  "meanings": [
    "[noun] \"Hello!\" or an equivalent greeting.",
    "[verb] To greet with \"hello\"."
  ],
  "source": "api",
  "success": true,
  "language": "en",
  "error": null
}
```

- **`meanings`**: List of strings. Each string is a definition. In offline mode, may include dictionary tags like `[Dictionary Name] Definition`.
- **`source`**: `api` (Online) or `sdcv` (Offline).
- **`success`**: Boolean indicating if a definition was found.
- **`error`**: Error message string if failed, otherwise `null`.

## Architecture & Internals

### Online Mode
Uses the free [DictionaryAPI.dev](https://dictionaryapi.dev/). No API key required.

### Offline Mode
Dependencies: `sdcv` (StarDict Console Version) must be installed on the user's system.

1.  **Language Mapping**: Converts 2-letter ISO codes (e.g., `en`) to 3-letter codes used by FreeDict (e.g., `eng`).
2.  **Dictionary Discovery**:
    -   Checks if a suitable dictionary exists in the `download-dir` or standard system paths.
    -   If missing, queries the [FreeDict](https://freedict.org/) database.
3.  **Automatic Download**:
    -   Downloads the dictionary (StarDict format).
    -   Extracts to the download directory.
    -   **English Monolingual Fallback**: If `eng->eng` is requested, downloads Webster's 1913 Dictionary from a configured mirror, as FreeDict is primarily bilingual.
4.  **Parsing**:
    -   Executes `sdcv` and parses the text output (as `sdcv` JSON support varies by version).
    -   Strips HTML tags from definitions.

## Testing

A `testdata/` directory can be created in the project root to persist downloaded dictionaries during development testing.

```bash
mkdir testdata
python3 package/contents/scripts/dictionary_lookup.py "test" --mode offline --download-dir testdata
```
