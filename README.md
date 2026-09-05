# dms-aerox3-battery-widget

DankMaterialShell (DMS) widget that shows the battery level of a
SteelSeries Aerox 3 Wireless Gen 2 mouse in the bar, styled to match DMS's
own laptop-battery widget (same icon set and color rules).

- **Left click**: open a popout with the level, charging state, and a
  refresh button
- **Right click**: refresh immediately
- Polls every 2 minutes otherwise
- Sends a desktop notification (`notify-send`) the first time the level
  drops to 20%, 15%, 10%, and 5% each discharge cycle — normal urgency at
  20/15%, critical at 10/5%. Resets once charging starts or the level
  recovers above 20%, same style as DMS's own first-party
  `DankBatteryAlerts` plugin.

## Requirement

The released `rivalcfg` package (4.17.0) doesn't recognize this mouse's USB
PID (`1038:1890`) — Gen 2 support lives on flozz/rivalcfg's
`device_aerox3_wireless_gen2` branch, unmerged upstream. This plugin runs
that branch directly as `python3 -m rivalcfg`, expected at:

```
~/ghq/github.com/flozz/rivalcfg
```

checked out on `device_aerox3_wireless_gen2`. If your checkout lives
elsewhere, edit the `cd` path in `scripts/battery-level.sh`.

## Install

Symlink this repo into your DMS plugins directory:

```bash
ln -s /path/to/dms-aerox3-battery-widget ~/.config/DankMaterialShell/plugins/Aerox3BatteryWidget
```

## Reload after edits

DMS plugins are not hot-reloaded automatically. After editing
`Aerox3Battery.qml`, run:

```bash
qs -p /usr/share/quickshell/dms ipc call plugins reload Aerox3BatteryWidget
```
