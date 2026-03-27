#!/usr/bin/env bash

# Detect displays
INTERNAL=$(xrandr | grep " connected" | grep -i "eDP\|LVDS" | awk '{print $1}' | head -1)
EXTERNAL=$(xrandr | grep " connected" | grep -vi "eDP\|LVDS" | awk '{print $1}' | head -1)

STATE_FILE="/tmp/monitor-mode"
CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "laptop")

# If no external display detected, stay on laptop
if [ -z "$EXTERNAL" ]; then
    xrandr --output "$INTERNAL" --auto
    notify-send "Display" "Laptop only (no external detected)" -t 2000
    echo "laptop" > "$STATE_FILE"
    exit 0
fi

# Determine next mode
case "$CURRENT" in
    laptop)   NEXT="extend"   ;;
    extend)   NEXT="mirror"   ;;
    mirror)   NEXT="external" ;;
    external) NEXT="laptop"   ;;
    *)        NEXT="laptop"   ;;
esac

# Execute xrandr commands for the next mode
case "$NEXT" in
    laptop)
        xrandr --output "$INTERNAL" --auto --output "$EXTERNAL" --off
        notify-send "Display" "Laptop only" -t 2000
        ;;
    extend)
        xrandr --output "$INTERNAL" --auto --output "$EXTERNAL" --auto --right-of "$INTERNAL"
        notify-send "Display" "Extended (external right)" -t 2000
        ;;
    mirror)
        RES=$(xrandr | grep -A1 "$INTERNAL connected" | tail -1 | awk '{print $1}')
        xrandr --output "$INTERNAL" --auto --output "$EXTERNAL" --same-as "$INTERNAL" --mode "$RES"
        notify-send "Display" "Mirror" -t 2000
        ;;
    external)
        xrandr --output "$EXTERNAL" --auto --output "$INTERNAL" --off
        notify-send "Display" "External only" -t 2000
        ;;
esac

echo "$NEXT" > "$STATE_FILE"
