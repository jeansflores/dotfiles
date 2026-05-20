#!/usr/bin/env bash

PROFILES=(power-saver balanced performance)

current() {
    powerprofilesctl get
}

label() {
    case "$1" in
        power-saver)  echo "PWR-SAVE" ;;
        balanced)     echo "BALANCED" ;;
        performance)  echo "PERF" ;;
    esac
}

next_profile() {
    local cur idx
    cur=$(current)
    for i in "${!PROFILES[@]}"; do
        [[ "${PROFILES[$i]}" == "$cur" ]] && idx=$i && break
    done
    echo "${PROFILES[$(( (idx + 1) % ${#PROFILES[@]} ))]}"
}

case "$1" in
    toggle)
        powerprofilesctl set "$(next_profile)"
        ;;
    *)
        label "$(current)"
        ;;
esac
