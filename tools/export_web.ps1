# Export Cottage Sort for the web.
#
# Requires the Godot 4.7 Web export templates:
#   Godot editor > Editor > Manage Export Templates > Download and Install
# (or place them so `godot --headless --export-release "Web"` can find them.)
#
# Usage:  pwsh tools/export_web.ps1  [-Godot "C:\path\to\Godot.exe"]

param(
	[string]$Godot = "$env:USERPROFILE\OneDrive\Desktop\Godot_v4.7.2-stable_win64.exe"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out  = Join-Path $root "build\web"
New-Item -ItemType Directory -Force -Path $out | Out-Null

Write-Host "Exporting Web build -> $out"
& $Godot --headless --path $root --export-release "Web" (Join-Path $out "index.html")
if ($LASTEXITCODE -ne 0) {
	Write-Host ""
	Write-Host "Export failed (exit $LASTEXITCODE)." -ForegroundColor Yellow
	Write-Host "If the message mentions a missing export template, open the editor and" -ForegroundColor Yellow
	Write-Host "run Editor > Manage Export Templates > Download and Install, then retry." -ForegroundColor Yellow
	exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Done. Preview locally with a plain static server:" -ForegroundColor Green
Write-Host "  python -m http.server 8060 --directory `"$out`""
Write-Host "then open http://localhost:8060/"
