import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "aerox3Battery"

    StyledText {
        width: parent.width
        text: "Aerox 3 Battery"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "SteelSeries Aerox 3 Wireless Gen 2 battery level, polled every 2 minutes via rivalcfg. Sends a desktop notification at 20%, 15%, 10%, and 5%. No configurable options."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: infoColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surface

        Column {
            id: infoColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            Row {
                spacing: Theme.spacingM

                DankIcon {
                    name: "info"
                    size: Theme.iconSize
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: "Requirements"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StyledText {
                text: "Reads the battery via a patched copy of rivalcfg vendored in this plugin (the released package doesn't support this mouse's USB PID yet) — no separate rivalcfg install needed. Two things still need a one-time setup, see the plugin's README:\n\n• pip install hidapi\n• a udev rule granting hidraw access to this mouse\n\nIf the bar icon shows a puzzle piece instead of a battery, hidapi isn't installed — open the popout for the exact command.\n\n• Left click: open the status popout\n• Right click: refresh immediately"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                wrapMode: Text.WordWrap
                width: parent.width
                lineHeight: 1.4
            }
        }
    }
}
