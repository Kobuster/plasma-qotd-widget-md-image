// Shows one piece: optional image on top, Markdown text below, scrolls when long.
// Uses only QtQuick, so it can be tested outside Plasma.
import QtQuick
import QtQuick.Controls
import QtQuick.Window

Item {
    id: view

    property string text: ""
    property url imageSource: ""
    property real imageMaxHeight: height * 0.6
    property color textColor: "white"
    property color outlineColor: "black"
    property string fontFamily: ""
    property int fontPointSize: 12
    property int fontWeight: Font.Normal
    property bool fontItalic: false
    property int alignment: Text.AlignHCenter
    property int spacing: 10

    signal clicked()

    readonly property bool hasImage: imageSource.toString() !== "" && pieceImage.status !== Image.Error

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        Item {
            id: content
            width: flick.width
            // Center short pieces vertically, let long ones scroll from the top
            height: Math.max(flick.height, column.height)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: view.clicked()
            }

            Column {
                id: column
                width: parent.width
                y: Math.max(0, (flick.height - height) / 2)
                spacing: view.hasImage && pieceText.text !== "" ? view.spacing : 0

                Image {
                    id: pieceImage
                    source: view.imageSource
                    visible: view.hasImage
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                    // Load large images scaled down to the size they are shown at
                    sourceSize.width: Math.max(1, Math.ceil(column.width * Screen.devicePixelRatio))
                    width: column.width
                    height: {
                        if (!visible || status !== Image.Ready || implicitWidth <= 0) return visible ? Math.min(view.imageMaxHeight, column.width) : 0;
                        return Math.min(view.imageMaxHeight, column.width * implicitHeight / implicitWidth);
                    }
                }

                Text {
                    id: pieceText
                    width: column.width
                    text: view.text
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                    horizontalAlignment: view.alignment
                    color: view.textColor
                    style: Text.Outline
                    styleColor: view.outlineColor
                    font.family: view.fontFamily
                    font.pointSize: view.fontPointSize
                    font.weight: view.fontWeight
                    font.italic: view.fontItalic
                    onLinkActivated: function (link) { Qt.openUrlExternally(link) }

                    HoverHandler {
                        enabled: pieceText.hoveredLink !== ""
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    // Jump back to the top whenever a new piece is shown
    onTextChanged: flick.contentY = 0
    onImageSourceChanged: flick.contentY = 0
}
