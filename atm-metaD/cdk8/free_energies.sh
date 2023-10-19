#!/bin/bash

for pair in 17-17 19-19 37-37 38-38  ; do
    ( cd protein-${pair} && res=`./analyze.sh 37` && echo "$pair $res")
done
