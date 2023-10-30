#!/bin/bash

# Get the active window's position
eval $(xdotool getwindowgeometry --shell $(xdotool getactivewindow))

# Get details of all screens
screens=($(xrandr | grep connected | grep -oP '\d+x\d+\+\d+\+\d+' | tr 'x+' '  '))

# Find out which screen the window is on
for ((i=0; i<${#screens[@]}; i+=4)); do
    screen_width=${screens[$i]}
    screen_height=${screens[$i+1]}
    screen_x=${screens[$i+2]}
    screen_y=${screens[$i+3]}

    # Check if the window's X and Y coordinates fall within this screen's geometry
    if [ $X -ge $screen_x ] && [ $X -lt $((screen_x+screen_width)) ] && \
       [ $Y -ge $screen_y ] && [ $Y -lt $((screen_y+screen_height)) ]; then
        break
    fi
done

# Add the adjustment for the screen height
adjustment_padding=35
adjusted_height=$((screen_height - adjustment_padding))

half_width=$((screen_width / 2))

# Resize and move the window to the left half of the screen
wmctrl -i -r $WINDOW -e 0,$screen_x,$screen_y,$half_width,$adjusted_height
