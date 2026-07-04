#!/bin/sh

# To validate the current mapping
# xinput get-button-map 13

# Then we just need to set left click for the middle click
xinput set-button-map 13 1 0 3 4 5 6 7
