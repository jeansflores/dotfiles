#!/usr/bin/env bash

BOOST=/sys/devices/system/cpu/cpufreq/boost

case "$1" in
    toggle)
        current=$(cat "$BOOST")
        if [ "$current" = "1" ]; then
            echo 0 | sudo tee "$BOOST" > /dev/null
        else
            echo 1 | sudo tee "$BOOST" > /dev/null
        fi
        ;;
    *)
        [ "$(cat $BOOST)" = "1" ] && echo "TURBO ON" || echo "TURBO OFF"
        ;;
esac
