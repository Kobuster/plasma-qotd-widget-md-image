import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: fullRepRoot
    
    // Signal for close button
    signal closeRequested()
    signal editFileRequested(string sourcePath)
    
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
        if (!currentPath) return false;
        var path = currentPath.toString();
        return path.indexOf("contents/common") !== -1 
               || path.indexOf("/usr/share/plasma") !== -1
               || path.indexOf(".local/share/plasma/plasmoids") !== -1
               || path.indexOf("quotes/") !== -1  // Widget's quotes directory
               || (!path.startsWith("/") && !path.startsWith("~"));  // Relative paths
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
    Layout.minimumWidth: PlasmaCore.Units.gridUnit * 20
    Layout.minimumHeight: PlasmaCore.Units.gridUnit * 25
    Layout.preferredWidth: width
    Layout.preferredHeight: height
    
    // Background
    Rectangle {
        anchors.fill: parent
        color: PlasmaCore.Theme.backgroundColor
        border.color: PlasmaCore.Theme.textColor
        border.width: 1
        opacity: 0.95
    }
    
    // Main layout
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: PlasmaCore.Units.smallSpacing
        spacing: PlasmaCore.Units.smallSpacing
        
        // Header with title and bookmark controls
        RowLayout {
            Layout.fillWidth: true
            spacing: PlasmaCore.Units.smallSpacing
            
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
                spacing: PlasmaCore.Units.smallSpacing
                
                PlasmaComponents.ToolButton {
                    id: bookmarkToggle
                    property var activeBookmark: getCurrentBookmark()
                    iconSource: activeBookmark ? "rating" : "rating-unrated"
                    tooltip: activeBookmark ? "Remove bookmark" : "Add bookmark"
                    onClicked: {
                        if (activeBookmark) {
                            // It exists, so this click means REMOVE
                            removeBookmark();
                        } else {
                            // It doesn't exist, so this click means ADD
                            bookmarkDialog.visible = true;
                        }
                    }
                }
                
                
                PlasmaComponents.ToolButton {
                    id: viewBookmarksButton
                    iconSource: "bookmarks"
                    tooltip: "View bookmarks"
                    onClicked: {
                        // Clear existing menu items
                        bookmarksMenu.clearMenuItems();
                        
                        // Populate menu with bookmarks
                        var list = bookmarkCache[currentPath];
                        if (list && list.length > 0) {
                            for (var i = 0; i < list.length; i++) {
                                var bookmark = list[i];
                                var menuItem = bookmarkMenuItemComponent.createObject(bookmarksMenu, {
                                    "text": bookmark.note + " (Pg " + (bookmark.page + 1) + ")",
                                    "pageIndex": bookmark.page
                                });
                                bookmarksMenu.addMenuItem(menuItem);
                            }
                        } else {
                            var emptyItem = bookmarkMenuItemComponent.createObject(bookmarksMenu, {
                                "text": "No bookmarks",
                                "enabled": false
                            });
                            bookmarksMenu.addMenuItem(emptyItem);
                        }
                        
                        bookmarksMenu.open();
                    }
                    
                    PlasmaComponents.ContextMenu {
                        id: bookmarksMenu
                    }
                    
                    Component {
                        id: bookmarkMenuItemComponent
                        PlasmaComponents.MenuItem {
                            property int pageIndex: -1
                            onClicked: {
                                if (pageIndex >= 0) {
                                    currentPageIndex = pageIndex;
                                }
                            }
                        }
                    }
                }
                
                PlasmaComponents.ToolButton {
                    id: closeButton
                    iconSource: "window-close"
                    tooltip: "Close"
                    onClicked: {
                        fullRepRoot.closeRequested()
                    }
                }
            }
        }
        
        // Separator
        PlasmaCore.SvgItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            elementId: "horizontal-line"
            svg: PlasmaCore.Svg {
                imagePath: "widgets/line"
            }
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
        PlasmaCore.SvgItem {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            elementId: "horizontal-line"
            svg: PlasmaCore.Svg {
                imagePath: "widgets/line"
            }
        }
        
        // Footer: Navigation and Utilities
        ColumnLayout {
            Layout.fillWidth: true
            spacing: PlasmaCore.Units.smallSpacing
            
            // Row 1: Navigation Bar (5 buttons)
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: PlasmaCore.Units.smallSpacing
                
                PlasmaComponents.Button {
                    id: startButton
                    iconSource: "go-first"
                    tooltip: "First page"
                    enabled: currentPageIndex > 0
                    onClicked: currentPageIndex = 0
                }
                
                PlasmaComponents.Button {
                    id: prevButton
                    iconSource: "go-previous"
                    tooltip: "Previous page"
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
                    Layout.minimumWidth: PlasmaCore.Units.gridUnit * 6
                }
                
                PlasmaComponents.Button {
                    id: nextButton
                    iconSource: "go-next"
                    tooltip: "Next page"
                    enabled: currentPageIndex < (pages.length - 1)
                    onClicked: {
                        if (currentPageIndex < pages.length - 1) {
                            currentPageIndex++
                        }
                    }
                }
                
                PlasmaComponents.Button {
                    id: endButton
                    iconSource: "go-last"
                    tooltip: "Last page"
                    enabled: currentPageIndex < (pages.length - 1)
                    onClicked: currentPageIndex = pages.length - 1
                }
            }
            
            // Row 2: Utilities Bar
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: PlasmaCore.Units.smallSpacing
                
                PlasmaComponents.TextField {
                    id: goToPageField
                    placeholderText: "Page..."
                    Layout.preferredWidth: PlasmaCore.Units.gridUnit * 5
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
                    iconSource: "document-edit"
                    text: "Edit"
                    tooltip: isInternalFile ? "Edit (will copy to ~/Documents/Quotes/)" : "Edit custom fortune file"
                    onClicked: {
                        if (currentPath) {
                            editFileRequested(currentPath);
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
    
    // Scroll to top when page changes
    onCurrentPageIndexChanged: {
        flickable.contentY = 0
    }
    
    // Bookmark Dialog
    Popup {
        id: bookmarkDialog
        
        parent: Overlay.overlay
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        width: PlasmaCore.Units.gridUnit * 12
        padding: PlasmaCore.Units.largeSpacing
        
        // Center on screen
        x: (parent.width - width) / 2
        y: parent.height * 0.15
        
        background: Rectangle {
            color: PlasmaCore.Theme.backgroundColor
            border.color: PlasmaCore.Theme.textColor
            border.width: 1
            radius: PlasmaCore.Units.smallSpacing
        }
        
        ColumnLayout {
            spacing: PlasmaCore.Units.largeSpacing
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
                spacing: PlasmaCore.Units.smallSpacing
                
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
