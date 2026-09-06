# Switch low-battery alerts to `dms notify`, dropping urgency tiers

The four cascading low-battery notifications (20/15/10/5%) originally shelled
out to `notify-send` directly, using `-u normal` for the 20/15% tiers and
`-u critical` for 10/5% — a real distinction on most notification daemons,
which display and persist critical alerts more aggressively.

A registry reviewer (AvengeMedia/dms-plugin-registry#847) asked to use
`dms notify` instead, since it's DMS's own notification CLI and drops one
external dependency (`notify-send`/`libnotify`) from the plugin. Checked
`dms notify`'s actual flags (`core/cmd/dms/commands_notify.go`): it takes
`--app`, `--icon`, `--file`, `--timeout` — no urgency or priority flag of any
kind.

Decided to switch anyway and drop urgency tiering entirely, rather than keep
`notify-send` only for the critical tiers. Splitting the mechanism across
tiers would have been more confusing than the fidelity it preserved, and the
underlying signal (mouse battery level) isn't urgent enough to be worth
carrying two notification mechanisms for.

Consequence: all four tiers now render identically at whatever urgency the
user's notification daemon defaults to — a user can no longer distinguish
"getting low" from "about to die" by how the notification itself behaves,
only by its title/text ("Battery Low" vs "Battery Critical") and icon.
