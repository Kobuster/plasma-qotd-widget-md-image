// Turning raw file contents into "pieces" the widget can show.
// Plain JavaScript without QML types, so it can be tested outside Plasma.
.pragma library

var IMAGE_EXTENSIONS = ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "avif", "jp2"];

function extensionOf(path) {
    var name = String(path).split("/").pop();
    var dot = name.lastIndexOf(".");
    return dot > 0 ? name.substring(dot + 1).toLowerCase() : "";
}

function isImagePath(path) {
    return IMAGE_EXTENSIONS.indexOf(extensionOf(path)) !== -1;
}

function baseName(path) {
    return String(path).split("/").pop();
}

function dirName(path) {
    var parts = String(path).split("/");
    parts.pop();
    return parts.join("/");
}

// Remove YAML front matter at the very top of a note
function stripFrontMatter(text) {
    if (text.indexOf("---\n") !== 0) return text;
    var end = text.indexOf("\n---", 3);
    if (end === -1) return text;
    var after = text.indexOf("\n", end + 4);
    return after === -1 ? "" : text.substring(after + 1);
}

// Obsidian [[target|alias]], [[target#heading]], [[target]] -> visible text
function wikilinkText(inner) {
    var bar = inner.indexOf("|");
    if (bar !== -1) return inner.substring(bar + 1);
    var target = inner.split("#")[0];
    return baseName(target).replace(/\.md$/i, "");
}

// Obsidian shows single line breaks as breaks; CommonMark needs two trailing spaces
function keepLineBreaks(text) {
    var lines = text.split("\n");
    var inFence = false;
    for (var i = 0; i < lines.length; i++) {
        if (/^\s*(```|~~~)/.test(lines[i])) {
            inFence = !inFence;
            continue;
        }
        if (inFence) continue;
        var next = i + 1 < lines.length ? lines[i + 1] : "";
        if (lines[i].trim() !== "" && next.trim() !== "" && !/^\s*(```|~~~)/.test(next)) {
            lines[i] = lines[i].replace(/\s+$/, "") + "  ";
        }
    }
    return lines.join("\n");
}

// Convert Obsidian-flavoured Markdown into what Qt's Markdown renderer shows well
function cleanMarkdown(text) {
    text = text.replace(/%%[\s\S]*?%%/g, "");                     // comments
    text = text.replace(/!\[\[[^\]]*\]\]/g, "");                  // remaining embeds
    text = text.replace(/!\[[^\]]*\]\((?:[^()\s]|\([^()]*\))*\)/g, ""); // remaining image links
    text = text.replace(/\[\[([^\]]+)\]\]/g, function (m, inner) { return wikilinkText(inner); });
    text = text.replace(/^(\s*>\s*)\[![^\]]+\][+-]?\s*/gm, "$1"); // callout markers
    text = text.replace(/==([^=\n]+)==/g, "**$1**");               // highlights
    // _italic_ (Qt shows underscores as underline, Obsidian as italic); leaves snake_case alone
    text = text.replace(/(^|[^\w*_])_([^_\s](?:[^_\n]*[^_\s])?)_(?=[^\w]|$)/gm, "$1*$2*");
    text = text.replace(/\n{3,}/g, "\n\n").trim();
    return keepLineBreaks(text);
}

// First image embed of a note: {target, kind, start, end} or null
function findFirstImage(text) {
    var re = /!\[\[([^\]]+)\]\]|!\[[^\]]*\]\(((?:[^()\s]|\([^()]*\))+)\)/g;
    var m;
    while ((m = re.exec(text)) !== null) {
        var target, kind;
        if (m[1] !== undefined) {
            target = m[1].split("|")[0].split("#")[0].trim();
            kind = "wiki";
        } else {
            target = m[2].replace(/^<|>$/g, "").trim();
            try { target = decodeURIComponent(target); } catch (e) {}
            kind = "markdown";
        }
        if (/^https?:\/\//i.test(target) || isImagePath(target)) {
            return { target: target, kind: kind, start: m.index, end: m.index + m[0].length };
        }
    }
    return null;
}

// Index of image files: {byPath: {path: true}, byName: {name: [paths]}}
function buildImageIndex(paths) {
    var index = { byPath: {}, byName: {} };
    for (var i = 0; i < paths.length; i++) {
        var p = paths[i];
        if (!p) continue;
        index.byPath[p] = true;
        var name = baseName(p).toLowerCase();
        if (!index.byName[name]) index.byName[name] = [];
        index.byName[name].push(p);
    }
    return index;
}

