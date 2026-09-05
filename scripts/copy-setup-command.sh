#!/bin/sh
# Copies the command to run setup.sh onto the clipboard, for the popout's
# "Copy Setup Command" button. Tries whichever clipboard tool is available —
# wl-copy (Wayland), then xclip/xsel (X11) — since this plugin is meant to
# work across desktops, not just a Wayland one.
plugin_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)" || exit 1
text="sh \"$plugin_dir/setup.sh\""

if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$text" | wl-copy
elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$text" | xclip -selection clipboard
elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$text" | xsel --clipboard --input
else
    exit 1
fi
