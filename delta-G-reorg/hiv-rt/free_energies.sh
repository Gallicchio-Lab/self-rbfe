#!/bin/bash

for pair in tmc-125-tmc-125 tmc-278-tmc-278  ; do
    ( cd protein-${pair} && res=`./analyze.sh 37` && echo "$pair $res")
done
