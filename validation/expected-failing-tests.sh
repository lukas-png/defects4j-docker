#!/bin/bash
# Run this script with defects4j >= 2.0.0 to create a CSV of expected failing
# tests for all bugs.

d4j=/opt/defects4j/framework

for pid in $("$d4j/bin/defects4j" pids)
do
    for bid in $("$d4j/bin/defects4j" bids -A -p "$pid")
    do
        echo -n "$pid;$bid;"
        sed -n 's/^--- //p' "$d4j/projects/$pid/trigger_tests/$bid" | paste -sd ';' -
    done
done > triggering-tests.csv
