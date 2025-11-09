import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import org.kde.kirigami 2.5 as Kirigami

Kirigami.FormLayout {
    id: generalPage

    property alias cfg_quotesFile: quotesFile.text
    property alias cfg_rotationInterval: rotationInterval.value
    property alias cfg_backgroundOpacity: backgroundOpacity.value
    property string cfg_textFont
    
    property string cfg_textColor
    property string cfg_outlineColor
    property string cfg_backgroundColor
    
    onCfg_textColorChanged: textColorButton.color = cfg_textColor
    onCfg_outlineColorChanged: outlineColorButton.color = cfg_outlineColor
    onCfg_backgroundColorChanged: backgroundColorButton.color = cfg_backgroundColor
    
    Component.onCompleted: {
        textColorButton.color = cfg_textColor
        outlineColorButton.color = cfg_outlineColor
        backgroundColorButton.color = cfg_backgroundColor
        
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
            placeholderText: i18n("quotes/english_quotes.txt")
        }
        
        Button {
            icon.name: "document-open"
            onClicked: fileDialog.open()
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
