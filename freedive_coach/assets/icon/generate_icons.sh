#!/bin/bash

# FreeDive Coach App Icon Generator
# Requires: ImageMagick (brew install imagemagick) or rsvg-convert (brew install librsvg)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🎨 Generating FreeDive Coach app icons..."

# Check for conversion tools
if command -v magick &> /dev/null; then
    CONVERT="magick"
elif command -v convert &> /dev/null; then
    CONVERT="convert"
elif command -v rsvg-convert &> /dev/null; then
    CONVERT="rsvg"
else
    echo "❌ Error: ImageMagick or librsvg is required"
    echo "Install with: brew install imagemagick"
    echo "         or: brew install librsvg"
    exit 1
fi

# Generate main app icon (1024x1024)
echo "📱 Creating main app icon..."
if [ "$CONVERT" = "rsvg" ]; then
    rsvg-convert -w 1024 -h 1024 app_icon.svg -o app_icon.png
    rsvg-convert -w 1024 -h 1024 app_icon_foreground.svg -o app_icon_foreground.png
else
    $CONVERT -background none -resize 1024x1024 app_icon.svg app_icon.png
    $CONVERT -background none -resize 1024x1024 app_icon_foreground.svg app_icon_foreground.png
fi

echo "✅ Icons generated successfully!"
echo ""
echo "Now run: flutter pub run flutter_launcher_icons"
echo ""