// Find the image file an embed points to, the way Obsidian resolves it
function resolveImage(image, notePath, vaultPath, index) {
    var target = image.target;
    if (/^https?:\/\//i.test(target)) return target;
    if (target.indexOf("/") === 0) return target;
    var noteDir = dirName(notePath);
    var candidates = [];
    if (image.kind === "markdown") candidates.push(noteDir + "/" + target);
    if (vaultPath) candidates.push(vaultPath.replace(/\/$/, "") + "/" + target);
    candidates.push(noteDir + "/" + target);
    for (var i = 0; i < candidates.length; i++) {
        var c = normalizePath(candidates[i]);
        if (index.byPath[c]) return c;
    }
    var byName = index.byName[baseName(target).toLowerCase()] || [];
    if (byName.length === 1) return byName[0];
    if (byName.length > 1) {
        var best = byName[0], bestScore = -1;
        for (var j = 0; j < byName.length; j++) {
            var score = commonPrefixLength(byName[j], noteDir);
            if (byName[j].toLowerCase().endsWith("/" + target.toLowerCase())) score += 10000;
            if (score > bestScore) { best = byName[j]; bestScore = score; }
        }
        return best;
    }
    return normalizePath(noteDir + "/" + target); // last guess; the view hides it if missing
}

function commonPrefixLength(a, b) {
    var n = 0;
    while (n < a.length && n < b.length && a[n] === b[n]) n++;
    return n;
}

function normalizePath(path) {
    var out = [];
    var parts = path.split("/");
    for (var i = 0; i < parts.length; i++) {
        if (parts[i] === "" && i > 0) continue;
        if (parts[i] === ".") continue;
        if (parts[i] === "..") { if (out.length > 1) out.pop(); continue; }
        out.push(parts[i]);
    }
    return out.join("/");
}

// A Markdown note becomes one piece: first image on top, the rest as Markdown
function noteToPiece(raw, path, vaultPath, index) {
    var text = stripFrontMatter(raw.replace(/\r\n?/g, "\n"));
    var image = findFirstImage(text);
    var imagePath = "";
    if (image) {
        imagePath = resolveImage(image, path, vaultPath, index);
        text = text.substring(0, image.start) + text.substring(image.end);
    }
    return { text: cleanMarkdown(text), image: imagePath, sourceFile: path, sourceIndex: 0 };
}

// A fortune file (entries separated by a line holding only %) becomes many pieces
function fortuneToPieces(raw, path) {
    var text = raw.replace(/\r\n?/g, "\n");
    var entries = ("\n" + text + "\n").split(/\n%[ \t]*(?=\n)/);
    var pieces = [];
    for (var i = 0; i < entries.length; i++) {
        var entry = entries[i].trim();
        if (entry.length === 0) continue;
        pieces.push({ text: cleanMarkdown(entry), image: "", sourceFile: path, sourceIndex: pieces.length });
    }
    return pieces;
}

// Split the loader output ("\x1eFILE:<path>\n<content>" records) into files
function splitRecords(output) {
    var files = [];
    var records = String(output).split("\x1e");
    for (var i = 0; i < records.length; i++) {
        var rec = records[i];
        if (rec.indexOf("FILE:") !== 0) continue;
        var nl = rec.indexOf("\n");
        var path = nl === -1 ? rec.substring(5) : rec.substring(5, nl);
        var content = nl === -1 ? "" : rec.substring(nl + 1);
        files.push({ path: path, content: content });
    }
    return files;
}

function fileToPieces(file, vaultPath, index) {
    if (extensionOf(file.path) === "md") return [noteToPiece(file.content, file.path, vaultPath, index)];
    return fortuneToPieces(file.content, file.path);
}

// Turn a path into a file:// URL, escaping characters such as # and ?
function fileUrl(path) {
    if (/^[a-z]+:\/\//i.test(path)) return path;
    return "file://" + String(path).split("/").map(encodeURIComponent).join("/");
}

// Shell-quote a string with single quotes
function shellQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'";
}

// Shell command that prints every note/quote file of a source as records
function loadCommand(path) {
    var q = shellQuote(path);
    var each = shellQuote('for f; do printf "\\036FILE:%s\\n" "$f"; cat "$f"; done');
    return "if [ -d " + q + " ]; then find " + q + " -mindepth 1 -name '.*' -prune -o -type f -name '*.md' -exec sh -c " + each + " sh {} +; " +
           "else printf '\\036FILE:%s\\n' " + q + "; cat " + q + "; fi";
}

// Shell command that lists image files below the given folders
function imageListCommand(folders) {
    var names = [];
    for (var i = 0; i < IMAGE_EXTENSIONS.length; i++) names.push("-iname '*." + IMAGE_EXTENSIONS[i] + "'");
    var quoted = folders.map(shellQuote).join(" ");
    return "find " + quoted + " -mindepth 1 -name '.*' -prune -o -type f \\( " + names.join(" -o ") + " \\) -print 2>/dev/null; true";
}
