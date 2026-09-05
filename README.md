# dms-aerox3-battery-widget

DankMaterialShell (DMS) widget that shows the battery level of a
SteelSeries Aerox 3 Wireless Gen 2 mouse in the bar, styled to match DMS's
own laptop-battery widget (same icon set and color rules). Works over both
the 2.4GHz wireless dongle (USB PID `1038:1890`) and a direct USB cable
(`1038:1892`) — the mouse has no Bluetooth mode.

- **Left click**: open a popout with the level, charging state, and a
  refresh button
- **Right click**: refresh immediately
- Polls every 2 minutes otherwise
- Sends a desktop notification (`notify-send`) the first time the level
  drops to 20%, 15%, 10%, and 5% each discharge cycle — normal urgency at
  20/15%, critical at 10/5%. Resets once charging starts or the level
  recovers above 20%, same style as DMS's own first-party
  `DankBatteryAlerts` plugin.
- If a dependency below is missing, the bar icon switches to a distinct
  puzzle-piece icon (instead of looking like the mouse is just off) and the
  popout tells you what to install.

## How it reads the battery

This mouse's USB PIDs aren't recognized by any released version of
[rivalcfg](https://github.com/flozz/rivalcfg) (the tool that actually talks
to the mouse over HID) — support exists only on an unmerged branch, which
also needed a small core fix beyond just adding the device. Rather than
requiring you to find, clone, and patch that branch yourself, this plugin
**vendors a pinned copy of it** in `vendor/rivalcfg/` — see
[`vendor/NOTICE.md`](vendor/NOTICE.md) for exactly what's vendored, why, and
how to re-sync it if the upstream PR ever merges. You do not need to install
or clone rivalcfg separately.

## Requirements

Two things *can't* be vendored and need a one-time setup step:

1. **The `hid` Python module** (PyPI package `hidapi`) — a compiled C
   extension wrapping the system `hidapi` library, so unlike rivalcfg it
   can't be shipped as plain source in this repo.

   ```bash
   pip install --user hidapi
   ```

   If the widget's bar icon shows a puzzle-piece instead of a battery, this
   is almost certainly why — open the popout for the exact command.

2. **A udev rule** granting your user unprivileged `hidraw` access to the
   mouse (without it, every HID read fails with a permissions error
   regardless of whether `hid` is installed). Create
   `/etc/udev/rules.d/99-steelseries-aerox3-gen2.rules`:

   ```
   SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1890", MODE="0666"
   SUBSYSTEM=="usb",    ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1890", MODE="0666"
   SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1892", MODE="0666"
   SUBSYSTEM=="usb",    ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1892", MODE="0666"
   ```

   Then reload udev and reconnect the mouse:

   ```bash
   sudo udevadm control --reload-rules
   sudo udevadm trigger
   ```

   (If you already use rivalcfg for other SteelSeries gear and have run
   `rivalcfg --update-udev` before, you likely already have a rule covering
   these PIDs and can skip this.)

## Install

Symlink this repo into your DMS plugins directory:

```bash
ln -s /path/to/dms-aerox3-battery-widget ~/.config/DankMaterialShell/plugins/aerox3Battery
```

## Reload after edits

DMS plugins are not hot-reloaded automatically. After editing
`Aerox3Battery.qml`, run:

```bash
qs -p /usr/share/quickshell/dms ipc call plugins reload aerox3Battery
```
