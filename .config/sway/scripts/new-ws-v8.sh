
#!/usr/bin/env bash

ACTION="$1" # "create" or "move"
DIR="$2"    # "next" or "prev"

WS_JSON=$(swaymsg -t get_workspaces)
FOCUS_OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
CUR_WS=$(echo "$WS_JSON" | jq -r '.[] | select(.focused) | .num')

if [ "$DIR" == "next" ]; then
    MAX_GLOBAL=$(echo "$WS_JSON" | jq '. | map(.num) | max')
    [[ "$MAX_GLOBAL" == "null" || -z "$MAX_GLOBAL" ]] && MAX_GLOBAL=0
    TARGET=$((MAX_GLOBAL + 1))
else
    TARGET=$(echo "$WS_JSON" | jq -r "[.[] | select(.output == \"$FOCUS_OUTPUT\" and .num < $CUR_WS) | .num] | sort | last")
    if [[ -z "$TARGET" || "$TARGET" == "null" ]]; then
        if [ "$CUR_WS" -gt 1 ]; then
            TARGET=$((CUR_WS - 1))
        else
            exit 0
        fi
    fi
fi

# THE FIX: If Target is 1, don't "move workspace to output".
# Let the config assignment handle it.
if [ "$TARGET" -eq 1 ]; then
    if [ "$ACTION" == "move" ]; then
        swaymsg "move container to workspace number 1; workspace number 1"
    else
        swaymsg "workspace number 1"
    fi
else
    # For all other workspaces, keep the dynamic monitor behavior
    if [ "$ACTION" == "move" ]; then
        swaymsg "mark --add _move; workspace number $TARGET; move workspace to output $FOCUS_OUTPUT; [con_mark=\"_move\"] move container to workspace current; unmark _move"
    else
        swaymsg "workspace number $TARGET; move workspace to output $FOCUS_OUTPUT"
    fi
fi
