#!/bin/sh

test -f /etc/X11/custom_keymap.xkb && xkbcomp /etc/X11/custom_keymap.xkb "$DISPLAY"
