# Web build

Cottage Sort targets the web first (itch.io, YouTube Playables, plain hosting).
The renderer is already **GL Compatibility** and the Web export preset has
**thread support off**, so the build runs on hosts that don't send the
COOP/COEP cross-origin-isolation headers (YouTube Playables, itch.io, GitHub
Pages, plain `python -m http.server`).

## One-time: install export templates

The repo has the preset but not the ~150 MB templates. In the Godot editor:
**Editor → Manage Export Templates → Download and Install** (match the editor
version, 4.7.2).

## Build

```powershell
pwsh tools/export_web.ps1
```

```bash
GODOT=/path/to/godot tools/export_web.sh
```

Output goes to `build/web/` (`index.html`, `.wasm`, `.pck`, ...). `build/` is
git-ignored.

## Preview

```bash
python -m http.server 8060 --directory build/web
```

Open <http://localhost:8060/>.

## Preset notes (`export_presets.cfg`)

- `variant/thread_support=false` — widest host compatibility. Keep off unless a
  host guarantees COOP/COEP headers.
- `html/head_include` sets the page background to the game's cream so there's no
  white flash before the canvas paints.
- `html/canvas_resize_policy=2` (adaptive) + the project's
  `stretch/mode=canvas_items`, `aspect=expand` handle the portrait letterboxing.
- PWA is off; turn it on later if shipping as an installable web app.

## Customizing the loading page later

We use Godot's default HTML shell for now. To brand it, copy the engine's
`misc/dist/html/full-size.html` from the matching Godot source, adjust it, save
it as `web/shell.html`, and set `html/custom_html_shell="web/shell.html"` in the
preset. Test every export after editing the shell — a broken shell breaks the
build.

## YouTube Playables

Keep the total payload lean (strip unused assets, the preset already excludes
`tools/*` and `*.md`). Playables run in an iframe with no cross-origin isolation,
which is why threads stay off. Input is touch/pointer — already handled via
`emulate_touch_from_mouse` and the board's touch/mouse handling.
