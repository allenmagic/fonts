#!/bin/bash

# setting src and dest folder
FONT_SRC_DIR="$(pwd)"
FONT_DEST_DIR="$HOME/.local/share/fonts"

# check the dest folder and mkdir if not exist
if [ ! -d "$FONT_DEST_DIR" ]; then
	mkdir -p "$FONT_DEST_DIR"
fi

# copy the fonts and fonts dirs to dest folder
for item in "$FONT_SRC_DIR"/*; do
	if [ -e "$item" ]; then
		# copy the fonts
		cp -r "$item" "$FONT_DEST_DIR"
		echo "Copied $item to $FONT_DEST_DIR"
	fi
done

# fc-cache
fc-cache -f -v

# message
echo "All fonts are installed to ~/.local/share/fonts folder."
