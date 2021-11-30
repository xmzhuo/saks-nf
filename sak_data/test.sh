#!/usr/bin/env bash 
cat $1 \
| gatk BedToIntervalList -I /dev/stdin -O $1.interval_list -SD $2 

