#!/bin/sh
# Prints rivalcfg's `--battery-level` output for the Aerox 3 Wireless Gen 2.
#
# The mouse's USB PIDs (1038:1890 wireless, 1038:1892 wired) aren't
# recognized by any released rivalcfg (4.17.0 on PyPI predates Gen 2
# support), and the fork branch that adds them also needed a core fix in
# mouse.py (see vendor/NOTICE.md) — so this runs a vendored, pinned copy of
# that branch via PYTHONPATH rather than depending on an external rivalcfg
# install or checkout.
plugin_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)" || exit 1

# The `hid` module (pip package `hidapi`) wraps the system hidapi library as
# a compiled C extension, so unlike rivalcfg itself it can't be vendored as
# plain Python source — it has to actually be installed. Reported as a
# distinct sentinel so the widget can tell "you need to install a
# dependency" apart from "the mouse is off or disconnected", which look
# identical from rivalcfg's own output otherwise.
if ! python3 -c "import hid" >/dev/null 2>&1; then
    echo "E: hidapi module not installed"
    exit 2
fi

# The 2.4GHz dongle occasionally misses a single HID read even while the
# mouse is awake and connected (200ms read timeout in rivalcfg's own code),
# which rivalcfg reports identically to "mouse is actually off": "E: No
# supported device found." One retry after a short pause resolves it
# without masking a real absence, since a genuinely off/unplugged mouse
# fails the same way on the second try too.
output="$(PYTHONPATH="$plugin_dir/vendor" python3 -m rivalcfg --battery-level 2>&1)"
case "$output" in
    "Charging ["* | "Discharging ["*)
        echo "$output"
        exit 0
        ;;
esac

sleep 1
exec env PYTHONPATH="$plugin_dir/vendor" python3 -m rivalcfg --battery-level
