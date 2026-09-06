# Aerox 3 Battery Widget

A DankMaterialShell plugin that polls a SteelSeries Aerox 3 Wireless Gen 2
mouse's battery over HID and renders it as a themed bar pill and popout.

## Language

**Battery state**:
The mouse's actual charge condition — Normal, Low, Charging, or Fully
Charged. Battery state drives `batteryColor()` and is what the `showColors`
setting gates: turning it off renders every battery state in
`Theme.widgetIconColor` instead of its state color.
_Avoid_: "status" (too easily confused with Widget status, below)

**Fully Charged**:
The battery state when `level >= 95 && isCharging` — the mouse is plugged
in and effectively topped off. Distinct from Charging (isCharging but
`level < 95`). Renders `Theme.success` (gated by `showColors`, same as any
other battery state) and "Fully Charged" in the popout's `detailsText`
instead of "Charging".
_Avoid_: "Full" alone (ambiguous with `battery_full`, the non-charging icon
name for a charged-and-unplugged mouse)

**Widget status**:
The plugin's own operating health, independent of battery state — currently
just "missing dependency" (hidapi not installed). Widget status renders
`Theme.warning` unconditionally: it is *not* gated by `showColors`, because
a setup problem isn't a battery reading and should stay visible even when
the user has turned battery-state colors off.
_Avoid_: lumping this in with "battery state" or "semantic colors"

**Charging indicator**:
The small bolt glyph shown in the bar pill alongside the battery icon when
`isCharging` is true, gated by the `showChargingIndicator` setting. This is
separate from the battery icon's own shape, which always uses DMS's
`battery_charging_*` icon set when charging regardless of this setting —
see [[0001-charging-indicator-not-icon-toggle]]. The bolt takes
`batteryColor()`'s color, so it turns `Theme.success` alongside the icon
when Fully Charged.
_Avoid_: "charging state" (too broad — sounds like it could also mean the
icon shape, which this setting does not control)
