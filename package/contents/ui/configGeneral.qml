import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: generalPage

    property var cfg_quotesFiles: []
    property int cfg_rotationInterval
    property alias cfg_backgroundOpacity: backgroundOpacity.value
    property string cfg_textFont
    
    property string cfg_textColor
    property string cfg_outlineColor
    property string cfg_backgroundColor
    property bool cfg_debugMode
    
    // Separate time components
    property int hours: Math.floor(cfg_rotationInterval / 3600)
    property int minutes: Math.floor((cfg_rotationInterval % 3600) / 60)
    property int seconds: cfg_rotationInterval % 60
    
    // Update rotationInterval when component values change
    function updateRotationInterval() {
        cfg_rotationInterval = hoursSpinBox.value * 3600 + minutesSpinBox.value * 60 + secondsSpinBox.value;
    }
    
    onCfg_textColorChanged: textColorButton.buttonColor = cfg_textColor
    onCfg_outlineColorChanged: outlineColorButton.buttonColor = cfg_outlineColor
    onCfg_backgroundColorChanged: backgroundColorButton.buttonColor = cfg_backgroundColor
    
    Component.onCompleted: {
        textColorButton.buttonColor = cfg_textColor
        outlineColorButton.buttonColor = cfg_outlineColor
        backgroundColorButton.buttonColor = cfg_backgroundColor
        
        // Initialize time spinboxes
        hoursSpinBox.value = Math.floor(cfg_rotationInterval / 3600);
        minutesSpinBox.value = Math.floor((cfg_rotationInterval % 3600) / 60);
        secondsSpinBox.value = cfg_rotationInterval % 60;
        
        if (cfg_textFont) {
            var parts = cfg_textFont.split(",");
            if (parts.length > 1) {
                fontLabel.text = parts[0] + " " + parts[1] + "pt";
            }
        }
    }

    Kirigami.FormLayout {
        // Quotes Files List
        ColumnLayout {
            Kirigami.FormData.label: i18n("Quotes Files:")
            spacing: Kirigami.Units.smallSpacing
            
            ListView {
                id: filesListView
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, Kirigami.Units.gridUnit * 10)
                clip: true
                
                model: cfg_quotesFiles
                
                delegate: RowLayout {
                    width: filesListView.width
                    spacing: Kirigami.Units.smallSpacing
                    
                    Label {
                        Layout.fillWidth: true
                        text: modelData
                        elide: Text.ElideMiddle
                    }
                    
                    Button {
                        icon.name: "edit-delete"
                        text: i18n("Remove")
                        onClicked: {
                            var newList = [];
                            for (var i = 0; i < cfg_quotesFiles.length; i++) {
                                if (i !== index) {
                                    newList.push(cfg_quotesFiles[i]);
                                }
                            }
                            cfg_quotesFiles = newList;
                        }
                    }
                }
                
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: Kirigami.Theme.disabledTextColor
                    border.width: 1
                    radius: 3
                    visible: filesListView.count === 0
                    
                    Label {
                        anchors.centerIn: parent
                        text: i18n("No files selected")
                        color: Kirigami.Theme.disabledTextColor
                    }
                }
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
                icon.name: "list-add"
                text: i18n("Add File...")
                onClicked: fileDialog.open()
            }
            
            Button {
                icon.name: "edit-reset"
                text: i18n("Reset to Default")
                onClicked: {
                    cfg_quotesFiles = ["quotes/inspirational_quotes.txt"];
                }
            }
        }

        // Rotation Interval - KDE style with separate hours, minutes, seconds
        RowLayout {
            Kirigami.FormData.label: i18n("Change every:")
            
            SpinBox {
                id: hoursSpinBox
                from: 0
                to: 23
                editable: true
                onValueChanged: updateRotationInterval()
            }
            
            Label {
                text: i18n("hrs")
            }
            
            SpinBox {
                id: minutesSpinBox
                from: 0
                to: 59
                editable: true
                onValueChanged: updateRotationInterval()
            }
            
            Label {
                text: i18n("mins")
            }
            
            SpinBox {
                id: secondsSpinBox
                from: 0
                to: 59
                editable: true
                onValueChanged: updateRotationInterval()
            }
            
            Label {
                text: i18n("secs")
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

        // Debug Mode
        Kirigami.FormData.isSection: true
        
        RowLayout {
            Kirigami.FormData.label: i18n("Debug:")
            
            CheckBox {
                id: debugModeCheckBox
                text: i18n("Enable Debug Mode")
                checked: cfg_debugMode
                onCheckedChanged: cfg_debugMode = checked
            }
            
            Label {
                text: i18n("(Check logs in journalctl)")
                color: Kirigami.Theme.disabledTextColor
                font.italic: true
            }
        }
        
        Label {
            text: i18n("Warning: Debug mode generates verbose logs. Only enable for troubleshooting.")
            color: Kirigami.Theme.negativeTextColor
            visible: debugModeCheckBox.checked
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    // File Dialog - Allow multiple file selection
    FileDialog {
        id: fileDialog
        title: i18n("Select Quotes Files")
        fileMode: FileDialog.OpenFiles  // Multiple files
        nameFilters: ["Text files (*.txt)", "All files (*)"]
        currentFolder: "file://~"
        onAccepted: {
            var newFiles = [];
            for (var i = 0; i < fileDialog.selectedFiles.length; i++) {
                var filePath = fileDialog.selectedFiles[i].toString().replace("file://", "");
                // Add if not already in list
                var alreadyExists = false;
                for (var j = 0; j < cfg_quotesFiles.length; j++) {
                    if (cfg_quotesFiles[j] === filePath) {
                        alreadyExists = true;
                        break;
                    }
                }
                if (!alreadyExists) {
                    newFiles.push(filePath);
                }
            }
            // Append new files to existing list
            var combinedList = cfg_quotesFiles.slice();
            for (var i = 0; i < newFiles.length; i++) {
                combinedList.push(newFiles[i]);
            }
            cfg_quotesFiles = combinedList;
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

