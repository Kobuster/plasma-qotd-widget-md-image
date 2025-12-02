import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kio 1.0 as KIO

Item {
    id: root

    // Configuration properties
    property string quotesFile: plasmoid.configuration.quotesFile
    property int rotationInterval: plasmoid.configuration.rotationInterval
    property real backgroundOpacity: plasmoid.configuration.backgroundOpacity
    property color textColor: plasmoid.configuration.textColor
    property color outlineColor: plasmoid.configuration.outlineColor
    property color backgroundColor: plasmoid.configuration.backgroundColor
    property string textFont: plasmoid.configuration.textFont
    
    // State properties
    property string currentQuote: plasmoid.configuration.currentQuote
    property var quotes: []
    property int currentQuoteIndex: -1
    
    // Popup state
    property var paginatedPages: []
    property bool popupDataReady: false
    property int popupInitialPage: 0
    
    // Helper function to get filename without path or extension
    function getQuotesFileName() {
        if (!quotesFile) return "Quotes";
        var path = quotesFile.toString();
        // Remove path
        var filename = path.split('/').pop();
        // Remove extension
        var dotIndex = filename.lastIndexOf('.');
        if (dotIndex > 0) {
            filename = filename.substring(0, dotIndex);
        }
        return filename;
    }
    
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Timer for auto-rotation
    Timer {
        id: rotationTimer
        interval: root.rotationInterval * 1000
        running: true
        repeat: true
        onTriggered: loadRandomQuote()
    }

    // Load and parse fortune file
    function loadFortuneFile(forceReload) {
        if (!quotesFile) {
            currentQuote = i18n("No quotes file configured.\n\nPlease select a file in settings.");
            return;
        }
        
        var filePath = quotesFile;
        
        // If relative path, resolve to plasmoid directory
        if (!filePath.startsWith("/") && !filePath.startsWith("~") && !filePath.startsWith("file://")) {
            filePath = Qt.resolvedUrl("../../" + filePath).toString();
        } else {
            if (filePath.startsWith("~/")) {
                filePath = filePath.replace("~", StandardPaths.writableLocation(StandardPaths.HomeLocation));
            }
            if (!filePath.startsWith("file://")) {
                filePath = "file://" + filePath;
            }
        }
        
        if (forceReload) {
            // Force reload by disconnecting first, then setting new source
            if (fileReader.source) {
                var oldSource = fileReader.source;
                var oldFilePath = oldSource.toString().replace("file://", "");
                var oldCommand = "if file -b --mime-type '" + oldFilePath + "' | grep -q '^text/'; then head -n 10000 '" + oldFilePath + "'; else echo 'BINARY_FILE_ERROR'; fi";
                fileReader.disconnectSource(oldCommand);
            }
        }
        
        fileReader.source = filePath;
    }

    // Load a random quote from parsed quotes
    function loadRandomQuote() {
        if (quotes.length === 0) {
            loadFortuneFile();
            return;
        }
        
        var randomIndex = Math.floor(Math.random() * quotes.length);
        currentQuoteIndex = randomIndex;
        currentQuote = quotes[randomIndex];
        plasmoid.configuration.currentQuote = currentQuote;
        plasmoid.configuration.lastUpdateTime = Date.now();
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
        
        var maxLinesPerPage = 45;
        var pages = [];
        var currentPage = [];
        var currentLineCount = 0;
        var pageContainingCurrentQuote = 0;
        
        for (var i = 0; i < quotes.length; i++) {
            var entry = quotes[i];
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
            if (i === currentQuoteIndex) {
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
        contextPopup.visible = true;
    }
    
    // File reader component
    PlasmaCore.DataSource {
        id: fileReader
        engine: "executable"
        property string source: ""
        
        onSourceChanged: {
            if (source) {
                var filePath = source.toString().replace("file://", "");
                // First check if file is text using 'file' utility, then read up to 10000 lines
                connectedSources = ["if file -b --mime-type '" + filePath + "' | grep -q '^text/'; then head -n 10000 '" + filePath + "'; else echo 'BINARY_FILE_ERROR'; fi"];
            }
        }
        
        onNewData: {
            if (data["exit code"] === 0) {
                var content = data.stdout;
                
                // Check for binary file error
                if (content.indexOf("BINARY_FILE_ERROR") === 0) {
                    currentQuote = i18n("Error: Selected file appears to be binary.\n\nPlease select a text file.");
                    disconnectSource(sourceName);
                    return;
                }
                
                // Parse fortune file format (quotes separated by %)
                quotes = content.split(/\n%\n/).map(function(q) { 
                    return q.trim(); 
                }).filter(function(q) { 
                    return q.length > 0; 
                });
                
                if (quotes.length > 0) {
                    loadRandomQuote();
                } else {
                    currentQuote = i18n("No quotes found in file.\n\nExpected format: quotes separated by % on its own line");
                }
            } else {
                currentQuote = i18n("Error loading file:\n%1", source.replace("file://", ""));
            }
            disconnectSource(sourceName);
        }
    }

    // Check if we should restore or refresh quote on startup
    Component.onCompleted: {
        loadFortuneFile();
        
        var timeSinceUpdate = Date.now() - plasmoid.configuration.lastUpdateTime;
        var intervalMs = root.rotationInterval * 1000;
        
        if (currentQuote && timeSinceUpdate < intervalMs) {
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
        
        // Add context menu action for View in Context
        plasmoid.setAction("viewInContext", "View in Context", "zoom-in");

        // Add context menu action for reloading quotes
        plasmoid.setAction("reloadQuotes", i18n("Reload Quotes from Disk"), "view-refresh");
        
    }
    
    function action_viewInContext() {
        openViewInContext();
    }
    
    // Popup dialog for View in Context
    PlasmaCore.Dialog {
        id: contextPopup
        flags: Qt.Window | Qt.WindowStaysOnTopHint
        hideOnWindowDeactivate: true
        location: PlasmaCore.Types.Floating
        
        // Center on screen when visibility changes
        onVisibleChanged: {
            if (visible) {
                var screenGeom = plasmoid.screenGeometry;
                x = screenGeom.x + (screenGeom.width - mainItem.width) / 2;
                y = screenGeom.y + (screenGeom.height - mainItem.height) / 2;
            }
        }
        
        mainItem: FullRepresentation {
            width: Math.max(root.width, PlasmaCore.Units.gridUnit * 20)  // Use parent widget width with minimum
            height: plasmoid.screenGeometry.height * 0.75  // 75% of screen height
            pages: root.paginatedPages
            dataLoaded: root.popupDataReady
            initialPageIndex: root.popupInitialPage
            textFont: root.textFont
            textColor: root.textColor
            titleText: root.getQuotesFileName()
            onCloseRequested: contextPopup.visible = false
        }
    }
    
    function action_reloadQuotes() {
        console.log("Reloading quotes from disk...");
        quotes = [];  // Clear existing quotes
        // Force reload by clearing the source first, then reloading
        fileReader.source = "";
        loadFortuneFile(true);  // Reload from file with force flag
    }

    // Watch for configuration changes
    onQuotesFileChanged: {
        loadFortuneFile();
    }
    
    onRotationIntervalChanged: {
        console.log("Rotation interval changed to:", rotationInterval, "seconds");
        rotationTimer.stop();
        rotationTimer.interval = root.rotationInterval * 1000;
        rotationTimer.start();
    }

    // Main UI
    ColumnLayout {
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
