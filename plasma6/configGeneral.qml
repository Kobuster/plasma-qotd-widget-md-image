import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: generalPage

    property alias cfg_quotesFile: quotesFile.text
    property alias cfg_rotationInterval: rotationInterval.value
    property alias cfg_backgroundOpacity: backgroundOpacity.value
    property string cfg_textFont
    
    property string cfg_textColor
    property string cfg_outlineColor
    property string cfg_backgroundColor
    
    onCfg_textColorChanged: textColorButton.buttonColor = cfg_textColor
    onCfg_outlineColorChanged: outlineColorButton.buttonColor = cfg_outlineColor
    onCfg_backgroundColorChanged: backgroundColorButton.buttonColor = cfg_backgroundColor
    
    Component.onCompleted: {
        textColorButton.buttonColor = cfg_textColor
        outlineColorButton.buttonColor = cfg_outlineColor
        backgroundColorButton.buttonColor = cfg_backgroundColor
        
        if (cfg_textFont) {
            var parts = cfg_textFont.split(",");
            if (parts.length > 1) {
                fontLabel.text = parts[0] + " " + parts[1] + "pt";
            }
        }
    }

    Kirigami.FormLayout {
        // Quotes File
        RowLayout {
            Kirigami.FormData.label: i18n("Quotes File:")
            
            TextField {
                id: quotesFile
                Layout.fillWidth: true
                placeholderText: i18n("../quotes/inspirational_quotes.txt")
            }
            
            Label {
                text: "?"
                font.bold: true
                color: Kirigami.Theme.linkColor
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    
                    ToolTip.visible: containsMouse
                    ToolTip.text: i18n("Click to learn how to create custom quote files")
                    
                    onClicked: {
                        Qt.openUrlExternally("https://gitlab.com/plasma-qotd-widget/plasma-qotd-widget/-/blob/main/creating_quotes.md")
                    }
                }
            }
        }
        
        RowLayout {
            Button {
                icon.name: "document-open"
                text: i18n("Browse...")
                onClicked: fileDialog.open()
            }
            
            Button {
                icon.name: "edit-reset"
                text: i18n("Reset to Default")
                onClicked: {
                    quotesFile.text = "../quotes/inspirational_quotes.txt";
                }
            }
        }

        // Rotation Interval
        SpinBox {
            id: rotationInterval
            Kirigami.FormData.label: i18n("Rotation Interval (seconds):")
            from: 10
            to: 86400
            stepSize: 10
            editable: true
            value: cfg_rotationInterval
            
            onValueChanged: {
                cfg_rotationInterval = value;
            }
            
            textFromValue: function(value) {
                if (value < 60) return value + "s";
                if (value < 3600) return Math.floor(value / 60) + "m";
                return Math.floor(value / 3600) + "h " + Math.floor((value % 3600) / 60) + "m";
            }
            
            valueFromText: function(text) {
                var seconds = 0;
                var parts = text.replace(/[hms]/g, ' ').trim().split(/\s+/);
                if (text.indexOf('h') > -1) {
                    seconds += parseInt(parts[0] || 0) * 3600;
                    if (parts.length > 1) seconds += parseInt(parts[1] || 0) * 60;
                } else if (text.indexOf('m') > -1) {
                    seconds += parseInt(parts[0] || 0) * 60;
                } else {
                    seconds = parseInt(parts[0] || 10);
                }
                return Math.max(10, Math.min(86400, seconds));
            }
        }

        // Background Opacity
        RowLayout {
            Kirigami.FormData.label: i18n("Background Opacity:")
            
            Slider {
                id: backgroundOpacity
                Layout.fillWidth: true
                from: 0.0
                to: 1.0
                stepSize: 0.01
            }
            
            Label {
                text: Math.round(backgroundOpacity.value * 100) + "%"
                Layout.minimumWidth: 50
            }
        }

        // Font Selection
        RowLayout {
            Kirigami.FormData.label: i18n("Font:")
            
            Label {
                id: fontLabel
                Layout.fillWidth: true
                text: cfg_textFont || i18n("System Default")
            }
            
            Button {
                text: i18n("Choose...")
                onClicked: fontDialog.open()
            }
        }

        // Text Color
        RowLayout {
            Kirigami.FormData.label: i18n("Text Color:")
            
            Rectangle {
                width: 40
                height: 25
                color: textColorButton.buttonColor
                border.color: "gray"
                border.width: 1
            }
            
            Button {
                id: textColorButton
                property color buttonColor: "#FFFFFF"
                text: i18n("Choose...")
                onClicked: {
                    colorDialog.selectedColor = textColorButton.buttonColor;
                    colorDialog.targetButton = "text";
                    colorDialog.open();
                }
            }
        }

        // Outline Color
        RowLayout {
            Kirigami.FormData.label: i18n("Outline Color:")
            
            Rectangle {
                width: 40
                height: 25
                color: outlineColorButton.buttonColor
                border.color: "gray"
                border.width: 1
            }
            
            Button {
                id: outlineColorButton
                property color buttonColor: "#000000"
                text: i18n("Choose...")
                onClicked: {
                    colorDialog.selectedColor = outlineColorButton.buttonColor;
                    colorDialog.targetButton = "outline";
                    colorDialog.open();
                }
            }
        }

        // Background Color
        RowLayout {
            Kirigami.FormData.label: i18n("Background Color:")
            
            Rectangle {
                width: 40
                height: 25
                color: backgroundColorButton.buttonColor
                border.color: "gray"
                border.width: 1
            }
            
            Button {
                id: backgroundColorButton
                property color buttonColor: "#000000"
                text: i18n("Choose...")
                onClicked: {
                    colorDialog.selectedColor = backgroundColorButton.buttonColor;
                    colorDialog.targetButton = "background";
                    colorDialog.open();
                }
            }
        }
    }

    // File Dialog
    FileDialog {
        id: fileDialog
        title: i18n("Select Quotes File")
        fileMode: FileDialog.OpenFile
        nameFilters: ["Text files (*.txt)", "All files (*)"]
        currentFolder: "file://~"
        onAccepted: {
            quotesFile.text = fileDialog.selectedFile.toString().replace("file://", "");
        }
    }

    // Color Dialog
    ColorDialog {
        id: colorDialog
        title: i18n("Choose Color")
        property string targetButton: ""
        onAccepted: {
            if (targetButton === "text") {
                textColorButton.buttonColor = colorDialog.selectedColor;
                cfg_textColor = colorDialog.selectedColor.toString();
            } else if (targetButton === "outline") {
                outlineColorButton.buttonColor = colorDialog.selectedColor;
                cfg_outlineColor = colorDialog.selectedColor.toString();
            } else if (targetButton === "background") {
                backgroundColorButton.buttonColor = colorDialog.selectedColor;
                cfg_backgroundColor = colorDialog.selectedColor.toString();
            }
        }
    }

    // Font Dialog
    FontDialog {
        id: fontDialog
        title: i18n("Choose Font")
        onAccepted: {
            var f = fontDialog.selectedFont;
            cfg_textFont = f.family + "," + f.pointSize + "," + f.weight + "," + (f.italic ? "italic" : "normal");
            fontLabel.text = f.family + " " + f.pointSize + "pt";
        }
    }
}

