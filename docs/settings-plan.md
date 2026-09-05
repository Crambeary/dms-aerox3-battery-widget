# Settings plan: bar-icon display options

Status: **planned, not started**. Three user-facing toggles requested for
the bar pill (the popout already shows everything unconditionally and isn't
in scope here):

1. Show percentage next to/in the icon, or hide it
2. Show semantic colors, or always render neutral
3. Show charging/discharging status in the bar, or icon-only

This doc fixes the mechanism (confirmed against DMS's own source) and lays
out the three settings with their defaults, exact code touch points, and the
open questions worth resolving before writing code.

## Mechanism (confirmed, not guesswork)

DMS plugin settings are simple key/value pairs, declared with the
`PluginSettings` declarative widgets (`ToggleSetting`, `SliderSetting`,
`StringSetting`, ...) and read back in the main widget via `pluginData`:

- `plugin.json` needs `"permissions": ["settings_read", "settings_write"]`
  added — currently `[]`. Without it, `ToggleSetting` warns and refuses to
  persist (confirmed in `PluginSettings.qml`'s own guard).
- Each `ToggleSetting { settingKey: "..."; defaultValue: ... }` in the
  settings QML auto-loads/saves that key — no manual wiring needed. Source:
  `quickshell/Modules/Plugins/ToggleSetting.qml` in the DMS repo.
- The main widget reads current values as `pluginData.someKey ?? default`
  (see DMS's own first-party `DankBatteryAlerts.qml` for the exact idiom
  we're already following for the notification thresholds).
- **Live updates are automatic**: `PluginComponent` (the base class
  `Aerox3Battery.qml` extends) has a `Connections` block on
  `pluginService.onPluginDataChanged` that reloads `pluginData` whenever a
  setting changes for this plugin — confirmed in
  `quickshell/Modules/Plugins/PluginComponent.qml` lines ~86-92. So toggling
  a setting in *DMS Settings → Plugins → Aerox 3 Battery* should update the
  bar icon immediately, no reload needed. **Verify this in practice** once
  implemented — confirmed from reading the source, not yet observed live.

## The three settings

| Key | Type | Default | Effect |
|---|---|---|---|
| `showPercentage` | bool | `true` | Show/hide a percentage text next to the bar icon |
| `showColors` | bool | `true` | Use semantic colors (error/primary/warning) vs. always `Theme.widgetIconColor` |
| `showChargingState` | bool | `true` | See open question below — affects icon shape and/or an indicator |

Defaults all default to the current always-on behavior, with one exception
called out below (`showPercentage`, which is a genuinely new addition, not
a toggle on existing behavior).

### 1. `showPercentage`

**Current state**: the bar pill (`horizontalBarPill`/`verticalBarPill` in
`Aerox3Battery.qml`) renders only the `DankIcon` — no percentage text at
all today. This setting *adds* a percentage display, it doesn't just hide
an existing one.

**Implementation**: add a `NumericText` or `StyledText` next to the icon in
both bar-pill components, following the pattern in DMS's own
`Modules/DankBar/Widgets/Battery.qml` (`horizontalSideText`,
`NumericText` with `reserveText` for stable width so the pill doesn't
jitter as digits change width). Wrap in `visible:
pluginData.showPercentage ?? true`.

**Default**: propose `true` (informative by default, matches DMS's own
native battery widget default) — open to `false` if we'd rather ship
matching today's icon-only look and let people opt in.

### 2. `showColors`

**Current state**: `batteryColor()` returns `Theme.error` (low battery),
`Theme.primary` (charging), `Theme.warning` (missing dependency), or
`Theme.widgetIconColor` (normal/unavailable) — see `Aerox3Battery.qml`.

**Implementation**: straightforward — `batteryColor()` becomes:

```qml
function batteryColor() {
    if (!(pluginData.showColors ?? true))
        return Theme.widgetIconColor;
    // ...existing logic unchanged
}
```

**Open question**: should the missing-dependency warning color
(`Theme.warning`) be exempt from this toggle? Arguably a setup problem
should stay visually distinct even if the user has turned off battery-state
colors, since it's not "battery status" so much as "this widget needs
attention." Leaning toward **exempting it** (missing-dependency always
shows warning color regardless of `showColors`), but worth confirming
before implementing rather than assuming.

### 3. `showChargingState`

**Open question — needs a decision before implementing**: "show
charging/discharging status" could mean either of two different things,
and they're not mutually exclusive:

- **(a) Icon shape**: `Theme.getBatteryIcon()` already returns a distinct
  bolt-style icon set when charging (`battery_charging_full`,
  `battery_charging_90`, etc. vs. plain `battery_N_bar`). This setting
  could control whether we ever pass `isCharging: true` into that call —
  i.e., when off, the bar icon always looks like a plain (dis)charging
  battery regardless of actual charging state, and charging is only
  visible in the popout.
- **(b) Explicit indicator**: an additional small glyph/text in the bar
  pill itself (e.g. a bolt icon, or literal "Charging" text) alongside the
  battery icon, independent of which icon shape is used.

These read very differently to a user turning the setting off: (a) means
"stop showing me the charging bolt shape," (b) means "add an explicit
charging label I can see without opening the popout." Recommend clarifying
intent with whoever's picking this up (or just deciding — (a) is simpler,
reuses the existing icon-shape mechanism, and needs zero new UI real
estate) before writing code.

**Tentative recommendation**: go with (a) — it's a smaller change (guards
the existing `isCharging` argument to `Theme.getBatteryIcon()`), doesn't
need new layout space in an already-small bar pill, and the popout remains
the source of truth for exact charging state either way.

```qml
function batteryIcon() {
    if (root.missingDependency)
        return "extension";
    const charging = (pluginData.showChargingState ?? true) && root.isCharging;
    return Theme.getBatteryIcon(root.level, charging, root.available);
}
```

## Settings UI

Add three `ToggleSetting` blocks to `Aerox3BatterySettings.qml`, replacing
the current "No configurable options" line in the description text at the
top of that file. Follow `DankBatteryAlertsSettings.qml`'s structure
(section headers via bare `StyledText` + a `StyledRect` divider, in the
same style as the existing "Requirements" info card lower in the file).

## Task checklist

- [ ] Resolve the `showChargingState` open question (icon-shape vs.
      explicit indicator, or both)
- [ ] Resolve the `showColors` / missing-dependency-warning exemption
      question
- [ ] Add `"settings_read", "settings_write"` to `plugin.json` permissions
- [ ] Add the three `ToggleSetting` blocks to `Aerox3BatterySettings.qml`
- [ ] Wire `pluginData.showPercentage` into both bar-pill components (new
      percentage text + `NumericText`/`reserveText` for stable width)
- [ ] Wire `pluginData.showColors` into `batteryColor()`
- [ ] Wire `pluginData.showChargingState` into `batteryIcon()`
- [ ] Confirm live-update actually works in practice (toggle a setting with
      the widget visible, no reload) — mechanism is confirmed from source,
      but not yet observed running
- [ ] Update README's feature list and the in-app settings description
      text to describe the new toggles
- [ ] Reload (`dms ipc call plugins reload aerox3Battery`) and screenshot
      each toggle's on/off state for a sanity check before committing
