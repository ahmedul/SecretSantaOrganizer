#!/bin/bash
# Generate logo PNGs from SVG

# Check if inkscape or imagemagick is available
if command -v inkscape &> /dev/null; then
    echo "Using Inkscape to convert SVG to PNG..."
    inkscape assets/logo.svg -o assets/logo-512.png -w 512 -h 512
    inkscape assets/logo.svg -o assets/logo-192.png -w 192 -h 192
    inkscape assets/logo.svg -o assets/logo-128.png -w 128 -h 128
    inkscape assets/logo.svg -o assets/logo-64.png -w 64 -h 64
elif command -v convert &> /dev/null; then
    echo "Using ImageMagick to convert SVG to PNG..."
    convert -background none -resize 512x512 assets/logo.svg assets/logo-512.png
    convert -background none -resize 192x192 assets/logo.svg assets/logo-192.png
    convert -background none -resize 128x128 assets/logo.svg assets/logo-128.png
    convert -background none -resize 64x64 assets/logo.svg assets/logo-64.png
else
    echo "Error: Neither Inkscape nor ImageMagick found."
    echo "Install one with:"
    echo "  sudo apt install inkscape"
    echo "  or"
    echo "  sudo apt install imagemagick"
    exit 1
fi

echo "Logo PNGs generated successfully!"
echo "Files created:"
echo "  - assets/logo-512.png"
echo "  - assets/logo-192.png"
echo "  - assets/logo-128.png"
echo "  - assets/logo-64.png"
