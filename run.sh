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

for i in $(seq ${min} ${step} ${max}); do
 echo -n "creating source mesh ${i}................... "
 /usr/bin/time -f "%e seconds" gmsh -v 0 -3 -clmax $(feenox inverse.fee ${i}) cube.geo -o cube-${i}.msh
 echo -n "populating source mesh ${i} with f(x,y,z)... "
 /usr/bin/time -f "%e seconds" feenox create.fee ${i}
 echo
done


for src in $(seq ${min} ${step} ${max}); do
 for dst in $(seq ${min} ${step} ${max}); do
  echo -n "interpolating from ${src} to ${dst}... "
  /usr/bin/time -f "%e seconds" feenox interpolate.fee ${src} ${dst}
 done
 echo
done


echo "errors"
echo "--------------------------------------------------"
echo "src     dst     L2      max     nodes   elements"

for src in $(seq ${min} ${step} ${max}); do
 for dst in $(seq ${min} ${step} ${max}); do
  feenox error.fee ${src} ${dst}
 done
 echo
done
