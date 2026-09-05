import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Aerox 3 Battery Widget for DankMaterialShell
// Polls a SteelSeries Aerox 3 Wireless Gen 2's battery level via rivalcfg
// and displays it as a themed bar pill, matching DMS's own laptop-battery
// widget (Modules/DankBar/Widgets/Battery.qml): same Theme.getBatteryIcon()
// icon set and the same charging/low-battery/normal color rules.
//
// rivalcfg's released package doesn't recognize this mouse's USB PID yet, so
// the actual query runs a vendored, patched copy of it (see vendor/NOTICE.md)
// through scripts/battery-level.sh.
//
// Left click opens the popout with a manual refresh button. Right click
// refreshes directly, same shortcut style as the Voxtype widget.

PluginComponent {
    id: root

    property int level: 0
    property bool isCharging: false
    property bool available: false
    property bool missingDependency: false
    property bool loading: true
    property var lastChecked: null

    readonly property bool isLowBattery: available && level <= 20 && !isCharging

    // Cascading low-battery alerts, same notify-send style as DMS's own
    // first-party DankBatteryAlerts plugin. Ordered ascending so the loop
    // in checkLowBattery() below can find the deepest tier crossed.
    readonly property var lowBatteryTiers: [
        { threshold: 20, urgency: "normal", icon: "material:battery_2_bar", title: "Aerox 3 Battery Low" },
        { threshold: 15, urgency: "normal", icon: "material:battery_1_bar", title: "Aerox 3 Battery Low" },
        { threshold: 10, urgency: "critical", icon: "material:battery_alert", title: "Aerox 3 Battery Critical" },
        { threshold: 5, urgency: "critical", icon: "material:battery_alert", title: "Aerox 3 Battery Critical" }
    ]

    // Index into lowBatteryTiers of the deepest tier already notified this
    // discharge cycle; -1 means none yet. Tracking the index (not a bool
    // per tier) means a check that lands several tiers below the last one
    // notified — e.g. the widget loads for the first time already at 8% —
    // fires exactly one notification for the deepest tier reached, not one
    // per skipped tier.
    property int notifiedTier: -1

    function checkLowBattery() {
        if (!root.available)
            return;

        if (root.isCharging || root.level > root.lowBatteryTiers[0].threshold) {
            root.notifiedTier = -1;
            return;
        }

        let crossedIndex = -1;
        for (let i = 0; i < root.lowBatteryTiers.length; i++) {
            if (root.level <= root.lowBatteryTiers[i].threshold)
                crossedIndex = i;
        }

        if (crossedIndex > root.notifiedTier) {
            root.notifiedTier = crossedIndex;
            root.sendLowBatteryNotification(root.lowBatteryTiers[crossedIndex]);
        }
    }

    function sendLowBatteryNotification(tier) {
        const proc = notifyComponent.createObject(root, {
            notifyTitle: tier.title,
            notifyMessage: "Aerox 3 mouse at " + root.level + "% — plug it in to charge.",
            notifyUrgency: tier.urgency,
            notifyIcon: tier.icon
        });
        proc.running = true;
    }

    Component {
        id: notifyComponent

        Process {
            property string notifyTitle: ""
            property string notifyMessage: ""
            property string notifyUrgency: "normal"
            property string notifyIcon: "material:battery_alert"

            command: ["notify-send", "-a", "Aerox 3 Battery", "-i", notifyIcon, "-u", notifyUrgency, notifyTitle, notifyMessage]

            onExited: exitCode => {
                if (exitCode !== 0)
                    console.error("Aerox3BatteryWidget: notify-send failed with code:", exitCode);
                destroy();
            }
        }
    }

    function batteryIcon() {
        if (root.missingDependency)
            return "extension";
        return Theme.getBatteryIcon(root.level, root.isCharging, root.available);
    }

    function batteryColor() {
        if (root.missingDependency)
            return Theme.warning;
        if (!root.available)
            return Theme.widgetIconColor;
        if (root.isLowBattery)
            return Theme.error;
        if (root.isCharging)
            return Theme.primary;
        return Theme.widgetIconColor;
    }

    function parseOutput(text) {
        const trimmed = text.trim();

        // Distinct sentinel from battery-level.sh — the `hid` module isn't
        // installed, which looks identical to "mouse not found" in
        // rivalcfg's own output otherwise. See that script for why this
        // can't just be vendored away like rivalcfg itself.
        if (trimmed === "E: hidapi module not installed") {
            root.missingDependency = true;
            root.available = false;
            root.loading = false;
            root.lastChecked = new Date();
            return;
        }

        root.missingDependency = false;
        const match = trimmed.match(/^(Charging|Discharging)\s+\[[^\]]*\]\s+(\d+)\s*%/);
        if (match) {
            root.isCharging = match[1] === "Charging";
            root.level = parseInt(match[2], 10);
            root.available = true;
        } else {
            root.available = false;
        }
        root.loading = false;
        root.lastChecked = new Date();
        root.checkLowBattery();
    }

    function refresh() {
        if (!batteryProcess.running)
            batteryProcess.running = true;
    }

    // Resolved relative to this QML file so the plugin keeps working if it
    // is cloned or symlinked somewhere other than its ghq path.
    readonly property string batteryScript: Qt.resolvedUrl("scripts/battery-level.sh").toString().replace("file://", "")
    readonly property string copySetupScript: Qt.resolvedUrl("scripts/copy-setup-command.sh").toString().replace("file://", "")

    property string copyButtonLabel: "Copy Setup Command"

    function copySetupCommand() {
        if (!copySetupProcess.running)
            copySetupProcess.running = true;
    }

    Process {
        id: batteryProcess
        command: ["sh", root.batteryScript]
        stdout: StdioCollector {
            onStreamFinished: root.parseOutput(text)
        }
    }

    Process {
        id: copySetupProcess
        command: ["sh", root.copySetupScript]
        onExited: exitCode => {
            root.copyButtonLabel = exitCode === 0 ? "Copied!" : "Copy failed — no clipboard tool found";
            copyLabelResetTimer.restart();
        }
    }

    Timer {
        id: copyLabelResetTimer
        interval: 1500
        onTriggered: root.copyButtonLabel = "Copy Setup Command"
    }

    // Battery drains slowly, so a HID query every couple of minutes is
    // plenty — this isn't a live status like Voxtype's recording state.
    Timer {
        interval: 120000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    pillRightClickAction: function() {
        root.refresh();
    }

    // PopoutComponent's own header (see DMS's Modules/Plugins/PopoutComponent.qml)
    // positions the title with no reserved width and the close button
    // anchored to the right independently, so a title this long ("Aerox 3
    // Battery" at fontSizeLarge+4 bold) overlapped the close button at the
    // previous 220. 280 gives ~40px of clearance between them.
    popoutWidth: 280

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "Aerox 3 Battery"
            detailsText: root.loading ? "Checking…" : (root.missingDependency ? "Setup needed" : (root.available ? (root.isCharging ? "Charging" : "Discharging") : "Unavailable"))
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    spacing: Theme.spacingM
                    leftPadding: Theme.spacingS

                    DankIcon {
                        name: root.batteryIcon()
                        size: Theme.iconSizeLarge
                        color: root.batteryColor()
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: root.loading ? "…" : (root.available ? root.level + "%" : "—")
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                StyledText {
                    width: parent.width
                    leftPadding: Theme.spacingS
                    text: "hidapi isn't installed — this is required."
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    visible: root.missingDependency
                }

                StyledText {
                    width: parent.width
                    leftPadding: Theme.spacingS
                    text: root.available ? "" : "No supported device found — is the mouse on and connected?"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                    visible: !root.available && !root.loading && !root.missingDependency
                }

                // Covers both states above: missing hidapi and a generic
                // "not found" (which is also what a missing udev rule looks
                // like — a permissions failure that doesn't get its own
                // sentinel from battery-level.sh). setup.sh checks and fixes
                // both, so it's a single next step either way.
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: !root.available && !root.loading

                    StyledText {
                        width: parent.width
                        leftPadding: Theme.spacingS
                        text: "Run the plugin's setup script to check/install hidapi and the udev rule:"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }

                    DankButton {
                        text: root.copyButtonLabel
                        iconName: "content_copy"
                        width: parent.width
                        onClicked: root.copySetupCommand()
                    }
                }

                StyledText {
                    width: parent.width
                    leftPadding: Theme.spacingS
                    text: root.lastChecked ? "Checked " + Qt.formatTime(root.lastChecked, "hh:mm:ss") : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    visible: root.lastChecked !== null
                }

                DankButton {
                    text: "Refresh"
                    iconName: "refresh"
                    width: parent.width
                    onClicked: root.refresh()
                }
            }
        }
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: icon.implicitWidth
            implicitHeight: icon.implicitHeight
            width: implicitWidth
            height: implicitHeight

            DankIcon {
                id: icon
                name: root.batteryIcon()
                size: root.iconSize
                color: root.batteryColor()
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: icon.implicitWidth
            implicitHeight: icon.implicitHeight
            width: implicitWidth
            height: implicitHeight

            DankIcon {
                id: icon
                name: root.batteryIcon()
                size: root.iconSize
                color: root.batteryColor()
            }
        }
    }

    Component.onCompleted: {
        batteryProcess.running = true;
    }
}
