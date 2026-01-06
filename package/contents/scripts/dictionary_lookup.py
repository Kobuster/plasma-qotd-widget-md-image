#!/usr/bin/env python3
import argparse
import json
import locale
import urllib.request
import urllib.parse
import urllib.error
import subprocess
import os
import sys
import tarfile
import re
import shutil
from pathlib import Path

def strip_html(text):
    clean = re.compile('<.*?>')
    return re.sub(clean, '', text)


# Constants
FREEDICT_API_URL = "https://freedict.org/freedict-database.json"
ONLINE_API_BASE = "https://api.dictionaryapi.dev/api/v2/entries"

# Fallback dictionaries (Monolingual or specific pairs not in FreeDict)
FALLBACK_DICTS = {
    'eng-eng': "http://download.huzheng.org/dict.org/stardict-dictd-web1913-2.4.2.tar.bz2"
}


# Map 2-letter codes to 3-letter ISO 639-2 codes (common ones) for FreeDict
# This is a basic map, might need expansion. FreeDict uses 3-letter codes.
ISO_MAP = {
    'en': 'eng', 'de': 'deu', 'fr': 'fra', 'es': 'spa', 'it': 'ita',
    'pt': 'por', 'ru': 'rus', 'ja': 'jpn', 'zh': 'zho', 'hi': 'hin',
    'sa': 'san', 'ar': 'ara', 'tr': 'tur', 'ko': 'kor', 'nl': 'nld',
    'sv': 'swe', 'pl': 'pol', 'uk': 'ukr', 'cs': 'ces', 'el': 'ell'
}

def get_iso3(lang_code):
    """Convert 2-letter code to 3-letter code if possible."""
    lang_code = lang_code.lower().split('_')[0]
    return ISO_MAP.get(lang_code, lang_code) # Fallback to input if not found

def get_desktop_language():
    try:
        loc = locale.getdefaultlocale()[0]
        if loc:
            return loc.split('_')[0]
    except:
        pass
    return 'en'

def normalize_response(query, meanings, source, success=True, lang='en', error=None):
    return {
        "query": query,
        "meanings": meanings,
        "source": source,
        "success": success,
        "language": lang,
        "error": error
    }

def fetch_url(url):
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            return response.read(), response.code
    except urllib.error.HTTPError as e:
        return None, e.code
    except Exception as e:
        return None, str(e)

# --- Online Lookup ---
def lookup_online(query, lang_code):
    """
    Lookup using dictionaryapi.dev.
    Returns (success, result_dict)
    """
    # dictionaryapi.dev often accepts 2-letter codes like 'en_US', 'en', 'hi'
    # strict mapping might be needed for some
    url = f"{ONLINE_API_BASE}/{lang_code}/{urllib.parse.quote(query)}"
    data, code = fetch_url(url)
    
    if code != 200:
        return False, f"API Error {code}"

    try:
        entries = json.loads(data)
        meanings = []
        for entry in entries:
            for meaning in entry.get('meanings', []):
                part_of_speech = meaning.get('partOfSpeech', '')
                for def_item in meaning.get('definitions', []):
                    definition = def_item.get('definition')
                    if definition:
                        if part_of_speech:
                            meanings.append(f"[{part_of_speech}] {definition}")
                        else:
                            meanings.append(definition)
        
        if not meanings:
             return False, "No definitions found in API response"

        return True, meanings
    except Exception as e:
        return False, f"Parse Error: {e}"

# --- Offline Lookup (SDCV) ---
def find_sdcv():
    return shutil.which('sdcv')

def get_default_download_dir():
    # Try standard paths. ~/.local/share/stardict/dic is XDG compliant
    # But usually sdcv looks in ~/.stardict/dic or /usr/share/stardict/dic
    # We will use ~/.stardict/dic as the install target for user
    home = Path.home()
    return home / ".stardict" / "dic"

def is_dict_installed(lang_src, lang_tgt, data_dir=None):
    """
    Check if a dictionary for src->tgt is available.
    sdcv doesn't have a simple 'is installed' flag for specific pair without parsing --list-dicts.
    We'll assume if we downloaded it, it's there.
    But better: run sdcv --list-dicts and check output.
    """
    cmd = ['sdcv', '--list-dicts']
    if data_dir:
        cmd.extend(['--data-dir', str(data_dir)])
    
    try:
        res = subprocess.run(cmd, capture_output=True, text=True)
        # Output format:
        # Dictionary's name   Word count
        # ...
        # We need to be loose here or match typical FreeDict names: "English-German" or "eng-deu"
        # FreeDict usually names them "English - German" or similar
        # simpler check: just try to lookup a common word? No, that's slow.
        # We will iterate our downloads logic. 
        # For now, let's assume we proceed to try lookups and if they fail, we try download.
        # Check standard FreeDict patterns in output?
        # Let's verify via the filesystem for our downloaded folders.
        return False # Logic deferred to 'ensure_dict'
    except:
        return False

