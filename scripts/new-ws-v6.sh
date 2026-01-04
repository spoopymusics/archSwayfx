
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

    # FOR NEW WORKSPACES:
    # We must: Create it -> Pin it to monitor -> (Optional) Move window
    if [ "$ACTION" == "move" ]; then
        swaymsg "workspace number $TARGET; move workspace to output $FOCUS_OUTPUT; move container to workspace number $TARGET; workspace number $TARGET"
    else
        swaymsg "workspace number $TARGET; move workspace to output $FOCUS_OUTPUT"
    fi
    exit 0
else
    # PREV: Find the closest existing workspace to the left on this monitor
    TARGET=$(echo "$WS_JSON" | jq -r "[.[] | select(.output == \"$FOCUS_OUTPUT\" and .num < $CUR_WS) | .num] | sort | last")

    if [[ -z "$TARGET" || "$TARGET" == "null" ]]; then
        exit 0
    fi
fi

# 2. Perform Action for Existing Workspaces (Left)
if [ "$ACTION" == "move" ]; then
    swaymsg "move container to workspace number $TARGET; workspace number $TARGET"
else
    swaymsg "workspace number $TARGET"
fi
