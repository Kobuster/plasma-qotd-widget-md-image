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
    
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    // Timer for auto-rotation
    Timer {
        id: rotationTimer
        interval: rotationInterval * 1000
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
        currentQuote = quotes[randomIndex];
        plasmoid.configuration.currentQuote = currentQuote;
        plasmoid.configuration.lastUpdateTime = Date.now();
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
        var intervalMs = rotationInterval * 1000;
        
        if (currentQuote && timeSinceUpdate < intervalMs) {
            // Quote is still fresh, keep it
            rotationTimer.interval = intervalMs - timeSinceUpdate;
            rotationTimer.restart();
        }
        
        // Add context menu action for reloading quotes
        plasmoid.setAction("reloadQuotes", i18n("Reload Quotes from Disk"), "view-refresh");
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
        rotationTimer.interval = rotationInterval * 1000;
        rotationTimer.restart();
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
        }
    }
}
