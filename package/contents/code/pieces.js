// Turning raw file contents into "pieces" the widget can show.
// Plain JavaScript without QML types, so it can be tested outside Plasma.
.pragma library

var IMAGE_EXTENSIONS = ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "avif", "jp2"];

// Rendering options and their defaults (the widget passes the user's settings)
//   frontMatter: "hide" | "show"
//   tags:        "keep" | "lines" (hide lines made only of tags) | "all" (hide every #tag)
//   images:      "first" | "all" | "none"
//   title:       "keep" | "hide" | "filename" (add the file name when a note has no heading)
//   length:      "whole" | "paragraphs" | "chars" | "marker"
//   paragraphs, chars: limits for those length modes; marker: the cut line, e.g. %%more%%
//   lineBreaks:  "obsidian" (every line break shows) | "markdown" (lines in a paragraph join)
var DEFAULTS = {
    frontMatter: "hide", tags: "lines", images: "first", title: "keep",
    length: "whole", paragraphs: 3, chars: 600, marker: "%%more%%", lineBreaks: "obsidian"
};

function withDefaults(opts) {
    var o = {};
    for (var k in DEFAULTS) o[k] = (opts && opts[k] !== undefined && opts[k] !== null && opts[k] !== "") ? opts[k] : DEFAULTS[k];
    return o;
}

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

// Split YAML front matter at the very top of a note from the body: {yaml, body}
function splitFrontMatter(text) {
    if (text.indexOf("---\n") !== 0) return { yaml: "", body: text };
    var end = text.indexOf("\n---", 3);
    if (end === -1) return { yaml: "", body: text };
    var after = text.indexOf("\n", end + 4);
    return { yaml: text.substring(4, end), body: after === -1 ? "" : text.substring(after + 1) };
}

function stripFrontMatter(text) {
    return splitFrontMatter(text).body;
}

// Obsidian tags: #word, #nested/tag; not headings ("# Title") and not inside words
var TAG_RE = /(^|[\s(])#[^\s#.,;:!?"'()\[\]{}<>`]+/g;

function removeTags(text, mode) {
    if (mode === "keep") return text;
    var lines = text.split("\n");
    var out = [];
    for (var i = 0; i < lines.length; i++) {
        var withoutTags = lines[i].replace(TAG_RE, "$1");
        if (lines[i].trim() !== "" && withoutTags.trim() === "") continue; // a line of only tags
        out.push(mode === "all" ? withoutTags.replace(/(\S)[ \t]{2,}(?=\S)/g, "$1 ").replace(/[ \t]+$/, "") : lines[i]);
    }
    return out.join("\n");
}

// The first non-empty line, if it is a heading: its index in lines, or -1
function titleLineIndex(lines) {
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim() === "") continue;
        return /^#{1,6}\s/.test(lines[i]) ? i : -1;
    }
    return -1;
}

function applyTitle(text, mode, path) {
    if (mode === "keep") return text;
    var lines = text.split("\n");
    var t = titleLineIndex(lines);
    if (mode === "hide" && t !== -1) lines.splice(t, 1);
    if (mode === "filename" && t === -1 && path) lines.unshift("# " + baseName(path).replace(/\.md$/i, ""), "");
    return lines.join("\n");
}

