import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import Qt.labs.platform as Platform
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root
    
    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 15

    // Disable Plasma's default background to allow full transparency
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Configuration properties
    property var quotesFiles: plasmoid.configuration.quotesFiles
    property int rotationInterval: plasmoid.configuration.rotationInterval
    property real backgroundOpacity: plasmoid.configuration.backgroundOpacity
    property color textColor: plasmoid.configuration.textColor
    property color outlineColor: plasmoid.configuration.outlineColor
    property color backgroundColor: plasmoid.configuration.backgroundColor
    property string textFont: plasmoid.configuration.textFont
    property bool debugMode: plasmoid.configuration.debugMode

    // Debug logging helper
    function log() {
        if (debugMode) {
            var args = Array.prototype.slice.call(arguments);
            console.log.apply(console, args);
        }
    }
    
    // State properties
    property string currentQuote: plasmoid.configuration.currentQuote
    property var quotes: []  // Array of {text: string, sourceFile: string, sourceIndex: int}
    property int currentQuoteIndex: plasmoid.configuration.currentQuoteIndex
    property string currentQuoteSourceFile: plasmoid.configuration.currentQuoteSourceFile
    
    // Multi-file loading state
    property int filesLoaded: 0
    property int filesToLoad: 0
    property var tempQuotes: []
    
    // Popup state
    property var paginatedPages: []
    property bool popupDataReady: false
    property int popupInitialPage: 0
    
    // Helper function to get filename without path or extension
    function getQuotesFileName() {
        if (!currentQuoteSourceFile) {
            if (!quotesFiles || quotesFiles.length === 0) return "Quotes";
            var path = quotesFiles[0].toString();
            var filename = path.split('/').pop();
            var dotIndex = filename.lastIndexOf('.');
            if (dotIndex > 0) {
                filename = filename.substring(0, dotIndex);
            }
            return filename;
        }
        var path = currentQuoteSourceFile.toString();
        var filename = path.split('/').pop();
        var dotIndex = filename.lastIndexOf('.');
        if (dotIndex > 0) {
            filename = filename.substring(0, dotIndex);
        }
        return filename;
    }

    // Context menu actions
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("View in Context")
            icon.name: "zoom-in"
            onTriggered: {
                openViewInContext();
            }
        },
        PlasmaCore.Action {
            text: i18n("Reload Quotes from Disk")
            icon.name: "view-refresh"
            onTriggered: {
                log("Reloading quotes from disk...");
                loadFortuneFile(true);
            }
        }
    ]

    // Timer for auto-rotation
    Timer {
        id: rotationTimer
        interval: root.rotationInterval * 1000
        running: true
        repeat: true
        onTriggered: loadRandomQuote()
    }

    // File reader using executable DataSource for Plasma 6
    Plasma5Support.DataSource {
        id: fileReader
        engine: "executable"
        
        onNewData: {
            log("fileReader onNewData for source:", sourceName);
            log("  exit code:", data["exit code"]);
            
            if (data["exit code"] === 0) {
                var content = data.stdout;
                log("  content length:", content.length);
                
                // Extract the original file path from the output
                var originalPath = "";
                var fileContent = content;
                
                if (content.startsWith("FILE:")) {
                    var firstNewline = content.indexOf("\n");
                    if (firstNewline > 0) {
                        var rawPath = content.substring(5, firstNewline);
                        // Remove timestamp suffix (format: path:timestamp)
                        var lastColon = rawPath.lastIndexOf(":");
                        if (lastColon > 0) {
                            originalPath = rawPath.substring(0, lastColon);
                        } else {
                            originalPath = rawPath;
                        }
                        fileContent = content.substring(firstNewline + 1);
                    }
                }
                
                log("  original path:", originalPath);
                
                // Parse fortune file format (quotes separated by %)
                var fileQuotes = fileContent.split(/\n%\n/).map(function(q) { 
                    return q.trim(); 
                }).filter(function(q) { 
                    return q.length > 0; 
                });
                
                log("  parsed", fileQuotes.length, "quotes");
                
                // Add quotes with source tracking
                for (var i = 0; i < fileQuotes.length; i++) {
                    tempQuotes.push({
                        text: fileQuotes[i],
                        sourceFile: originalPath,
                        sourceIndex: i
                    });
                }
                
                filesLoaded++;
                log("  filesLoaded:", filesLoaded, "/", filesToLoad);
                checkAllFilesLoaded();
            } else {
                log("  error loading, stderr:", data.stderr);
                filesLoaded++;
                checkAllFilesLoaded();
            }
            // Don't manually disconnect - let DataSource handle it
        }
    }
    
    // Load and parse fortune files
    function loadFortuneFile(forceReload) {
        if (!quotesFiles || quotesFiles.length === 0) {
            currentQuote = i18n("No quotes file configured.\n\nPlease select a file in settings.");
            return;
        }
        
        log("loadFortuneFile: Loading", quotesFiles.length, "files");
        
        // Reset loading state
        filesLoaded = 0;
        filesToLoad = quotesFiles.length;
        tempQuotes = [];
        
        // Collect all commands to run simultaneously
        var commands = [];
        var timestamp = Date.now(); // Use timestamp to force unique commands
        
        for (var i = 0; i < quotesFiles.length; i++) {
            var filePath = quotesFiles[i];
            if (!filePath) continue;
            
            // If relative path, resolve to plasmoid directory
            if (!filePath.startsWith("/") && !filePath.startsWith("~") && !filePath.startsWith("file://")) {
                filePath = Qt.resolvedUrl("../../" + filePath).toString();
            } else {
                if (filePath.startsWith("~/")) {
                    filePath = filePath.replace("~", Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation));
                }
                if (!filePath.startsWith("file://")) {
                    filePath = "file://" + filePath;
                }
            }
            
            var cleanPath = filePath.toString().replace("file://", "");
            log("Preparing to load file", i, ":", cleanPath);
            
            // Create a unique command that includes the original path in a comment
            // We append a timestamp to the FILE marker to make the command unique every time
            // This ensures DataSource sees it as a new source and executes it
            var command = "echo 'FILE:" + quotesFiles[i] + ":" + timestamp + "' && head -n 10000 '" + cleanPath + "'";
            commands.push(command);
        }
        
        // Set all commands at once
        if (commands.length > 0) {
            log("Starting to load", commands.length, "files simultaneously");
            fileReader.connectedSources = commands;
        }
    }
    
    function checkAllFilesLoaded() {
        log("checkAllFilesLoaded:", filesLoaded, "/", filesToLoad);
        if (filesLoaded >= filesToLoad) {
            // All files loaded, update quotes array
            quotes = tempQuotes;
            log("All files loaded! Total quotes:", quotes.length);
            
            if (quotes.length > 0) {
                // Check if we should restore a previous quote
                if (currentQuoteIndex >= 0 && currentQuoteIndex < quotes.length) {
                    // Restore the quote
                    log("Restoring previous quote at index:", currentQuoteIndex);
                    currentQuote = quotes[currentQuoteIndex].text;
                    currentQuoteSourceFile = quotes[currentQuoteIndex].sourceFile;
                } else {
                    // Load a random quote
                    log("Loading random quote (no valid previous index)");
                    loadRandomQuote();
                }
            } else {
                currentQuote = i18n("No quotes found in files.\n\nExpected format: quotes separated by % on its own line");
            }
        }
    }

    // Load a random quote from parsed quotes
    function loadRandomQuote() {
        log("loadRandomQuote called, quotes.length:", quotes.length);
        if (quotes.length === 0) {
            // Check if files are currently being loaded
            if (filesLoaded < filesToLoad && filesToLoad > 0) {
                log("Files are still loading, waiting...");
                return;
            }
            log("No quotes loaded, calling loadFortuneFile");
            loadFortuneFile();
            return;
        }
        
        var randomIndex = Math.floor(Math.random() * quotes.length);
        log("Selected random index:", randomIndex, "current index:", currentQuoteIndex);
        currentQuoteIndex = randomIndex;
        currentQuote = quotes[randomIndex].text;
        currentQuoteSourceFile = quotes[randomIndex].sourceFile;
        log("New quote set, first 50 chars:", currentQuote.substring(0, 50));
        
        // Persist to configuration
        plasmoid.configuration.currentQuote = currentQuote;
        plasmoid.configuration.currentQuoteIndex = currentQuoteIndex;
        plasmoid.configuration.currentQuoteSourceFile = currentQuoteSourceFile;
        plasmoid.configuration.lastUpdateTime = Date.now();
        
        // Reset timer to full interval
        rotationTimer.stop();
        rotationTimer.interval = root.rotationInterval * 1000;
        rotationTimer.start();
    }
    
    // Pagination functions for View in Context popup
    function countLines(text) {
        if (!text) return 0;
        return text.split('\n').length;
    }
    
    function truncateEntry(entry, maxLines) {
        var lines = entry.split('\n');
        if (lines.length <= maxLines) {
            return entry;
        }
        var truncated = lines.slice(0, maxLines).join('\n');
        return truncated + '\n...';
    }
    
    function formatPage(entries) {
        var htmlEntries = [];
        for (var i = 0; i < entries.length; i++) {
            var entry = entries[i];
            var htmlEntry = entry.replace(/\n/g, '<br>');
            htmlEntries.push(htmlEntry);
        }
        return htmlEntries.join('<hr style="margin: 20px 0; border: none; border-top: 2px solid #888; opacity: 0.5;">');
    }
    
    // Paginate quotes and find which page contains the current quote
    function paginateFromCurrentQuote() {
        if (quotes.length === 0) {
            paginatedPages = [];
            popupDataReady = false;
            popupInitialPage = 0;
            return;
        }
        
        // Filter quotes to only show those from the current source file
        var filteredQuotes = [];
        var currentQuoteIndexInFiltered = -1;
        
        for (var i = 0; i < quotes.length; i++) {
            if (quotes[i].sourceFile === currentQuoteSourceFile) {
                filteredQuotes.push(quotes[i].text);
                if (i === currentQuoteIndex) {
                    currentQuoteIndexInFiltered = filteredQuotes.length - 1;
                }
            }
        }
        
        if (filteredQuotes.length === 0) {
            paginatedPages = [];
            popupDataReady = false;
            popupInitialPage = 0;
            return;
        }
        
        var maxLinesPerPage = 45;
        var pages = [];
        var currentPage = [];
        var currentLineCount = 0;
        var pageContainingCurrentQuote = 0;
        
        for (var i = 0; i < filteredQuotes.length; i++) {
            var entry = filteredQuotes[i];
            var entryLines = countLines(entry);
            
            // If a single entry exceeds max lines, truncate it
            if (entryLines > maxLinesPerPage) {
                entry = truncateEntry(entry, maxLinesPerPage);
                entryLines = maxLinesPerPage;
            }
            
            // Check if adding this entry would exceed page limit
            var linesNeeded = entryLines;
            if (currentPage.length > 0) {
                linesNeeded += 1; // Add 1 for the separator
            }
            
            if (currentLineCount + linesNeeded > maxLinesPerPage && currentPage.length > 0) {
                // Push current page and start a new one
                pages.push(formatPage(currentPage));
                currentPage = [entry];
                currentLineCount = entryLines;
            } else {
                // Add entry to current page
                currentPage.push(entry);
                currentLineCount += linesNeeded;
            }
            
            // Track which page contains the current quote
            if (i === currentQuoteIndexInFiltered) {
                pageContainingCurrentQuote = pages.length; // Will be the index of the page being built
            }
        }
        
        // Don't forget the last page
        if (currentPage.length > 0) {
            pages.push(formatPage(currentPage));
        }
        
        paginatedPages = pages;
        popupInitialPage = pageContainingCurrentQuote;
        popupDataReady = true;
    }
    
    // Open the View in Context popup
    function openViewInContext() {
        paginateFromCurrentQuote();
        if (contextPopup.visible) {
            // If already visible, just ensure page is correct
            fullRep.currentPageIndex = root.popupInitialPage;
        } else {
            // If opening, ensure page is reset
            fullRep.currentPageIndex = root.popupInitialPage;
            contextPopup.visible = true;
        }
    }

    // Check if we should restore or refresh quote on startup
    Component.onCompleted: {
        console.log("=== Widget Component.onCompleted ===");
        console.log("  quotesFiles:", JSON.stringify(quotesFiles));
        console.log("  quotesFile (old):", plasmoid.configuration.quotesFile);
        
        // Migration: Check if old quotesFile (singular) exists and quotesFiles is empty
        var oldQuotesFile = plasmoid.configuration.quotesFile;
        if (oldQuotesFile && oldQuotesFile.length > 0) {
            console.log(">>> MIGRATING: Found old quotesFile, converting to quotesFiles array");
            plasmoid.configuration.quotesFiles = [oldQuotesFile];
            plasmoid.configuration.quotesFile = "";  // Clear old config
            console.log(">>> Migration complete. quotesFiles is now:", JSON.stringify(plasmoid.configuration.quotesFiles));
        } else if (!quotesFiles || quotesFiles.length === 0) {
            console.log(">>> No quotes files configured, setting default");
            plasmoid.configuration.quotesFiles = ["quotes/inspirational_quotes.txt"];
            console.log(">>> Default set. quotesFiles is now:", JSON.stringify(plasmoid.configuration.quotesFiles));
        } else {
            console.log(">>> quotesFiles already configured:", JSON.stringify(quotesFiles));
        }
        
        loadFortuneFile();
        
        var timeSinceUpdate = Date.now() - plasmoid.configuration.lastUpdateTime;
        var intervalMs = root.rotationInterval * 1000;
        
        if (currentQuote && timeSinceUpdate < intervalMs && currentQuoteIndex >= 0) {
            // Quote is still fresh, keep it and adjust timer
            var remainingTime = intervalMs - timeSinceUpdate;
            rotationTimer.interval = remainingTime;
            rotationTimer.restart();
            // Reset to normal interval after first trigger
            rotationTimer.triggered.connect(function() {
                if (rotationTimer.interval !== root.rotationInterval * 1000) {
                    rotationTimer.interval = root.rotationInterval * 1000;
                }
            });
        } else {
            // Interval has passed or no quote, load fresh quote
            rotationTimer.interval = root.rotationInterval * 1000;
            rotationTimer.restart();
        }
    }

    // Watch for configuration changes
    onQuotesFilesChanged: {
        console.log("onQuotesFilesChanged: Reloading files");
        loadFortuneFile();
    }
    
    onRotationIntervalChanged: {
        log("Rotation interval changed to:", rotationInterval, "seconds");
        rotationTimer.stop();
        rotationTimer.interval = root.rotationInterval * 1000;
        rotationTimer.start();
    }

    // Popup window for View in Context
    Window {
        id: contextPopup
        flags: Qt.Window | Qt.WindowStaysOnTopHint
        modality: Qt.ApplicationModal
        title: root.getQuotesFileName()
        width: Math.max(root.width, Kirigami.Units.gridUnit * 20)
        height: Screen.height * 0.75
        
        // Center on screen when visibility changes
        onVisibleChanged: {
            if (visible) {
                x = (Screen.width - width) / 2;
                y = (Screen.height - height) / 2;
            }
        }
        
        FullRepresentation {
            id: fullRep
            anchors.fill: parent
            pages: root.paginatedPages
            dataLoaded: root.popupDataReady
            initialPageIndex: root.popupInitialPage
            textFont: root.textFont
            textColor: root.textColor
            titleText: root.getQuotesFileName()
            currentPath: root.currentQuoteSourceFile
            bookmarkDataString: plasmoid.configuration.bookmarkData
            onCloseRequested: contextPopup.visible = false
            onBookmarkDataStringChanged: {
                plasmoid.configuration.bookmarkData = bookmarkDataString
            }
            onEditFileRequested: {
                handleEditFile(sourcePath);
            }
        }
    }

    // File copying for default quotes
    Plasma5Support.DataSource {
        id: fileCopier
        engine: "executable"
        property string targetPath: ""
        property string originalPath: ""
        property string resolvedSourcePath: ""
        property bool needsCopy: false
        
        onNewData: {
            if (data["exit code"] === 0) {
                if (needsCopy) {
                    // Directory created, now copy the file
                    needsCopy = false;
                    connectedSources = ["cp '" + resolvedSourcePath + "' '" + targetPath + "'"];
                } else {
                    // File copied successfully
                    log("Copied file to:", targetPath);
                    // Update configuration to use the copied file
                    var newList = [];
                    for (var i = 0; i < quotesFiles.length; i++) {
                        if (quotesFiles[i] === originalPath) {
                            newList.push(targetPath);
                        } else {
                            newList.push(quotesFiles[i]);
                        }
                    }
                    plasmoid.configuration.quotesFiles = newList;
                    quotesFiles = newList;
                    
                    // Reload quotes
                    loadFortuneFile(true);
                    
                    // Open the copied file
                    Qt.openUrlExternally("file://" + targetPath);
                }
            } else {
                log("Error executing command:", data.stderr);
            }
            // Don't manually disconnect - let DataSource handle it
        }
    }
    
    function handleEditFile(sourcePath) {
        if (!sourcePath) return;
        
        var path = sourcePath.toString();
        
        // Check if it's an internal/default file
        var isInternal = path.indexOf("contents/common") !== -1 
                      || path.indexOf("/usr/share/plasma") !== -1
                      || path.indexOf(".local/share/plasma/plasmoids") !== -1
                      || path.indexOf("quotes/") !== -1
                      || (!path.startsWith("/") && !path.startsWith("~"));
        
        if (isInternal) {
            // Need to copy to ~/Documents/Quotes/
            var filename = path.split('/').pop();
            var targetPath = Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation) + "/Documents/Quotes/" + filename;
            
            // Resolve source path if relative
            var resolvedSource = path;
            if (!resolvedSource.startsWith("/") && !resolvedSource.startsWith("~") && !resolvedSource.startsWith("file://")) {
                resolvedSource = Qt.resolvedUrl("../../" + resolvedSource).toString().replace("file://", "");
            } else if (resolvedSource.startsWith("~/")) {
                resolvedSource = resolvedSource.replace("~", Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation));
            } else if (resolvedSource.startsWith("file://")) {
                resolvedSource = resolvedSource.replace("file://", "");
            }
            
            // Set up for copy operation
            fileCopier.targetPath = targetPath;
            fileCopier.originalPath = path;
            fileCopier.resolvedSourcePath = resolvedSource;
            fileCopier.needsCopy = true;
            
            // First create the directory
            fileCopier.connectedSources = ["mkdir -p ~/Documents/Quotes"];
        } else {
            // Just open the file
            var openPath = path;
            if (!openPath.startsWith("file://")) {
                openPath = "file://" + openPath;
            }
            Qt.openUrlExternally(openPath);
        }
    }

    // Main UI
    fullRepresentation: ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: backgroundOpacity === 0 ? "transparent" : Qt.rgba(backgroundColor.r, backgroundColor.g, backgroundColor.b, backgroundOpacity)

            Flickable {
                id: flickable
                anchors.fill: parent
                anchors.margins: 10
                anchors.bottomMargin: 30
                contentWidth: quoteText.width
                contentHeight: quoteText.height
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Text {
                    id: quoteText
                    width: flickable.width
                    text: currentQuote || i18n("Loading quote...")
                    color: textColor
                    font.family: {
                        if (textFont) {
                            var parts = textFont.split(",");
                            return parts[0] || "";
                        }
                        return "";
                    }
                    font.pointSize: {
                        if (textFont) {
                            var parts = textFont.split(",");
                            if (parts.length > 1) {
                                return parseInt(parts[1]) || 12;
                            }
                        }
                        return 12;
                    }
                    font.weight: {
                        if (textFont) {
                            var parts = textFont.split(",");
                            if (parts.length > 2) {
                                return parseInt(parts[2]) || Font.Normal;
                            }
                        }
                        return Font.Normal;
                    }
                    font.italic: {
                        if (textFont) {
                            var parts = textFont.split(",");
                            if (parts.length > 3) {
                                return parts[3] === "italic";
                            }
                        }
                        return false;
                    }
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    
                    lineHeight: 0.8
                    
                    style: Text.Outline
                    styleColor: outlineColor
                    
                    // Click to advance
                    MouseArea {
                        anchors.fill: parent
                        onClicked: loadRandomQuote()
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
            
            // View in Context button
            Text {
                id: viewInContextButton
                text: "..."
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 5
                color: textColor
                font.family: {
                    if (textFont) {
                        var parts = textFont.split(",");
                        return parts[0] || "";
                    }
                    return "";
                }
                font.pointSize: {
                    if (textFont) {
                        var parts = textFont.split(",");
                        if (parts.length > 1) {
                            return parseInt(parts[1]) || 12;
                        }
                    }
                    return 12;
                }
                font.weight: {
                    if (textFont) {
                        var parts = textFont.split(",");
                        if (parts.length > 2) {
                            return parseInt(parts[2]) || Font.Normal;
                        }
                    }
                    return Font.Normal;
                }
                font.italic: {
                    if (textFont) {
                        var parts = textFont.split(",");
                        if (parts.length > 3) {
                            return parts[3] === "italic";
                        }
                    }
                    return false;
                }
                style: Text.Outline
                styleColor: outlineColor
                opacity: viewInContextMouseArea.containsMouse ? 1.0 : 0.6
                
                MouseArea {
                    id: viewInContextMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: openViewInContext()
                }
            }
        }
    }
}
