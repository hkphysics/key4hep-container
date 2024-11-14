#!/bin/bash

while true
do
    yarn gc
    yarn run-incremental
    sleep 5
done
