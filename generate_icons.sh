#!/bin/bash

# Android icon sizes
declare -A android_sizes
android_sizes=(
  ["mdpi"]=48
  ["hdpi"]=72
  ["xhdpi"]=96
  ["xxhdpi"]=144
  ["xxxhdpi"]=192
)

# iOS icon sizes
declare -A ios_sizes
ios_sizes=(
  ["Icon-App-20x20@1x.png"]=20
  ["Icon-App-20x20@2x.png"]=40
  ["Icon-App-20x20@3x.png"]=60
  ["Icon-App-29x29@1x.png"]=29
  ["Icon-App-29x29@2x.png"]=58
  ["Icon-App-29x29@3x.png"]=87
  ["Icon-App-40x40@1x.png"]=40
  ["Icon-App-40x40@2x.png"]=80
  ["Icon-App-40x40@3x.png"]=120
  ["Icon-App-60x60@2x.png"]=120
  ["Icon-App-60x60@3x.png"]=180
  ["Icon-App-76x76@1x.png"]=76
  ["Icon-App-76x76@2x.png"]=152
  ["Icon-App-83.5x83.5@2x.png"]=167
  ["Icon-App-1024x1024@1x.png"]=1024
)

# Generate Android icons
for size in "${!android_sizes[@]}"; do
  dimension=${android_sizes[$size]}
  convert assets/images/icon.png -resize ${dimension}x${dimension} android/app/src/main/res/mipmap-${size}/ic_launcher.png
done

# Generate iOS icons
for file in "${!ios_sizes[@]}"; do
  dimension=${ios_sizes[$file]}
  convert assets/images/icon.png -resize ${dimension}x${dimension} ios/Runner/Assets.xcassets/AppIcon.appiconset/${file}
done

echo "Icons generated successfully"