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
    
    // Internal state
    property int currentPageIndex: 0
    
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
        
        // Header with title and close button
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            PlasmaExtras.Heading {
                id: header
                level: 2
                text: fullRepRoot.titleText
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
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
        
        // Navigation controls
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            PlasmaComponents.Button {
                id: prevButton
                text: "Previous"
                icon.name: "go-previous"
                enabled: currentPageIndex > 0
                onClicked: {
                    if (currentPageIndex > 0) {
                        currentPageIndex--
                    }
                }
            }
            
            Item {
                Layout.fillWidth: true
            }
            
            PlasmaComponents.Label {
                id: pageIndicator
                text: {
                    if (!dataLoaded || pages.length === 0) {
                        return "0 of 0"
                    }
                    return (currentPageIndex + 1) + " of " + pages.length
                }
                horizontalAlignment: Text.AlignHCenter
            }
            
            Item {
                Layout.fillWidth: true
            }
            
            PlasmaComponents.Button {
                id: nextButton
                text: "Next"
                icon.name: "go-next"
                enabled: currentPageIndex < (pages.length - 1)
                onClicked: {
                    if (currentPageIndex < pages.length - 1) {
                        currentPageIndex++
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
}