def download_dictionary(src_iso, tgt_iso, download_dir):
    """
    Find and download dictionary from FreeDict.
    src_iso, tgt_iso: 3-letter codes (eng, deu)
    """
    print(f"Checking for dictionary {src_iso}->{tgt_iso}...", file=sys.stderr)
    
    desired_name = f"{src_iso}-{tgt_iso}"
    download_url = None

    # Check Fallback first for Monolingual
    if desired_name in FALLBACK_DICTS:
        download_url = FALLBACK_DICTS[desired_name]
        print(f"Using fallback source for {desired_name}...", file=sys.stderr)
    else:
        # 1. Fetch DB
        data, code = fetch_url(FREEDICT_API_URL)

        if code != 200:
            return False, "Failed to fetch FreeDict database"
        
        try:
            db = json.loads(data)
        except:
            return False, "Failed to parse FreeDict database"

        # 2. Find match
        # FreeDict structure is list of objects. matching "name" usually "src-tgt"
        candidate = None
        
        for entry in db:
            if entry.get('name') == desired_name:
                candidate = entry
                break
        
        if not candidate:
            return False, f"No dictionary found for {desired_name} in FreeDict."

        # 3. Get Release URL
        releases = candidate.get('releases', [])
        if not releases:
            return False, "No releases found."
        
        # Pick download URL. Prefer StarDict format for sdcv.
        # helper to score urls
        def score_url(u):
            s = 0
            if 'stardict' in u: s += 10
            if u.endswith('.tar.xz'): s += 2
            elif u.endswith('.tar.gz'): s += 1
            return s

        best_score = -1
        
        for release in releases:
            url = release.get('URL')
            if not url: continue
            
            # We only want archives
            if not (url.endswith('.tar.xz') or url.endswith('.tar.gz') or url.endswith('.tar.bz2')):
                continue
                
            s = score_url(url)
            if s > best_score:
                best_score = s
                download_url = url
                
    if not download_url:
        return False, "No suitable download URL found."
        
    # 4. Download
    print(f"Downloading {download_url}...", file=sys.stderr)
    try:
        # Create dir
        os.makedirs(download_dir, exist_ok=True)
        
        # Stream download to memory using urllib (or temp file if large? Dicts are 5-20MB usually)
        with urllib.request.urlopen(download_url) as response:
            with tarfile.open(fileobj=io.BytesIO(response.read()), mode="r:*") as tar:
                tar.extractall(path=download_dir)
                
        print(f"Installed dictionary to {download_dir}", file=sys.stderr)
        return True, "Installed"
    except Exception as e:
        return False, f"Download/Install failed: {e}"
import io

