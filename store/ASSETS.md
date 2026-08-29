# Asset pack — free for commercial use

Run once (Windows):

```powershell
powershell -ExecutionPolicy Bypass -File tools\fetch_assets.ps1
```

or, in Git Bash / macOS / Linux / Codemagic:

```bash
bash tools/fetch_assets.sh
```

Then import them:

```bash
godot --headless --path . --editor --quit
```

Everything fetched is **CC0** (public-domain dedication) or **SIL OFL** — both
usable in a paid, ad-supported app with **no attribution requirement**. The OFL
only forbids selling the font by itself. Licence texts are copied to `licenses/`.

| What | Where it lands | Source | Licence |
|---|---|---|---|
| Fredoka (variable UI font) | `game/assets/fonts/Fredoka.ttf` | google/fonts | OFL 1.1 |
| Kenney Interface Sounds (100 UI SFX) | `game/assets/kenney_interface_sounds/` | Calinou/kenney-interface-sounds | CC0 |
| 5 game SFX (mapped from the pack) | `game/audio/{tap,place,pour,buzz,win}.wav` | ↑ | CC0 |
| 2 cozy music beds | `game/assets/music/*.mp3` | FreePD.com (0lhi/FreePD mirror) | CC0 |
| AdMob + ATT plugin GDScript | `addons/AdmobPlugin/` (committed) | cengiz-pz/godot-*-admob-plugin v4.0 | MIT |
| AdMob iOS binaries (27 MB Google SDK) | `ios/framework/`, `ios/plugins/*.a` (git-ignored, re-fetched) | ↑ | MIT / Google |

## What's already wired

- **Font** — `game/ui_theme.gd` loads Fredoka at weight 480 for all Buttons and
  Labels; falls back to Godot's default when the file is absent.
- **SFX** — `game/audio.gd` plays `game/audio/*.wav` by name; the fetch script
  overwrites the five generated placeholders in place. Re-run
  `tools/gen_sfx.py` to get the old ones back.
- **Music** — `game/audio.gd::_pick_music()` uses the first of
  `magic_in_the_garden.mp3` → `slice_of_life.mp3` → the generated `music.wav`
  that exists, and loops it.
- **AdMob / ATT** — see `store/INTEGRATION.md`. Bundled but gated behind
  `USE_ADMOB_PLUGIN := false` in `ads.gd` until a CI/device export confirms the
  4.4.1-built addon loads on 4.7.

## SFX mapping

`tap → pluck_001` · `place → drop_002` · `pour → glass_002` ·
`buzz → error_003` · `win → confirmation_002`. To try other picks, copy a
different file from `game/assets/kenney_interface_sounds/` over the target in
`game/audio/` and re-import.

## Deliberately deferred: bitmap art for jars / beads / cottage

The jars, beads and cottage are procedural `_draw()` art (polished in M7 + M24).
Swapping in sprite art (Kenney "Puzzle Pack", "Board Game Icons", etc. — all
CC0) is a self-contained milestone, not a drop-in: `board.gd` and
`cottage_view.gd` would each need a sprite path alongside the draw calls, plus
9-slice panels to replace the runtime `StyleBoxFlat` theme. Left as-is so the
current look doesn't regress. When ready, add the pack under
`game/assets/art/` and branch the draw code on a `Config.USE_SPRITE_ART` flag.