// Blocks separated by blank lines, keeping fenced code blocks whole
function splitBlocks(text) {
    var blocks = [], cur = [], inFence = false;
    var lines = text.split("\n");
    for (var i = 0; i < lines.length; i++) {
        if (/^\s*(```|~~~)/.test(lines[i])) inFence = !inFence;
        if (!inFence && lines[i].trim() === "") {
            if (cur.length) { blocks.push(cur.join("\n")); cur = []; }
        } else {
            cur.push(lines[i]);
        }
    }
    if (cur.length) blocks.push(cur.join("\n"));
    return blocks;
}

// Shorten a piece: {text, cut}
function applyLength(text, o) {
    var blocks = splitBlocks(text);
    var head = [];
    // A leading title does not count against the limit
    if (blocks.length && /^#{1,6}\s/.test(blocks[0]) && blocks[0].indexOf("\n") === -1) head.push(blocks.shift());
    var keep = [];
    if (o.length === "paragraphs") {
        var n = Math.max(1, parseInt(o.paragraphs) || 1);
        keep = blocks.slice(0, n);
    } else if (o.length === "chars") {
        var limit = Math.max(50, parseInt(o.chars) || 600), used = 0;
        for (var i = 0; i < blocks.length; i++) {
            if (used + blocks[i].length <= limit) { keep.push(blocks[i]); used += blocks[i].length; continue; }
            if (keep.length === 0) {
                // The first paragraph alone is too long: cut it at a sentence end, else at a space
                var part = blocks[i].substring(0, limit);
                var end = Math.max(part.lastIndexOf(". "), part.lastIndexOf("! "), part.lastIndexOf("? "), part.lastIndexOf("… "));
                keep.push(end > limit / 3 ? part.substring(0, end + 1) : part.substring(0, part.lastIndexOf(" ") > 0 ? part.lastIndexOf(" ") : limit));
            }
            break;
        }
    } else {
        return { text: text, cut: false };
    }
    var cut = keep.length < blocks.length || (keep.length && blocks.length && keep[keep.length - 1] !== blocks[keep.length - 1]);
    return { text: head.concat(keep).join("\n\n"), cut: cut };
}

// Cut at a line holding only the marker (checked before comments are removed)
function cutAtMarker(text, marker) {
    var lines = text.split("\n");
    for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim() === marker) return { text: lines.slice(0, i).join("\n"), cut: true };
    }
    return { text: text, cut: false };
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
function cleanMarkdown(text, lineBreaks) {
    text = text.replace(/%%[\s\S]*?%%/g, "");                     // comments
    text = text.replace(/!\[\[[^\]]*\]\]/g, "");                  // remaining embeds
    text = text.replace(/!\[[^\]]*\]\((?:[^()\s]|\([^()]*\))*\)/g, ""); // remaining image links
    text = text.replace(/\[\[([^\]]+)\]\]/g, function (m, inner) { return wikilinkText(inner); });
    text = text.replace(/^(\s*>\s*)\[![^\]]+\][+-]?\s*/gm, "$1"); // callout markers
    text = text.replace(/==([^=\n]+)==/g, "**$1**");               // highlights
    // _italic_ (Qt shows underscores as underline, Obsidian as italic); leaves snake_case alone
    text = text.replace(/(^|[^\w*_])_([^_\s](?:[^_\n]*[^_\s])?)_(?=[^\w]|$)/gm, "$1*$2*");
    text = text.replace(/\n{3,}/g, "\n\n").trim();
    return lineBreaks === "markdown" ? text : keepLineBreaks(text);
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

// All image embeds of a note, in order
function findAllImages(text) {
    var found = [];
    var rest = text, offset = 0, img;
    while ((img = findFirstImage(rest)) !== null) {
        found.push({ target: img.target, kind: img.kind, start: img.start + offset, end: img.end + offset });
        offset += img.end;
        rest = rest.substring(img.end);
    }
    return found;
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

// Shared steps for a note or quote: title, tags, length, Markdown clean-up
function renderText(text, path, o, isNote) {
    var cut = false;
    if (o.length === "marker") {
        var m = cutAtMarker(text, o.marker);
        text = m.text; cut = m.cut;
    }
    text = removeTags(text, o.tags);
    text = applyTitle(text, o.title === "filename" && !isNote ? "keep" : o.title, path);
    text = cleanMarkdown(text, "markdown");
    if (o.length === "paragraphs" || o.length === "chars") {
        var l = applyLength(text, o);
        text = l.text; cut = cut || l.cut;
    }
    if (o.lineBreaks !== "markdown") text = keepLineBreaks(text);
    if (cut) text += "\n\n…";
    return text;
}

// A Markdown note becomes one piece: images on top, the rest as Markdown
function noteToPiece(raw, path, vaultPath, index, opts) {
    var o = withDefaults(opts);
    var fm = splitFrontMatter(raw.replace(/\r\n?/g, "\n"));
    var text = fm.body;
    var found = o.images === "none" ? [] : (o.images === "all" ? findAllImages(text) : [findFirstImage(text)].filter(function (x) { return x; }));
    var images = [];
    for (var i = found.length - 1; i >= 0; i--) {
        images.unshift(resolveImage(found[i], path, vaultPath, index));
        text = text.substring(0, found[i].start) + text.substring(found[i].end);
    }
    text = renderText(text, path, o, true);
    if (o.frontMatter === "show" && fm.yaml.trim() !== "") text = "```\n" + fm.yaml.trim() + "\n```\n\n" + text;
    return { text: text, images: images, image: images.length ? images[0] : "", sourceFile: path, sourceIndex: 0 };
}

// A fortune file (entries separated by a line holding only %) becomes many pieces
function fortuneToPieces(raw, path, opts) {
    var o = withDefaults(opts);
    var text = raw.replace(/\r\n?/g, "\n");
    var entries = ("\n" + text + "\n").split(/\n%[ \t]*(?=\n)/);
    var pieces = [];
    for (var i = 0; i < entries.length; i++) {
        var entry = entries[i].trim();
        if (entry.length === 0) continue;
        pieces.push({ text: renderText(entry, path, o, false), images: [], image: "", sourceFile: path, sourceIndex: pieces.length });
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

function fileToPieces(file, vaultPath, index, opts) {
    if (extensionOf(file.path) === "md") return [noteToPiece(file.content, file.path, vaultPath, index, opts)];
    return fortuneToPieces(file.content, file.path, opts);
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

// Shell command that prints every note/quote file of a source as records.
// recursive false: only notes directly in the folder, not in its subfolders.
function loadCommand(path, recursive) {
    var q = shellQuote(path);
    var depth = recursive === false ? " -maxdepth 1" : "";
    var each = shellQuote('for f; do printf "\\036FILE:%s\\n" "$f"; cat "$f"; done');
    return "if [ -d " + q + " ]; then find " + q + " -mindepth 1" + depth + " -name '.*' -prune -o -type f -name '*.md' -exec sh -c " + each + " sh {} +; " +
           "else printf '\\036FILE:%s\\n' " + q + "; cat " + q + "; fi";
}

// Shell command that lists image files below the given folders
function imageListCommand(folders) {
    var names = [];
    for (var i = 0; i < IMAGE_EXTENSIONS.length; i++) names.push("-iname '*." + IMAGE_EXTENSIONS[i] + "'");
    var quoted = folders.map(shellQuote).join(" ");
    return "find " + quoted + " -mindepth 1 -name '.*' -prune -o -type f \\( " + names.join(" -o ") + " \\) -print 2>/dev/null; true";
}
