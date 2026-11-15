import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-default-applications"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Rendering")
        icon: "preferences-desktop-font"
        source: "configRendering.qml"
    }
}
