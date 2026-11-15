// Settings page: how a note or quote is turned into what the widget shows
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: renderingPage

    property alias cfg_imageMode: imageCombo.currentIndex
    property alias cfg_imageMaxHeight: imageMaxHeightSlider.value
    property alias cfg_titleMode: titleCombo.currentIndex
    property alias cfg_tagMode: tagCombo.currentIndex
    property alias cfg_showFrontMatter: frontMatterCheck.checked
    property alias cfg_lengthMode: lengthCombo.currentIndex
    property alias cfg_lengthParagraphs: paragraphsSpin.value
    property alias cfg_lengthChars: charsSpin.value
    property string cfg_cutMarker
    property alias cfg_obsidianLineBreaks: lineBreakCheck.checked
    property alias cfg_textAlignment: alignmentCombo.currentIndex
    property alias cfg_showScrollbar: scrollbarCheck.checked

    Kirigami.FormLayout {

        ComboBox {
            id: imageCombo
            Kirigami.FormData.label: i18n("Images:")
            model: [i18n("First image on top"), i18n("All images on top"), i18n("No images")]
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Image height, at most:")
            enabled: imageCombo.currentIndex !== 2

            Slider {
                id: imageMaxHeightSlider
                Layout.fillWidth: true
                from: 0.1
                to: 1.0
                stepSize: 0.05
            }

            Label {
                text: i18n("%1% of the widget", Math.round(imageMaxHeightSlider.value * 100))
                Layout.minimumWidth: 50
            }
        }

        ComboBox {
            id: titleCombo
            Kirigami.FormData.label: i18n("Title:")
            model: [i18n("Keep the note's heading"), i18n("Hide the first heading"), i18n("File name, if the note has no heading")]
        }

        ComboBox {
            id: tagCombo
            Kirigami.FormData.label: i18n("Tags:")
            model: [i18n("Keep"), i18n("Hide lines made only of tags"), i18n("Hide all tags")]
        }

        CheckBox {
            id: frontMatterCheck
            Kirigami.FormData.label: i18n("Front matter:")
            text: i18n("Show the YAML properties")
        }

        Item { Kirigami.FormData.isSection: true }

        ComboBox {
            id: lengthCombo
            Kirigami.FormData.label: i18n("Length:")
            model: [i18n("Whole note"), i18n("First paragraphs"), i18n("About a number of characters"), i18n("Up to a cut marker")]
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Paragraphs:")
            visible: lengthCombo.currentIndex === 1

            SpinBox {
                id: paragraphsSpin
                from: 1
                to: 100
                editable: true
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Characters:")
            visible: lengthCombo.currentIndex === 2

            SpinBox {
                id: charsSpin
                from: 50
                to: 20000
                stepSize: 50
                editable: true
            }

            Label {
                text: i18n("cut at a paragraph or sentence end")
                opacity: 0.7
            }
        }

        TextField {
            Kirigami.FormData.label: i18n("Cut marker:")
            visible: lengthCombo.currentIndex === 3
            text: cfg_cutMarker
            onTextEdited: cfg_cutMarker = text
            placeholderText: "%%more%%"
            ToolTip.visible: hovered
            ToolTip.text: i18n("Put this on a line of its own in a note; the widget shows only what comes before it. %%more%% is an Obsidian comment, so Obsidian itself hides it.")
        }

        Item { Kirigami.FormData.isSection: true }

        CheckBox {
            id: lineBreakCheck
            Kirigami.FormData.label: i18n("Line breaks:")
            text: i18n("Show every line break, as Obsidian does")
            ToolTip.visible: hovered
            ToolTip.text: i18n("Off: lines inside a paragraph join, as in standard Markdown (better for prose copied from PDFs)")
        }

        ComboBox {
            id: alignmentCombo
            Kirigami.FormData.label: i18n("Text alignment:")
            model: [i18n("Left"), i18n("Centered"), i18n("Justified")]
        }

        CheckBox {
            id: scrollbarCheck
            Kirigami.FormData.label: i18n("Long pieces:")
            text: i18n("Show a scrollbar")
        }
    }
}
