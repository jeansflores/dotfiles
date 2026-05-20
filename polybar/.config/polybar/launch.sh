#!/usr/bin/env bash

killall -q polybar
while pgrep -u $UID -x polybar > /dev/null; do sleep 0.5; done

# lança uma barra por monitor ativo (com resolução atribuída)
for m in $(xrandr --query | grep -E "^[A-Z].* connected (primary )?[0-9]" | cut -d" " -f1); do
    MONITOR=$m polybar --reload main &
done
