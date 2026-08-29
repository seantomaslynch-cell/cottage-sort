#!/usr/bin/env bash
# Fetch the free / commercial-use asset pack for Cottage Sort.
#
# Everything pulled here is CC0 (public-domain dedication) or SIL OFL — both are
# fine for a paid, ad-supported commercial app with no attribution obligation
# (OFL only asks that the font not be sold on its own). Sources + licences are
# written to licenses/ .
#
# Usage:  bash tools/fetch_assets.sh
# Safe to re-run; it overwrites the placeholder assets in place.
set -euo pipefail
cd "$(dirname "$0")/.."
root=$(pwd)
mkdir -p game/assets/fonts game/assets/music game/assets/kenney_interface_sounds licenses

dl() { curl -fsSL --retry 3 -o "$1" "$2" && echo "  ok  $1"; }

echo "[1/4] Fredoka (SIL OFL) — cozy rounded UI font"
dl game/assets/fonts/Fredoka.ttf \
  "https://raw.githubusercontent.com/google/fonts/main/ofl/fredoka/Fredoka%5Bwdth%2Cwght%5D.ttf"
dl licenses/Fredoka-OFL.txt \
  "https://raw.githubusercontent.com/google/fonts/main/ofl/fredoka/OFL.txt"

echo "[2/4] Kenney Interface Sounds (CC0) — UI SFX"
tmp=$(mktemp -d)
curl -fsSL --retry 3 -o "$tmp/ks.zip" \
  "https://github.com/Calinou/kenney-interface-sounds/archive/refs/heads/master.zip"
unzip -qo "$tmp/ks.zip" -d "$tmp"
cp "$tmp"/kenney-interface-sounds-master/addons/kenney_interface_sounds/*.wav \
   game/assets/kenney_interface_sounds/
cp "$tmp"/kenney-interface-sounds-master/LICENSE.txt licenses/KenneyInterfaceSounds-CC0.txt
rm -rf "$tmp"
# map the five sounds the game plays onto tasteful picks
cp game/assets/kenney_interface_sounds/pluck_001.wav        game/audio/tap.wav
cp game/assets/kenney_interface_sounds/drop_002.wav         game/audio/place.wav
cp game/assets/kenney_interface_sounds/glass_002.wav        game/audio/pour.wav
cp game/assets/kenney_interface_sounds/error_003.wav        game/audio/buzz.wav
cp game/assets/kenney_interface_sounds/confirmation_002.wav game/audio/win.wav
echo "  ok  game/audio/{tap,place,pour,buzz,win}.wav"

echo "[3/4] FreePD tracks (CC0) — cozy music bed"
dl "game/assets/music/magic_in_the_garden.mp3" \
  "https://raw.githubusercontent.com/0lhi/FreePD/stream/Scoring/Magic%20in%20the%20Garden.mp3"
dl "game/assets/music/slice_of_life.mp3" \
  "https://raw.githubusercontent.com/0lhi/FreePD/stream/Scoring/Slice%20of%20Life.mp3"
cat > licenses/FreePD-CC0.txt <<'EOF'
Music: "Magic in the Garden" and "Slice of Life"
Source: FreePD.com (mirror: github.com/0lhi/FreePD)
Licence: CC0 1.0 Universal (public domain). No attribution required.
EOF
echo "  ok  game/assets/music/*.mp3"

echo "[4/4] AdMob + App Tracking Transparency plugins (cengiz-pz, MIT)"
mkdir -p addons ios
tmpp=$(mktemp -d)
curl -fsSL --retry 3 -o "$tmpp/ios.zip" \
  "https://github.com/cengiz-pz/godot-ios-admob-plugin/releases/download/v4.0/AdmobPlugin-v4.0.zip"
curl -fsSL --retry 3 -o "$tmpp/android.zip" \
  "https://github.com/cengiz-pz/godot-android-admob-plugin/releases/download/v4.0/AdmobPlugin-4.0.zip"
unzip -qo "$tmpp/ios.zip"     -d "$tmpp/ios"
unzip -qo "$tmpp/android.zip" -d "$tmpp/android"
# iOS zip: addons/AdmobPlugin + ios/{framework,plugins}
cp -r "$tmpp/ios/addons/AdmobPlugin" addons/
cp -r "$tmpp/ios/ios/." ios/
# Android zip: AdmobPlugin-root/addons/AdmobPlugin (adds bin/*.aar)
cp -r "$tmpp/android/AdmobPlugin-root/addons/AdmobPlugin/bin" addons/AdmobPlugin/
cp "$tmpp/ios/addons/AdmobPlugin/LICENSE" licenses/AdmobPlugin-MIT.txt
rm -rf "$tmpp"
echo "  ok  addons/AdmobPlugin/ + ios/framework + ios/plugins"

echo
echo "Done. Next: godot --headless --path . --editor --quit   (imports the new assets)"
