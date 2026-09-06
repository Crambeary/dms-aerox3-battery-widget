# Charging indicator is a separate bolt glyph, not an icon-shape toggle

`docs/settings-plan.md` originally proposed two readings for "show
charging/discharging status": (a) gate whether the bar icon ever uses DMS's
`battery_charging_*` icon shapes, or (b) add a separate explicit indicator
next to the icon, independent of icon shape. The plan's own tentative
recommendation was (a), since it reuses an existing mechanism and needs no
new bar-pill layout space.

Grilled with the user and decided the opposite: `showChargingIndicator`
controls a small bolt glyph rendered beside the battery icon. The icon's
own shape stays unconditional — it always reflects real charging state via
`Theme.getBatteryIcon()`, with no setting able to suppress it. Rationale:
conflating "hide the charging cue" with "change which icon shape renders"
would have made the icon lie about the mouse's actual state whenever the
setting was off, which is worse than adding one small glyph.

Consequence: the setting only ever adds/removes the bolt. A user who wants
zero charging cues in the bar can't get that from this setting alone — the
icon shape will still show the bolt-style glyph while charging.
