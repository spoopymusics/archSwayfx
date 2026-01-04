
#!/usr/bin/env bash

# Action: "create" to just jump, "move" to take window with you
ACTION="$1"

# 1. Get the name of the currently focused monitor
FOCUS_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')

# 2. Find the highest workspace number currently in use
MAX_WS=$(swaymsg -t get_workspaces | jq '. | map(.num) | max')

# If no workspaces exist (unlikely), start at 1
if [ "$MAX_WS" == "null" ]; then
    NEW_WS=1
else
    NEW_WS=$((MAX_WS + 1))
fi

# 3. Perform the action
if [ "$ACTION" == "move" ]; then
    # Move the current container to the new workspace
    swaymsg "move container to workspace number $NEW_WS"
    # Focus the new workspace
    swaymsg "workspace number $NEW_WS"
else
    # Just create/jump to the new workspace
    swaymsg "workspace number $NEW_WS"
fi

# 4. Ensure the new workspace is pinned to the monitor that was focused
swaymsg "workspace $NEW_WS output $FOCUS_OUTPUT"
