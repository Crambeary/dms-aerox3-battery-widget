#!/bin/sh
# Prints rivalcfg's `--battery-level` output for the Aerox 3 Wireless Gen 2.
#
# The mouse's USB PID (1038:1890) isn't recognized by the released rivalcfg
# package (4.17.0 on PyPI predates Gen 2 support), so this can't just call
# the installed `rivalcfg` binary. Support lives on flozz/rivalcfg's
# device_aerox3_wireless_gen2 branch, unmerged, so this runs it in place as
# `python3 -m rivalcfg` from inside that checkout instead.
#
# Path is hardcoded rather than discovered via ghq, since ghq isn't
# guaranteed to be installed wherever this plugin runs.
cd "$HOME/ghq/github.com/flozz/rivalcfg" || exit 1

# The 2.4GHz dongle occasionally misses a single HID read even while the
# mouse is awake and connected (200ms read timeout in rivalcfg's own code),
# which rivalcfg reports identically to "mouse is actually off": "E: No
# supported device found." One retry after a short pause resolves it
# without masking a real absence, since a genuinely off/unplugged mouse
# fails the same way on the second try too.
output="$(python3 -m rivalcfg --battery-level 2>&1)"
case "$output" in
    "Charging ["* | "Discharging ["*)
        echo "$output"
        exit 0
        ;;
esac

sleep 1
exec python3 -m rivalcfg --battery-level
