#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_icon="$project_dir/Branding/UmbraPatcher.png"
assets="$project_dir/UmbraPatcher/Assets.xcassets"

# Resample the approved artwork for Xcode and the in-app brand mark.
sips -z 1024 1024 "$source_icon" --out "$assets/AppIcon.appiconset/UmbraPatcher.png" >/dev/null
sips -z 256 256 "$source_icon" --out "$assets/BrandIcon.imageset/BrandIcon.png" >/dev/null
