<#
  Fetch the free / commercial-use asset pack for Cottage Sort  (Windows)

  Uses curl.exe (built into Windows 10 1803+ / 11) so TLS 1.2 to GitHub just
  works — Windows PowerShell 5.1's Invoke-WebRequest defaults to TLS 1.0 and
  GitHub refuses it, which is why the first version downloaded nothing.

  Everything here is CC0 (public-domain dedication) or SIL OFL - both fine for a
  paid, ad-supported commercial app, no attribution required (OFL only forbids
  selling the font on its own). Licence texts land in licenses/ .

  Usage:   powershell -ExecutionPolicy Bypass -File tools\fetch_assets.ps1
  Safe to re-run; overwrites the placeholder assets in place.
#>
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location (Join-Path $PSScriptRoot '..')
$root = (Get-Location).Path

$curl = (Get-Command curl.exe -ErrorAction SilentlyContinue)
if (-not $curl) { throw "curl.exe not found. Needs Windows 10 1803+ or 11. (Or run tools/fetch_assets.sh in Git Bash.)" }

foreach ($d in 'game\assets\fonts','game\assets\music','game\assets\kenney_interface_sounds','licenses','addons') {
  New-Item -ItemType Directory -Force -Path $d | Out-Null
}

function Dl($url, $out) {
  & curl.exe -fSL --retry 3 --create-dirs -o $out $url
  if ($LASTEXITCODE -ne 0) { throw "download failed ($LASTEXITCODE): $url" }
  $kb = [math]::Round((Get-Item $out).Length / 1KB, 1)
  "  ok  $out  (${kb} KB)"
}

Write-Host "[1/4] Fredoka (SIL OFL) - cozy rounded UI font"
Dl "https://raw.githubusercontent.com/google/fonts/main/ofl/fredoka/Fredoka%5Bwdth%2Cwght%5D.ttf" "game\assets\fonts\Fredoka.ttf"
Dl "https://raw.githubusercontent.com/google/fonts/main/ofl/fredoka/OFL.txt" "licenses\Fredoka-OFL.txt"

Write-Host "[2/4] Kenney Interface Sounds (CC0) - UI SFX"
$tmp = Join-Path $env:TEMP ("ks_" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
Dl "https://codeload.github.com/Calinou/kenney-interface-sounds/zip/refs/heads/master" "$tmp\ks.zip"
Expand-Archive "$tmp\ks.zip" -DestinationPath $tmp -Force
$src = "$tmp\kenney-interface-sounds-master\addons\kenney_interface_sounds"
Copy-Item "$src\*.wav" "game\assets\kenney_interface_sounds\" -Force
Copy-Item "$tmp\kenney-interface-sounds-master\LICENSE.txt" "licenses\KenneyInterfaceSounds-CC0.txt" -Force
Remove-Item -Recurse -Force $tmp
$map = [ordered]@{ 'pluck_001'='tap'; 'drop_002'='place'; 'glass_002'='pour'; 'error_003'='buzz'; 'confirmation_002'='win' }
foreach ($k in $map.Keys) {
  Copy-Item "game\assets\kenney_interface_sounds\$k.wav" ("game\audio\" + $map[$k] + ".wav") -Force
}
"  ok  game\audio\{tap,place,pour,buzz,win}.wav  <- Kenney"

Write-Host "[3/4] FreePD tracks (CC0) - cozy music bed"
Dl "https://raw.githubusercontent.com/0lhi/FreePD/stream/Scoring/Magic%20in%20the%20Garden.mp3" "game\assets\music\magic_in_the_garden.mp3"
Dl "https://raw.githubusercontent.com/0lhi/FreePD/stream/Scoring/Slice%20of%20Life.mp3" "game\assets\music\slice_of_life.mp3"
@"
Music: "Magic in the Garden" and "Slice of Life"
Source: FreePD.com  (mirror: github.com/0lhi/FreePD)
Licence: CC0 1.0 Universal (public domain). No attribution required.
"@ | Set-Content "licenses\FreePD-CC0.txt" -Encoding utf8

Write-Host "[4/4] AdMob + App Tracking Transparency plugins (cengiz-pz, MIT)"
$tp = Join-Path $env:TEMP ("admob_" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $tp | Out-Null
Dl "https://github.com/cengiz-pz/godot-ios-admob-plugin/releases/download/v4.0/AdmobPlugin-v4.0.zip" "$tp\ios.zip"
Dl "https://github.com/cengiz-pz/godot-android-admob-plugin/releases/download/v4.0/AdmobPlugin-4.0.zip" "$tp\android.zip"
Expand-Archive "$tp\ios.zip"     -DestinationPath "$tp\ios"     -Force
Expand-Archive "$tp\android.zip" -DestinationPath "$tp\android" -Force
New-Item -ItemType Directory -Force -Path "ios" | Out-Null
Copy-Item "$tp\ios\addons\AdmobPlugin" "addons\" -Recurse -Force          # iOS: addons/AdmobPlugin
Copy-Item "$tp\ios\ios\*"              "ios\"     -Recurse -Force          #      ios/{framework,plugins}
Copy-Item "$tp\android\AdmobPlugin-root\addons\AdmobPlugin\bin" "addons\AdmobPlugin\" -Recurse -Force  # Android: bin/*.aar
Copy-Item "$tp\ios\addons\AdmobPlugin\LICENSE" "licenses\AdmobPlugin-MIT.txt" -Force
Remove-Item -Recurse -Force $tp

Write-Host ""
Write-Host "Done. Files:"
Get-ChildItem game\assets\fonts, game\assets\music, addons -Recurse -File -ErrorAction SilentlyContinue |
  ForEach-Object { "  " + $_.FullName.Substring($root.Length + 1) }
Write-Host ""
Write-Host "Next: godot --headless --path . --editor --quit    (imports the new assets)"
