#!/usr/bin/bash

COUNTER=0
while [ ${COUNTER} -lt $1 ]; do
    sh downloadFullInventory.sh
    sleep 200 
    let COUNTER=COUNTER+1 
done
