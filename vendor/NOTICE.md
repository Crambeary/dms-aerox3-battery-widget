# Vendored dependency: rivalcfg

This directory vendors the `rivalcfg` Python package, unmodified, at a
specific commit. It exists here — rather than requiring a separate
install — because Aerox 3 Wireless Gen 2 support (this widget's whole
reason to exist) isn't in any released rivalcfg version yet.

- **Upstream**: https://github.com/flozz/rivalcfg
- **Branch**: `device_aerox3_wireless_gen2`
- **Commit**: `77200c925cbaab04ebc53e0551535b3b8d9aa71b` (2026-09-04)
- **License**: WTFPL (see `rivalcfg/LICENSE`) — permissive, vendoring is fine

## Why vendored instead of "just install rivalcfg"

Two things are missing from every released rivalcfg (including 4.17.0 on
PyPI), both only on the branch above:

1. **Device support**: `rivalcfg/devices/aerox3_wireless_gen2_wired.py` and
   `aerox3_wireless_gen2_wireless.py` — the profiles for USB PIDs `1038:1892`
   (wired) and `1038:1890` (2.4GHz wireless). Without these, rivalcfg reports
   "No supported device found" regardless of whether the mouse is on.

2. **A core fix in `rivalcfg/mouse.py`**: the released `Mouse.battery`
   property treats any battery reading outside 0–100 as a total failure
   (returns `{"is_charging": None, "level": None}`). This device's battery
   read occasionally produces a raw value outside that range on an
   otherwise-successful read; the branch clamps instead of discarding:

   ```python
   # released:
   if result["level"] is None or result["level"] > 100 or result["level"] < 0:
       return {"is_charging": None, "level": None}
   # branch:
   if result["level"] is not None:
       result["level"] = max(min(result["level"], 100), 0)
   ```

   Without this, the widget would spuriously report "unavailable" on a
   fraction of reads even with the device profiles present and the mouse
   fully awake.

Since both fixes are unmerged and live only on this branch, and the branch
carries other unrelated in-flight changes (see the PR discussion upstream),
vendoring a pinned snapshot here is more reliable for plugin users than
asking everyone to find, clone, and check out a moving branch themselves.

## Updating this vendor copy

If the upstream PR merges, or the branch moves and you want to re-sync:

```bash
git clone https://github.com/flozz/rivalcfg /tmp/rivalcfg
cd /tmp/rivalcfg && git checkout device_aerox3_wireless_gen2
cp -r rivalcfg /path/to/this/plugin/vendor/rivalcfg
cp LICENSE /path/to/this/plugin/vendor/rivalcfg/LICENSE
```

Then update the commit hash above and re-test both wired and wireless modes
before committing.

## Still required separately (not vendored — can't be)

- The `hid` Python module (PyPI package `hidapi`) — a compiled C extension
  wrapping the system `hidapi` library, so it can't be vendored as source.
- A udev rule granting unprivileged `hidraw` access to this mouse's PIDs.

See the plugin's top-level README for install steps for both.
