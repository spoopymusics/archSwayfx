
#!/usr/bin/env bash

ACTION="$1" # "create" or "move"
DIR="$2"    # "next" or "prev"

# 1. Get current state
WS_JSON=$(swaymsg -t get_workspaces)
FOCUS_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
CUR_WS=$(echo "$WS_JSON" | jq -r '.[] | select(.focused) | .num')

if [ "$DIR" == "next" ]; then
    # Find global max and add 1
    MAX_GLOBAL=$(echo "$WS_JSON" | jq '. | map(.num) | max')
    [[ "$MAX_GLOBAL" == "null" || -z "$MAX_GLOBAL" ]] && MAX_GLOBAL=0
    TARGET=$((MAX_GLOBAL + 1))

    if [ "$ACTION" == "move" ]; then
        swaymsg "mark --add _move; workspace number $TARGET; move workspace to output $FOCUS_OUTPUT; [con_mark=\"_move\"] move container to workspace current; unmark _move"
    else
        swaymsg "workspace number $TARGET; move workspace to output $FOCUS_OUTPUT"
    fi
    exit 0
else
    # PREV Logic (Persistence Fix):
    # Try to find the closest existing workspace on this monitor
    TARGET=$(echo "$WS_JSON" | jq -r "[.[] | select(.output == \"$FOCUS_OUTPUT\" and .num < $CUR_WS) | .num] | sort | last")

    # If no existing workspace is found to the left, try to just go to (Current - 1)
    # This re-creates the "deleted" workspace (like Workspace 1)
    if [[ -z "$TARGET" || "$TARGET" == "null" ]]; then
        if [ "$CUR_WS" -gt 1 ]; then
            TARGET=$((CUR_WS - 1))
        else
            exit 0 # Already at 1, nowhere to go
        fi
    fi
fi

# 2. Perform Action for Left
if [ "$ACTION" == "move" ]; then
    swaymsg "mark --add _move; workspace number $TARGET; move workspace to output $FOCUS_OUTPUT; [con_mark=\"_move\"] move container to workspace current; unmark _move"
else
    swaymsg "workspace number $TARGET; move workspace to output $FOCUS_OUTPUT"
fi