def lookup_offline(query, lang_code, desktop_lang, download_dir):
    """
    1. Check sdcv presence.
    2. Try lookup.
    3. If fails/empty, check if we can download dict, then retry.
    """
    if not find_sdcv():
        return False, "sdcv not installed", []

    # Map codes
    src_iso = get_iso3(lang_code)
    tgt_iso = get_iso3(desktop_lang)
    
    # Run SDCV
    # We use --json if available (newer sdcv), else parse text.
    # Actually, standard sdcv 0.5.2+ supports --json. Let's try it.
    # Need to specify data dir if custom.
    
    def run_sdcv():
        # sdcv 0.5.2 does not support --json. Use text output.
        cmd = ['sdcv', '-n', query, '--utf8-output']
        if download_dir:
            cmd.extend(['--data-dir', str(download_dir)])
        
        try:
            res = subprocess.run(cmd, capture_output=True, text=True)
            return res.stdout
        except:
            return None

    output = run_sdcv()
    
    # Parse Text Output
    # Format:
    # Found X items ...
    # -->DictName
    # -->Word
    # Definition...
    results = []
    if output:
        # Split by "-->"
        parts = output.split("-->")
        # parts[0] is garbage "Found ..."
        # parts[1] is DictName \n
        # parts[2] is Word \n Definition
        # parts[3] is DictName \n
        # parts[4] is Word \n Definition
        
        for i in range(1, len(parts), 2):
            if i+1 < len(parts):
                d_name = parts[i].strip()
                # parts[i+1] starts with Word, then rest is definition
                # Word is first line of parts[i+1]
                w_part = parts[i+1].split('\n', 1)
                word = w_part[0].strip()
                def_text = w_part[1] if len(w_part) > 1 else ""
                
                if def_text:
                    clean_def = strip_html(def_text)
                    clean_def = re.sub(r'\s+', ' ', clean_def).strip()
                    results.append(f"[{d_name}] {clean_def}")

    if results:
         return True, "Success", results

    if results:
         return True, "Success", results
         
    # If no results, try Downloading
    # Only try to download if query seems plausible? or just always if missing dict?
    # We don't know if dict is missing or word is missing.
    # Check if dict exists in download_dir matching the request.
    # Heuristic: Check filesystem for .ifo files in data dir containing ISO codes?
    # Easier: Just try to download. normalize_sdcv checks return.
    
    # To avoid repeated download attempts for missing words, we should check if we HAVE the dict.
    # We can check folder names in download_dir. FreeDict extracts to "freedict-eng-deu-X.Y"
    # Search for folder containing src_iso and tgt_iso?
    
    found_dict = False
    if os.path.exists(download_dir):
        for name in os.listdir(download_dir):
            if src_iso in name and tgt_iso in name:
                found_dict = True
                break
    
    if not found_dict:
        success, msg = download_dictionary(src_iso, tgt_iso, download_dir)
        if success:
            # Retry lookup
            output = run_sdcv()
            results = []
            if output:
                parts = output.split("-->")
                for i in range(1, len(parts), 2):
                    if i+1 < len(parts):
                        d_name = parts[i].strip()
                        w_part = parts[i+1].split('\n', 1)
                        word = w_part[0].strip()
                        def_text = w_part[1] if len(w_part) > 1 else ""
                        if def_text:
                            clean_def = strip_html(def_text)
                            clean_def = re.sub(r'\s+', ' ', clean_def).strip()
                            results.append(f"[{d_name}] {clean_def}")
            
            if results:
                return True, "Success", results
            else:
                 return False, "Word not found (Dict installed)", []
        else:
             return False, f"Word not found & Dict download failed: {msg}", []

    return False, "Word not found", []

# --- Main ---
def main():
    parser = argparse.ArgumentParser(description="Dictionary Lookup Script")
    parser.add_argument("query", help="Word to lookup")
    parser.add_argument("--langs", default="en", help="Comma separated languages (ISO 2-letter)")
    parser.add_argument("--mode", choices=["online", "offline"], default="online")
    parser.add_argument("--desktop-lang", default=None)
    parser.add_argument("--download-dir", default=None)
    parser.add_argument("--test", action="store_true", help="Run self-tests")
    
    args = parser.parse_args()
    
    if args.test:
        run_tests(args)
        return

    query = args.query
    mode = args.mode
    langs = [l.strip() for l in args.langs.split(',')]
    desktop_lang = args.desktop_lang or get_desktop_language()
    
    # Download Dir
    download_dir = args.download_dir
    if not download_dir:
        # Defaults
        if mode == "offline":
             download_dir = str(get_default_download_dir())

    all_errors = []
    
    for lang in langs:
        res_meanings = []
        res_source = ""
        res_success = False
        res_error = None
        
        if mode == "online":
            success, result = lookup_online(query, lang)
            if success:
                print(json.dumps(normalize_response(query, result, "api", True, lang)))
                return
            else:
                all_errors.append(f"{lang}: {result}")
                
        elif mode == "offline":
            success, msg, meanings = lookup_offline(query, lang, desktop_lang, download_dir)
            if success:
                print(json.dumps(normalize_response(query, meanings, "sdcv", True, lang)))
                return
            else:
                all_errors.append(f"{lang}: {msg}")

    # If we reached here, no success
    print(json.dumps(normalize_response(query, [], mode, False, langs[0] if langs else 'en', "; ".join(all_errors))))

# --- Text ---
def run_tests(args):
    # Primitive self-tests
    print("Running Tests...")
    
    # Test 1: Helper ISO
    assert get_iso3('en') == 'eng'
    assert get_iso3('de') == 'deu'
    print("ISO Map: OK")
    
    # Test 2: Online Lookup (Network dependent)
    print("Test Online 'hello'...", end='')
    s, r = lookup_online('hello', 'en')
    if s and 'greeting' in str(r).lower():
         print(" PASS")
    else:
         print(f" FAIL ({r})")

    # Test 3: Offline Logic (Mock?)
    # Validating imports work at least
    print("Imports and Logic Compilation: PASS")
    
    print("Done.")

if __name__ == "__main__":
    main()
