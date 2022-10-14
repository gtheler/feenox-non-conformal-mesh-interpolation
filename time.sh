#!/bin/bash -e

for i in gmsh feenox /usr/bin/time; do
 if [ -z "$(which ${i})" ]; then
  echo "error: ${i} not installed"
  exit 1
 fi
done

min=10
max=50
step=10

echo "src     dst     readsrc readdst wrtone  wrtf    diff    average"
echo "10      10      0.016   0.014   0.021   0.019   -0.001  0.009"

for src in $(seq ${min} ${step} ${max}); do
 for dst in $(seq ${min} ${step} ${max}); do
  feenox interpolate_timed.fee ${src} ${dst}
 done
 echo
done
