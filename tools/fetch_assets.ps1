<#
  Fetch the free / commercial-use asset pack for Cottage Sort  (Windows / PowerShell)

  Everything here is CC0 (public-domain dedication) or SIL OFL - both fine for a
  paid, ad-supported commercial app, no attribution required (OFL only forbids
  selling the font on its own). Sources + licences land in licenses/ .

  Usage:   powershell -ExecutionPolicy Bypass -File tools\fetch_assets.ps1
  Safe to re-run; overwrites the placeholder assets in place.
#>
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$root = (Get-Location).Path
foreach ($d in 'game\assets\fonts','game\assets\music','game\assets\kenney_interface_sounds','licenses','addons') {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
}
function Dl($url, $out) { Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing; "  ok  $out" }

Write-Host "[1/4] Fredoka (SIL OFL) - cozy rounded UI font"
Dl "https://raw.githubusercontent.com/google/fonts/main/ofl/fredoka/Fredoka%5Bwdth%2Cwght%5D.ttf" "game\assets\fonts\Fredoka.ttf"
Dl "https://raw.githubusercontent.com/google/fonts/main/ofl/fredoka/OFL.txt" "licenses\Fredoka-OFL.txt"

Write-Host "[2/4] Kenney Interface Sounds (CC0) - UI SFX"
$tmp = Join-Path $env:TEMP ("ks_" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
Dl "https://github.com/Calinou/kenney-interface-sounds/archive/refs/heads/master.zip" "$tmp\ks.zip"
Expand-Archive "$tmp\ks.zip" -DestinationPath $tmp -Force
$src = "$tmp\kenney-interface-sounds-master\addons\kenney_interface_sounds"
Copy-Item "$src\*.wav" "game\assets\kenney_interface_sounds\" -Force
Copy-Item "$tmp\kenney-interface-sounds-master\LICENSE.txt" "licenses\KenneyInterfaceSounds-CC0.txt" -Force
Remove-Item -Recurse -Force $tmp
$map = @{ 'pluck_001'='tap'; 'drop_002'='place'; 'glass_002'='pour'; 'error_003'='buzz'; 'confirmation_002'='win' }
foreach ($k in $map.Keys) { Copy-Item "game\assets\kenney_interface_sounds\$k.wav" ("game\audio\" + $map[$k] + ".wav") -Force }
"  ok  game\audio\{tap,place,pour,buzz,win}.wav"

Write-Host "[3/4] FreePD tracks (CC0) - cozy music bed"
Dl "https://raw.githubusercontent.com/0lhi/FreePD/stream/Scoring/Magic%20in%20the%20Garden.mp3" "game\assets\music\magic_in_the_garden.mp3"
Dl "https://raw.githubusercontent.com/0lhi/FreePD/stream/Scoring/Slice%20of%20Life.mp3" "game\assets\music\slice_of_life.mp3"
@"
Music: "Magic in the Garden" and "Slice of Life"
Source: FreePD.com  (mirror: github.com/0lhi/FreePD)
Licence: CC0 1.0 Universal (public domain). No attribution required.
"@ | Set-Content "licenses\FreePD-CC0.txt" -Encoding utf8

Write-Host "[4/4] AdMob + App Tracking Transparency plugins (cengiz-pz, MIT)"
Dl "https://github.com/cengiz-pz/godot-ios-admob-plugin/releases/download/v4.0/AdmobPlugin-v4.0.zip" "$root\_ios_admob.zip"
Dl "https://github.com/cengiz-pz/godot-android-admob-plugin/releases/download/v4.0/AdmobPlugin-4.0.zip" "$root\_android_admob.zip"
Expand-Archive "$root\_ios_admob.zip"     -DestinationPath "$root\_ios_admob"     -Force
Expand-Archive "$root\_android_admob.zip" -DestinationPath "$root\_android_admob" -Force
Copy-Item "$root\_ios_admob\addons\*"     "addons\" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$root\_android_admob\addons\*" "addons\" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "$root\_ios_admob","$root\_android_admob","$root\_ios_admob.zip","$root\_android_admob.zip"
@"
Godot iOS/Android AdMob plugins - github.com/cengiz-pz  (MIT licence)
Release v4.0 (built/tested against Godot 4.4.1, addon interface v2).
Bundled for a CI export test; verify it loads on 4.7.x before shipping.
"@ | Set-Content "licenses\AdmobPlugin-MIT.txt" -Encoding utf8

Write-Host ""
Write-Host "Done. Next: godot --headless --path . --editor --quit   (imports the new assets)"
