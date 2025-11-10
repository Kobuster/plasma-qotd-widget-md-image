import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import org.kde.kirigami 2.5 as Kirigami

Kirigami.FormLayout {
    id: generalPage

    property alias cfg_quotesFile: quotesFile.text
    property int cfg_rotationInterval
    property alias cfg_backgroundOpacity: backgroundOpacity.value
    property string cfg_textFont
    
    property string cfg_textColor
    property string cfg_outlineColor
    property string cfg_backgroundColor
    
    // Separate time components
    property int hours: Math.floor(cfg_rotationInterval / 3600)
    property int minutes: Math.floor((cfg_rotationInterval % 3600) / 60)
    property int seconds: cfg_rotationInterval % 60
    
    // Update rotationInterval when component values change
    function updateRotationInterval() {
        cfg_rotationInterval = hoursSpinBox.value * 3600 + minutesSpinBox.value * 60 + secondsSpinBox.value;
    }
    
    onCfg_textColorChanged: textColorButton.color = cfg_textColor
    onCfg_outlineColorChanged: outlineColorButton.color = cfg_outlineColor
    onCfg_backgroundColorChanged: backgroundColorButton.color = cfg_backgroundColor
    
    Component.onCompleted: {
        textColorButton.color = cfg_textColor
        outlineColorButton.color = cfg_outlineColor
        backgroundColorButton.color = cfg_backgroundColor
        
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

    // Quotes File
    RowLayout {
        Kirigami.FormData.label: i18n("Quotes File:")
        
        TextField {
            id: quotesFile
            Layout.fillWidth: true
            placeholderText: i18n("quotes/inspirational_quotes.txt")
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
                quotesFile.text = "quotes/inspirational_quotes.txt";
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
            color: textColorButton.color
            border.color: "gray"
            border.width: 1
        }
        
        Button {
            id: textColorButton
            property color color: "#FFFFFF"
            text: i18n("Choose...")
            onClicked: {
                colorDialog.currentColor = textColorButton.color;
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
            color: outlineColorButton.color
            border.color: "gray"
            border.width: 1
        }
        
        Button {
            id: outlineColorButton
            property color color: "#000000"
            text: i18n("Choose...")
            onClicked: {
                colorDialog.currentColor = outlineColorButton.color;
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
            color: backgroundColorButton.color
            border.color: "gray"
            border.width: 1
        }
        
        Button {
            id: backgroundColorButton
            property color color: "#000000"
            text: i18n("Choose...")
            onClicked: {
                colorDialog.currentColor = backgroundColorButton.color;
                colorDialog.targetButton = "background";
                colorDialog.open();
            }
        }
    }

    // File Dialog
    FileDialog {
        id: fileDialog
        title: i18n("Select Quotes File")
        selectFolder: false
        nameFilters: ["Text files (*.txt)", "All files (*)"]
        folder: "file://~"
        onAccepted: {
            quotesFile.text = fileDialog.fileUrl.toString().replace("file://", "");
        }
    }

    // Color Dialog
    ColorDialog {
        id: colorDialog
        title: i18n("Choose Color")
        property string targetButton: ""
        onAccepted: {
            if (targetButton === "text") {
                textColorButton.color = colorDialog.color;
                cfg_textColor = colorDialog.color.toString();
            } else if (targetButton === "outline") {
                outlineColorButton.color = colorDialog.color;
                cfg_outlineColor = colorDialog.color.toString();
            } else if (targetButton === "background") {
                backgroundColorButton.color = colorDialog.color;
                cfg_backgroundColor = colorDialog.color.toString();
            }
        }
    }

    // Font Dialog
    FontDialog {
        id: fontDialog
        title: i18n("Choose Font")
        onAccepted: {
            var f = fontDialog.font;
            cfg_textFont = f.family + "," + f.pointSize + "," + f.weight + "," + (f.italic ? "italic" : "normal");
            fontLabel.text = f.family + " " + f.pointSize + "pt";
        }
    }
}
