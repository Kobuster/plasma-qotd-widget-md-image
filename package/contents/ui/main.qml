import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import Qt.labs.platform as Platform
import org.kde.plasma.plasma5support as Plasma5Support
import "../code/pieces.js" as Pieces

PlasmoidItem {
    id: root

    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 15

    // No Plasma background; the widget draws its own with configurable opacity
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Configuration (each widget on the desktop has its own)
    property var sources: plasmoid.configuration.quotesFiles      // files and folders
    property var disabledSources: plasmoid.configuration.disabledSources
    property var flatSources: plasmoid.configuration.flatSources   // folders without subfolders
    property string vaultPath: resolvePath(plasmoid.configuration.vaultPath)
    property int rotationInterval: plasmoid.configuration.rotationInterval
    property int rescanInterval: plasmoid.configuration.rescanInterval
    property real imageMaxHeight: plasmoid.configuration.imageMaxHeight
    property int textAlignment: plasmoid.configuration.textAlignment
    property real backgroundOpacity: plasmoid.configuration.backgroundOpacity
    property color textColor: plasmoid.configuration.textColor
    property color outlineColor: plasmoid.configuration.outlineColor
    property color backgroundColor: plasmoid.configuration.backgroundColor
    property string textFont: plasmoid.configuration.textFont
    property bool debugMode: plasmoid.configuration.debugMode

    // State
    property var pieces: []          // [{text, image, sourceFile, sourceIndex}]
    property var current: null      // the piece on screen
    property var shuffleBag: []      // indices not shown yet in this round
    property string statusText: i18n("Loading…")

    // Loading state
    property var pendingCommands: ({})   // command -> source index, or "images"
    property var loadedFiles: []
    property var imagePaths: []
    property int loadsLeft: 0
    property bool keepCurrentOnLoad: false

    function log() {
        if (debugMode) console.log.apply(console, Array.prototype.slice.call(arguments));
    }

    // Absolute path for a configured path: ~, file:// and paths relative to the widget package
    function resolvePath(p) {
        if (!p) return "";
        p = p.toString();
        if (p.indexOf("file://") === 0) {
            p = p.substring(7);
            try { p = decodeURIComponent(p); } catch (e) {}
        }
        if (p.indexOf("~/") === 0 || p === "~") {
            var home = Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString().replace("file://", "");
            p = home + p.substring(1);
        }
        if (p.indexOf("/") !== 0) {
            p = Qt.resolvedUrl("../../" + p).toString().replace("file://", "");
            try { p = decodeURIComponent(p); } catch (e) {}
        }
        return p.replace(/\/+$/, "");
    }

    function fontPart(i, fallback) {
        var parts = (textFont || "").split(",");
        return parts.length > i && parts[i] !== "" ? parts[i] : fallback;
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Next Piece")
            icon.name: "media-skip-forward"
            onTriggered: showNext()
        },
        PlasmaCore.Action {
            text: i18n("Open in Default App")
            icon.name: "document-open"
            onTriggered: openCurrent()
        },
        PlasmaCore.Action {
            text: i18n("Open in Obsidian")
            icon.name: "document-edit"
            onTriggered: openInObsidian()
        },
        PlasmaCore.Action {
            text: i18n("Open Containing Folder")
            icon.name: "folder-open"
            onTriggered: openFolder()
        },
        PlasmaCore.Action {
            text: i18n("Reload from Disk")
            icon.name: "view-refresh"
            onTriggered: loadSources(true)
        }
    ]

    function openCurrent() {
        if (!current) return;
        if (!Qt.openUrlExternally(Pieces.fileUrl(current.sourceFile))) openFolder();
    }

    function openFolder() {
        if (!current) return;
        Qt.openUrlExternally(Pieces.fileUrl(Pieces.dirName(current.sourceFile)));
    }

    function openInObsidian() {
        if (!current) return;
        Qt.openUrlExternally("obsidian://open?path=" + encodeURIComponent(current.sourceFile));
    }

    // Runs shell commands; each command's output arrives in onNewData
    Plasma5Support.DataSource {
        id: runner
        engine: "executable"

        onNewData: function (sourceName, data) {
            if (!(sourceName in root.pendingCommands)) return;
            var tag = root.pendingCommands[sourceName];
            delete root.pendingCommands[sourceName];
            if (data["exit code"] !== 0) log("command failed:", sourceName, data.stderr);
            var out = data.stdout || "";
            if (tag === "images") {
                root.imagePaths = out.split("\n").filter(function (l) { return l.length > 0; });
            } else {
                root.loadedFiles = root.loadedFiles.concat(Pieces.splitRecords(out));
            }
            root.loadsLeft--;
            if (root.loadsLeft === 0) root.finishLoading();
        }
    }

    // Read all sources (and the image list) from disk
    function loadSources(keepCurrent) {
        if (!sources || sources.length === 0) {
            pieces = [];
            current = null;
            statusText = i18n("No sources configured.\n\nRight-click > Configure to add files or folders.");
            return;
        }
        keepCurrentOnLoad = keepCurrent === true;
        loadedFiles = [];
        imagePaths = [];
        var commands = {};
        var stamp = Date.now();
        var roots = [];
        var off = disabledSources || [];
        var flat = flatSources || [];
        for (var i = 0; i < sources.length; i++) {
            if (off.indexOf(sources[i]) !== -1) continue;
            var path = resolvePath(sources[i]);
            if (!path) continue;
            var recursive = flat.indexOf(sources[i]) === -1;
            // The trailing no-op makes each command unique, so it runs again on reload
            commands[Pieces.loadCommand(path, recursive) + " ; : " + stamp + "-" + i] = i;
            roots.push(path);
        }
        if (roots.length === 0) {
            pieces = [];
            current = null;
            statusText = i18n("All sources are switched off.\n\nRight-click > Configure to switch one on.");
            return;
        }
        // Embedded images are looked up in the vault, or else in the sources themselves
        var imageRoots = vaultPath ? [vaultPath] : roots;
        if (imageRoots.length > 0) {
            commands[Pieces.imageListCommand(imageRoots) + " ; : " + stamp + "-images"] = "images";
        }
        pendingCommands = commands;
        loadsLeft = Object.keys(commands).length;
        log("loading", loadsLeft, "commands");
        runner.connectedSources = Object.keys(commands);
    }

    function finishLoading() {
        var index = Pieces.buildImageIndex(imagePaths);
        var all = [];
        for (var i = 0; i < loadedFiles.length; i++) {
            all = all.concat(Pieces.fileToPieces(loadedFiles[i], vaultPath, index));
        }
        log("loaded", all.length, "pieces from", loadedFiles.length, "files");
        pieces = all;
        shuffleBag = [];
        if (all.length === 0) {
            current = null;
            statusText = i18n("Nothing found in the configured sources.\n\nFolders are searched for .md notes; text files are read as quotes separated by % lines.");
            return;
        }
        // Keep showing the same piece if it still exists (reload, rescan, or Plasma restart)
        var savedFile = keepCurrentOnLoad && current ? current.sourceFile : plasmoid.configuration.currentQuoteSourceFile;
        var savedIndex = keepCurrentOnLoad && current ? current.sourceIndex : plasmoid.configuration.currentQuoteIndex;
        var fresh = keepCurrentOnLoad || (Date.now() - plasmoid.configuration.lastUpdateTime) < rotationInterval * 1000;
        if (fresh) {
            for (var j = 0; j < all.length; j++) {
                if (all[j].sourceFile === savedFile && all[j].sourceIndex === savedIndex) {
                    current = all[j];
                    return;
                }
            }
        }
        showNext();
    }

    // Next piece in shuffled order; every piece comes once before any repeats
    function showNext() {
        if (pieces.length === 0) {
            loadSources(false);
            return;
        }
        if (shuffleBag.length === 0) {
            var bag = [];
            for (var i = 0; i < pieces.length; i++) bag.push(i);
            for (var k = bag.length - 1; k > 0; k--) {
                var r = Math.floor(Math.random() * (k + 1));
                var t = bag[k]; bag[k] = bag[r]; bag[r] = t;
            }
            // Avoid showing the same piece twice in a row across rounds
            if (bag.length > 1 && current && pieces[bag[bag.length - 1]] === current) {
                var last = bag.pop(); bag.unshift(last);
            }
            shuffleBag = bag;
        }
        var bagNow = shuffleBag;
        current = pieces[bagNow.pop()];
        shuffleBag = bagNow;

        plasmoid.configuration.currentQuoteSourceFile = current.sourceFile;
        plasmoid.configuration.currentQuoteIndex = current.sourceIndex;
        plasmoid.configuration.lastUpdateTime = Date.now();
        rotationTimer.restart();
    }

    Timer {
        id: rotationTimer
        interval: Math.max(10, root.rotationInterval) * 1000
        running: true
        repeat: true
        onTriggered: showNext()
    }

    // Pick up new or changed notes without restarting Plasma
    Timer {
        interval: Math.max(1, root.rescanInterval) * 60000
        running: true
        repeat: true
        onTriggered: loadSources(true)
    }

    Component.onCompleted: loadSources(false)
    onSourcesChanged: loadSources(false)
    onDisabledSourcesChanged: loadSources(true)
    onFlatSourcesChanged: loadSources(true)
    onVaultPathChanged: loadSources(true)

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 6
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4

        Rectangle {
            anchors.fill: parent
            color: root.backgroundOpacity === 0 ? "transparent"
                 : Qt.rgba(root.backgroundColor.r, root.backgroundColor.g, root.backgroundColor.b, root.backgroundOpacity)
        }

        PieceView {
            anchors.fill: parent
            anchors.margins: 10
            text: root.current ? root.current.text : root.statusText
            imageSource: root.current && root.current.image ? Pieces.fileUrl(root.current.image) : ""
            imageMaxHeight: height * root.imageMaxHeight
            alignment: [Text.AlignLeft, Text.AlignHCenter, Text.AlignJustify][root.textAlignment] || Text.AlignHCenter
            textColor: root.textColor
            outlineColor: root.outlineColor
            fontFamily: root.fontPart(0, "")
            fontPointSize: parseInt(root.fontPart(1, "12")) || 12
            fontWeight: parseInt(root.fontPart(2, "400")) || Font.Normal
            fontItalic: root.fontPart(3, "") === "italic"
            onClicked: root.showNext()
        }
    }
}
