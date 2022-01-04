#!/bin/bash

if /usr/bin/64tass -C -B --export-labels -l /tmp/64tass_labels.inc_ $* ; then
    echo "OK"
    echo "#importonce
.namespace ccgms { " >  64tass_labels.inc
    cat /tmp/64tass_labels.inc_ | sed 's/\(\.*\)/.label\ \1/' >> 64tass_labels.inc
    echo "}" >>  64tass_labels.inc
    rm /tmp/64tass_labels.inc_
    exit 0
else
    echo "NOK"
    exit 1
fi

