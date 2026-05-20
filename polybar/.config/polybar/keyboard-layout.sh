#!/usr/bin/env bash

CURRENT=$(setxkbmap -query | grep layout | awk '{print $2}')
VARIANT=$(setxkbmap -query | grep variant | awk '{print $2}')

case "$1" in
    toggle)
        if [ "$CURRENT" = "us" ]; then
            setxkbmap -layout br -variant abnt2
        else
            setxkbmap -layout us -variant intl
        fi
        ;;
    *)
        if [ "$CURRENT" = "us" ]; then
            echo "US"
        else
            echo "BR"
        fi
        ;;
esac
