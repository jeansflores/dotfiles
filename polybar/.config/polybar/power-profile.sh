#!/usr/bin/env bash

PROFILES=(power-saver balanced performance)

current() {
    busctl get-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
        net.hadess.PowerProfiles ActiveProfile 2>/dev/null | awk '{gsub(/"/, ""); print $2}'
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
        busctl set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles \
            net.hadess.PowerProfiles ActiveProfile s "$(next_profile)"
        ;;
    *)
        label "$(current)"
        ;;
esac
