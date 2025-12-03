import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: fullRepRoot
    
    // Signal for close button
    signal closeRequested()
    
    // Properties passed from main.qml
    property var pages: []
    property bool dataLoaded: false
    property int initialPageIndex: 0
    
    // Font properties from main widget
    property string textFont: ""
    property color textColor: "#000000"
    property string titleText: "Quotes"
    
    // Bookmark properties
    property string currentPath: ""
    property string bookmarkDataString: "{}"
    property var bookmarkCache: JSON.parse(bookmarkDataString || "{}")
    
    // Internal state
    property int currentPageIndex: 0
    
    // Read-only detection for edit button
    function checkIsInternal() {
        return currentPath.indexOf("contents/common") !== -1 
               || currentPath.indexOf("/usr/share/plasma") !== -1
               || currentPath.indexOf(".local/share/plasma/plasmoids") !== -1;
    }
    
    property bool isInternalFile: checkIsInternal()
    
    // Bookmark management functions
    function getCurrentBookmark() {
        var path = currentPath;
        var list = bookmarkCache[path] || [];
        // Find object with matching page
        for (var i = 0; i < list.length; i++) {
            if (list[i].page === currentPageIndex) return list[i];
        }
        return null;
    }
    
    function addBookmark(noteText) {
        var path = currentPath;
        if (!bookmarkCache[path]) bookmarkCache[path] = [];
        
        // Avoid duplicates
        if (!getCurrentBookmark()) {
            bookmarkCache[path].push({
                "page": currentPageIndex,
                "note": noteText
            });
            // Sort by page number
            bookmarkCache[path].sort(function(a,b) { return a.page - b.page; });
            saveBookmarks();
        }
    }
    
    function removeBookmark() {
        var path = currentPath;
        var list = bookmarkCache[path] || [];
        
        // Filter out the current page
        bookmarkCache[path] = list.filter(function(item) { return item.page !== currentPageIndex; });
        saveBookmarks();
    }
    
    function saveBookmarks() {
        bookmarkDataString = JSON.stringify(bookmarkCache);
        // Force UI refresh
        bookmarkCache = JSON.parse(bookmarkDataString);
    }
    
    function isBookmarked(index) {
        var list = bookmarkCache[currentPath];
        if (!list) return false;
        for (var i = 0; i < list.length; i++) {
            if (list[i].page === index) return true;
        }
        return false;
    }
    
    // Set minimum dimensions (used when in layout contexts)
    Layout.minimumWidth: Kirigami.Units.gridUnit * 20
    Layout.minimumHeight: Kirigami.Units.gridUnit * 25
    Layout.preferredWidth: width
    Layout.preferredHeight: height
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: Kirigami.Theme.backgroundColor
        border.color: Kirigami.Theme.textColor
        border.width: 1
        opacity: 0.95
    }
    
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        
        // Header with title and bookmark controls
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            PlasmaExtras.Heading {
                id: header
                level: 2
                text: fullRepRoot.titleText
                Layout.fillWidth: false
                horizontalAlignment: Text.AlignLeft
            }
            
            Item {
                Layout.fillWidth: true
            }
            
            // Bookmark controls
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents.ToolButton {
                    id: bookmarkToggle
                    property var activeBookmark: getCurrentBookmark()
                    icon.name: activeBookmark ? "rating" : "rating-unrated"
                    PlasmaComponents.ToolTip.text: activeBookmark ? "Remove bookmark" : "Add bookmark"
                    PlasmaComponents.ToolTip.visible: hovered
                    onClicked: {
                        if (activeBookmark) {
                            // It exists, so this click means REMOVE
                            removeBookmark();
                        } else {
                            // It doesn't exist, so this click means ADD
                            bookmarkDialog.open();
                        }
                    }
                }
                
                PlasmaComponents.ToolButton {
                    id: viewBookmarksButton
                    icon.name: "bookmarks"
                    PlasmaComponents.ToolTip.text: "View bookmarks"
                    PlasmaComponents.ToolTip.visible: hovered
                    onClicked: bookmarksMenu.open()
                    
                    PlasmaComponents.Menu {
                        id: bookmarksMenu
                        
                        Instantiator {
                            model: {
                                var list = bookmarkCache[currentPath];
                                return list ? list : [];
                            }
                            delegate: PlasmaComponents.MenuItem {
                                text: modelData.note + " (Pg " + (modelData.page + 1) + ")"
                                onClicked: {
                                    currentPageIndex = modelData.page;
                                }
                            }
                            onObjectAdded: function(index, object) {
                                bookmarksMenu.insertItem(index, object)
                            }
                            onObjectRemoved: function(index, object) {
                                bookmarksMenu.removeItem(object)
                            }
                        }
                        
                        PlasmaComponents.MenuItem {
                            text: bookmarksMenu.count === 0 ? "No bookmarks" : ""
                            visible: bookmarksMenu.count === 0
                            enabled: false
                        }
                    }
                }
                
                PlasmaComponents.ToolButton {
                    id: closeButton
                    icon.name: "window-close"
                    PlasmaComponents.ToolTip.text: "Close"
                    PlasmaComponents.ToolTip.visible: hovered
                    onClicked: {
                        fullRepRoot.closeRequested()
                    }
                }
            }
        }
        
        // Separator
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        
        // Content viewer with scroll
        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: contentLabel.height
            clip: true
            
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
            
            Text {
                id: contentLabel
                width: flickable.width - 10
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                color: fullRepRoot.textColor
                font.family: {
                    if (fullRepRoot.textFont) {
                        var parts = fullRepRoot.textFont.split(",");
                        return parts[0] || "";
                    }
                    return "";
                }
                font.pointSize: {
                    if (fullRepRoot.textFont) {
                        var parts = fullRepRoot.textFont.split(",");
                        if (parts.length > 1) {
                            return parseInt(parts[1]) || 12;
                        }
                    }
                    return 12;
                }
                font.weight: {
                    if (fullRepRoot.textFont) {
                        var parts = fullRepRoot.textFont.split(",");
                        if (parts.length > 2) {
                            return parseInt(parts[2]) || Font.Normal;
                        }
                    }
                    return Font.Normal;
                }
                font.italic: {
                    if (fullRepRoot.textFont) {
                        var parts = fullRepRoot.textFont.split(",");
                        if (parts.length > 3) {
                            return parts[3] === "italic";
                        }
                    }
                    return false;
                }
                text: {
                    if (!dataLoaded) {
                        return "<i>Loading fortunes...</i>"
                    }
                    if (pages.length === 0) {
                        return "<i>No fortunes available</i>"
                    }
                    if (currentPageIndex >= 0 && currentPageIndex < pages.length) {
                        return pages[currentPageIndex]
                    }
                    return "<i>Error: Invalid page</i>"
                }
            }
        }
        
        // Separator
        Kirigami.Separator {
            Layout.fillWidth: true
        }
        
        // Footer: Navigation and Utilities
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            // Row 1: Navigation Bar (5 buttons)
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents.Button {
                    id: startButton
                    icon.name: "go-first"
                    PlasmaComponents.ToolTip.text: "First page"
                    PlasmaComponents.ToolTip.visible: hovered
                    enabled: currentPageIndex > 0
                    onClicked: currentPageIndex = 0
                }
                
                PlasmaComponents.Button {
                    id: prevButton
                    icon.name: "go-previous"
                    PlasmaComponents.ToolTip.text: "Previous page"
                    PlasmaComponents.ToolTip.visible: hovered
                    enabled: currentPageIndex > 0
                    onClicked: {
                        if (currentPageIndex > 0) {
                            currentPageIndex--
                        }
                    }
                }
                
                PlasmaComponents.Label {
                    id: pageIndicator
                    text: {
                        if (!dataLoaded || pages.length === 0) {
                            return "Page 0 of 0"
                        }
                        return "Page " + (currentPageIndex + 1) + " of " + pages.length
                    }
                    horizontalAlignment: Text.AlignHCenter
                    Layout.minimumWidth: Kirigami.Units.gridUnit * 6
                }
                
                PlasmaComponents.Button {
                    id: nextButton
                    icon.name: "go-next"
                    PlasmaComponents.ToolTip.text: "Next page"
                    PlasmaComponents.ToolTip.visible: hovered
                    enabled: currentPageIndex < (pages.length - 1)
                    onClicked: {
                        if (currentPageIndex < pages.length - 1) {
                            currentPageIndex++
                        }
                    }
                }
                
                PlasmaComponents.Button {
                    id: endButton
                    icon.name: "go-last"
                    PlasmaComponents.ToolTip.text: "Last page"
                    PlasmaComponents.ToolTip.visible: hovered
                    enabled: currentPageIndex < (pages.length - 1)
                    onClicked: currentPageIndex = pages.length - 1
                }
            }
            
            // Row 2: Utilities Bar
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents.TextField {
                    id: goToPageField
                    placeholderText: "Page..."
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 5
                    validator: IntValidator {
                        bottom: 1
                        top: pages.length > 0 ? pages.length : 1
                    }
                    onAccepted: {
                        var target = parseInt(text);
                        if (target >= 1 && target <= pages.length) {
                            currentPageIndex = target - 1; // Convert 1-based to 0-based
                        }
                        text = "";
                    }
                }
                
                PlasmaComponents.Button {
                    text: "Go"
                    enabled: goToPageField.text.length > 0
                    onClicked: {
                        goToPageField.accepted();
                    }
                }
                
                PlasmaComponents.Button {
                    id: editButton
                    icon.name: "document-edit"
                    text: "Edit"
                    enabled: !isInternalFile
                    PlasmaComponents.ToolTip.text: isInternalFile ? "Cannot edit default fortunes" : "Edit custom fortune file"
                    PlasmaComponents.ToolTip.visible: hovered
                    onClicked: {
                        if (!isInternalFile && currentPath) {
                            Qt.openUrlExternally(currentPath)
                        }
                    }
                }
            }
        }
    }
    
    // Set to initial page when popup is opened
    Component.onCompleted: {
        currentPageIndex = initialPageIndex
    }
    
    // Watch for initialPageIndex changes (when popup reopens)
    onInitialPageIndexChanged: {
        currentPageIndex = initialPageIndex
    }
    
    // Bookmark Dialog
    Popup {
        id: bookmarkDialog
        
        parent: Overlay.overlay
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        width: Kirigami.Units.gridUnit * 12
        padding: Kirigami.Units.largeSpacing
        
        // Center on screen
        x: (parent.width - width) / 2
        y: parent.height * 0.15
        
        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            border.color: Kirigami.Theme.textColor
            border.width: 1
            radius: Kirigami.Units.smallSpacing
        }
        
        ColumnLayout {
            spacing: Kirigami.Units.largeSpacing
            anchors.fill: parent
            
            PlasmaExtras.Heading {
                level: 3
                text: "Add Bookmark"
                Layout.fillWidth: true
            }
            
            PlasmaComponents.Label {
                text: "Enter a short description:"
            }
            
            PlasmaComponents.TextField {
                id: bookmarkNoteField
                Layout.fillWidth: true
                maximumLength: 50
                placeholderText: "e.g., Chapter 1"
                focus: true
                onAccepted: {
                    if (text.length > 0) {
                        saveBookmarkButton.clicked();
                    }
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: Kirigami.Units.smallSpacing
                
                PlasmaComponents.Button {
                    text: "Cancel"
                    onClicked: {
                        bookmarkDialog.close();
                        bookmarkNoteField.text = "";
                    }
                }
                
                PlasmaComponents.Button {
                    id: saveBookmarkButton
                    text: "Save"
                    enabled: bookmarkNoteField.text.length > 0
                    onClicked: {
                        addBookmark(bookmarkNoteField.text);
                        bookmarkDialog.close();
                        bookmarkNoteField.text = "";
                    }
                }
            }
        }
        
        onOpened: {
            bookmarkNoteField.forceActiveFocus();
        }
    }
}
