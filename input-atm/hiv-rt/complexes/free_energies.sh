#!/bin/bash

for pair in tmc-278-tmc-125 tmc-278-tmc-278 tmc-125-tmc-125  ; do
    ( cd protein-${pair} && res=`./analyze.sh 20` && echo "$pair $res")
done
