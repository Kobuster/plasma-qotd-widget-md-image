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
        
        // Header with title and close button
        RowLayout {
            Layout.fillWidth: true
            spacing: PlasmaCore.Units.smallSpacing
            
            PlasmaExtras.Heading {
                id: header
                level: 2
                text: fullRepRoot.titleText
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
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
        
        // Navigation controls
        RowLayout {
            Layout.fillWidth: true
            spacing: PlasmaCore.Units.smallSpacing
            
            PlasmaComponents.Button {
                id: prevButton
                text: "Previous"
                iconSource: "go-previous"
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
                iconSource: "go-next"
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
