# Settings plan: bar-icon display options

Status: **grilled and decided, not yet implemented**. Three user-facing
toggles requested for the bar pill (the popout already shows everything
unconditionally and isn't in scope here):

1. Show percentage next to/in the icon, or hide it
2. Show battery-state colors, or always render neutral
3. Show a charging indicator glyph in the bar, or icon-only

This doc fixes the mechanism (confirmed against DMS's own source) and lays
out the three settings with their defaults and exact code touch points. All
open questions below were resolved in a grilling session — see
[CONTEXT.md](../CONTEXT.md) for the vocabulary this session settled
(Battery state / Fully Charged / Widget status / Charging indicator) and
[ADR-0001](adr/0001-charging-indicator-not-icon-toggle.md) for the one
decision that reverses this doc's own original recommendation.

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
| `showPercentage` | bool | `false` | Show/hide a percentage text next to the bar icon |
| `showColors` | bool | `true` | Use battery-state colors (error/primary/success) vs. always `Theme.widgetIconColor` |
| `showChargingIndicator` | bool | `true` | Show/hide a small bolt glyph next to the icon when charging |

`showPercentage` defaults to `false` since it's genuinely new UI, not a
toggle on existing behavior — ships matching today's icon-only look exactly,
opt-in rather than opt-out. `showColors` and `showChargingIndicator` default
to `true`, matching current always-on behavior.

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

**Default**: `false` — decided (see table above) to ship matching today's
icon-only look and let people opt in, rather than DMS's own native widget's
default of always-on.

**Layout order**: when both `showChargingIndicator` and `showPercentage`
are on, the bar pill renders bolt → battery icon → percentage text (see
`showChargingIndicator` below for the bolt itself).

### 2. `showColors`

**Current state**: `batteryColor()` returns `Theme.error` (low battery),
`Theme.primary` (charging), `Theme.warning` (missing dependency), or
`Theme.widgetIconColor` (normal/unavailable) — see `Aerox3Battery.qml`.
Fully Charged is a new state added alongside this work (see "Fully Charged"
below): `Theme.success` when `level >= 95 && isCharging`.

**Decided**: the missing-dependency warning color is **exempt** from this
toggle — it's Widget status (the plugin needs setup), not Battery state,
per [CONTEXT.md](../CONTEXT.md). Every actual battery state (normal, low,
charging, fully charged) *is* gated by `showColors`, including the new
Fully Charged → `Theme.success` state.

```qml
function batteryColor() {
    if (root.missingDependency)
        return Theme.warning; // Widget status — never gated by showColors
    if (!(pluginData.showColors ?? true))
        return Theme.widgetIconColor;
    if (!root.available)
        return Theme.widgetIconColor;
    if (root.isFullyCharged)
        return Theme.success;
    if (root.isLowBattery)
        return Theme.error;
    if (root.isCharging)
        return Theme.primary;
    return Theme.widgetIconColor;
}
```

### 3. `showChargingIndicator`

**Decided** (see [ADR-0001](adr/0001-charging-indicator-not-icon-toggle.md)
for why this reverses the plan's original recommendation): this setting
controls a small bolt glyph rendered beside the battery icon in the bar
pill — it does **not** touch icon shape. `Theme.getBatteryIcon()` keeps
receiving the real `isCharging` value unconditionally, so the icon itself
always uses DMS's `battery_charging_*` set while charging regardless of
this setting.

```qml
function batteryIcon() {
    if (root.missingDependency)
        return "extension";
    return Theme.getBatteryIcon(root.level, root.isCharging, root.available);
    // unchanged — icon shape is not gated by showChargingIndicator
}
```

The bolt glyph itself: a second small `DankIcon` (e.g. `"bolt"`), visible
when `pluginData.showChargingIndicator ?? true` and `root.isCharging`,
colored with `root.batteryColor()` — same color the main icon uses, so it
turns `Theme.success` alongside the icon when Fully Charged, and respects
the `showColors` gating automatically since it reads the same function.

## Settings UI

Add three `ToggleSetting` blocks to `Aerox3BatterySettings.qml`, replacing
the current "No configurable options" line in the description text at the
top of that file. Follow `DankBatteryAlertsSettings.qml`'s structure
(section headers via bare `StyledText` + a `StyledRect` divider, in the
same style as the existing "Requirements" info card lower in the file).

## Fully Charged (bundled into this pass)

Originally filed as an unrelated follow-up, then decided (grilling session)
to bundle into this same implementation since it shares `batteryColor()`
and `detailsText` touch points with `showColors` above.

**Decided**: `isFullyCharged: level >= 95 && isCharging` (matches the
band DMS's own `Theme.getBatteryIcon()` already treats as "topped off" for
`battery_full`/`battery_charging_full`, tolerating a mouse that reports
96–99% but is effectively full). New readonly property on `root`:

```qml
readonly property bool isFullyCharged: available && isCharging && level >= 95
```

- [ ] Popout `detailsText`: `root.isFullyCharged ? "Fully Charged" : (root.isCharging ? "Charging" : "Discharging")`
- [ ] `batteryColor()`: `Theme.success` when `isFullyCharged`, gated by
      `showColors` like every other battery state (see `showColors` above)
- [ ] Icon shape: unchanged — `Theme.getBatteryIcon()` already renders
      `battery_charging_full` at this range, no new icon needed

## Task checklist

- [x] Resolve the `showChargingIndicator` question — bolt glyph beside the
      icon, icon shape stays unconditional (ADR-0001)
- [x] Resolve the `showColors` / missing-dependency-warning exemption
      question — exempt, it's Widget status not Battery state
- [x] Resolve Fully Charged detection, color, and gating — see above
- [x] Add `"settings_read", "settings_write"` to `plugin.json` permissions
- [x] Add the three `ToggleSetting` blocks to `Aerox3BatterySettings.qml`
- [x] Wire `pluginData.showPercentage` into both bar-pill components (new
      percentage text + `NumericText`/`reserveText` for stable width),
      defaulting to `false`
- [x] Add `isFullyCharged` property and wire it into `batteryColor()` and
      the popout's `detailsText`
- [x] Wire `pluginData.showColors` into `batteryColor()`, exempting the
      missing-dependency branch
- [x] Add the bolt glyph to both bar-pill components, gated by
      `pluginData.showChargingIndicator` and `root.isCharging`, colored via
      `root.batteryColor()`
- [x] Lay out bar-pill elements in order: bolt → icon → percentage
- [ ] Confirm live-update actually works in practice (toggle a setting with
      the widget visible, no reload) — mechanism is confirmed from source,
      but not yet observed running (needs a live DMS session; not possible
      from the sandboxed environment this was implemented in)
- [x] Update README's feature list and the in-app settings description
      text to describe the new toggles and the Fully Charged state
- [ ] Reload (`dms ipc call plugins reload aerox3Battery`) and screenshot
      each toggle's on/off state, plus the Fully Charged state, for a
      sanity check before committing (same live-session caveat as above)
