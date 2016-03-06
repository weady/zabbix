#!/bin/bash
#
#
#

ip -s link | grep 'state' | awk '{print $2,$9}' | grep "$1" | awk -F':' '{print $2}' | sed 's/[[:space:]]//'
