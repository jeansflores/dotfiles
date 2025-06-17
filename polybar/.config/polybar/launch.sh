#!/bin/bash
# Mata qualquer polybar rodando
killall -q polybar

# Espera fechar
while pgrep -x polybar >/dev/null; do sleep 0.5; done

# Inicia em todos os monitores
for m in $(polybar --list-monitors | cut -d":" -f1); do
  MONITOR=$m polybar example &
done
