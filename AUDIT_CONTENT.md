# Cottage Sort — Content & "Full Game" Audit

Prepared against the M32 build (commit `1107095`). This is a *content, feel and
onboarding* pass — a companion to [`AUDIT.md`](AUDIT.md) (competitive/monetization
gaps, mostly closed) and [`AUDIT_FUNCTIONAL.md`](AUDIT_FUNCTIONAL.md) (code health
+ bug log).

## Verdict

Mechanically this is a **complete hybrid-casual puzzle game**. Every system the
competitive audit called for is built and tested: gentle fail state, gems,
6-booster inventory, piggy bank, starter pack, struggle offer, 28-day battle
pass, daily jackpot, weekly event, ghost leaderboard, 6 themed realms, 2-room
cottage + endless decor, combos, haptics, settings, analytics, verified level
generator. 8 headless test suites pass; the authored curve L1–L40 and endless
past it are solver-verified beatable.

What's missing is **connective tissue** — the stuff that makes a player feel
they're inside a warm, finished product instead of operating a stack of correct
systems:

1. **A real tutorial.** Right now it's four passive text banners.
2. **A home.** The game boots straight onto Level 1 — no title, no logo, no "Play".
3. **Long-term goals.** No achievements, no collection screen, no stats page.
4. **A thread of story.** No framing, no character, no reason the cottage matters.
5. **Level variety.** Every one of 40 levels is the identical task.

None of this is hard. It's mostly UI and content on top of systems that already
exist. Ranked plan at the bottom.

---

## 1. The tutorial — the #1 gap

**Your instinct is right.** A new player today gets:

- `game/coach.gd`: one non-interactive banner, shown on stages 0–3 only:
  - L1 "Tap a jar to pick it up, then tap another to pour matching colours on top."
  - L2 "Some jars are mixed. Look for a pour that frees a whole colour."
  - L3 "Wrong move? Tap Undo below to take it back."
  - L4 "Out of room? The Jar button gives you a spare to work with."
- 4 well-designed hand-authored layouts (`HAND_LEVELS` 0–3).
- The Daily pop-up is correctly suppressed on session 1.

### What's wrong

- **It's passive.** No hand/finger pointer, no glow on the jar to tap, nothing
  stops a lost player from flailing. Mobile players who don't read the banner —
  most of them — are on their own. Top sort games *point at the first move* and
  don't advance until the player makes it.
- **No first-pour celebration.** The very first successful pour should feel
  great — a little burst, a sound, "Nice!". Right now it's silent.
- **The meta is never explained.** Player wins L1, sees "+50 coins", and nothing
  says what coins are *for*. The cottage — the entire reason to return — is
  introduced by an unlabelled "Cottage" button they have no reason to press.
- **The move budget arrives unannounced.** L1–L10 are fail-free (`flow`). The
  first budgeted level (L11) just… has a move counter now, with no "from here
  on, moves are limited — plan ahead" beat.
- **Stars are never taught.** The player 1-stars a few levels without knowing
  why, or that fewer moves = more stars = more reward.

### The redesign (small, high-impact)

**FTUE flow (first ~4 minutes):**

| Beat | What happens |
|---|---|
| Cold open | Title card → one line of framing (see §2e) → "Let's tidy up." |
| L1 | Dim everything except one jar; pulsing finger points to it, then to the target. Board ignores taps elsewhere until the taught pour lands. Big "Nice!" + juice on success. Repeat the point once for the winning pour. |
| L1 win | "+50 coins" animates into a coin pill; a callout: *"Coins rebuild your cottage."* Auto-open the Cottage for 3 seconds showing the run-down house, then "Let's earn some more." |
| L2 | Free play, banner: "Some jars are mixed — free a whole colour first." |
| L3 | Force one wrong-ish move is impossible to script safely; instead just surface Undo with a one-time glow the first time a pour is made. |
| L4 | Glow the **Jar** button once when the board first has no legal move. |
| L11 (first budget) | One-time modal: *"Moves are limited from here. Run out and you can watch an ad, spend coins, or restart — no lives, ever."* |
| First 2-star, first 3-star | One-time toast explaining the star tiers and that they pay bonus coins. |

**Build notes:** `coach.gd` already owns the banner; add a `point_at(rect)`
finger sprite and a `gate` mode on `board.gd` (`_unhandled_input` early-returns
unless the tap matches `_tutorial_allow`). Everything is one-time, gated on
`SaveData` flags (`ftue_pour_done`, `ftue_budget_seen`, `ftue_star2_seen`, …).
No new screens.

---

## 2. "Feels like a full game" — the missing frame

### 2a. Title / home screen

There is no main menu. `main._ready()` runs straight into `_load_current()`.
Add a light **Home**: the logo, the cottage art as a backdrop that visibly
improves as it's restored, a big **Play** (→ current level), and small
Cottage / Daily / Settings buttons. This is the single biggest "this is a real
product" signal, and it's ~one screen. It also gives Daily / Season / Shop a
natural front door instead of burying them under a "Menu" button mid-puzzle.

### 2b. Achievements *(you asked for this)*

Nothing exists. Add an **Achievements** screen (grid of badges, locked ones
shown as silhouettes) with a coin/gem reward per unlock. All the data needed is
already in `SaveData`. Starter set (~24):

- **Progress:** clear 10 / 25 / 50 / 100 levels · reach Chapter 2 / 3 / 4 / 6 ·
  finish the authored curve (L40) · reach endless L60 / L80.
- **Skill:** first 3-star · 3-star 10 / 30 levels · a flawless clear (3-star, no
  undo/hint) · a x3 / x5 combo · beat par on 5 levels.
- **Cottage:** first upgrade · fully restore a room · 100% restored · complete
  Garden / Kitchen / Cozy Nook set · own 25 decor · complete a seasonal set.
- **Habit:** 3 / 7 / 30-day login streak · claim a weekly chest · win a daily
  jackpot · finish a battle-pass season · reach BP tier 30.

Achievements double as a to-do list on quiet days and a great notification
source ("You're 2 levels from *Cottage Regular*").

### 2c. Collection album

Decor is bought and drawn ~12px tall in the cottage scene — there's no payoff
screen. Add a **Collection** tab: every decor item as a card, owned ones in
colour with a short flavour line, unowned as a silhouette + price, set-completion
bars, and the seasonal sets you've missed marked "past season". This turns
`decor_data.gd` (already 3 fixed sets + 4 seasonal + endless) into something
players *want to fill in*. Pairs with an achievement track.

### 2d. Stats / profile page

Players read these obsessively and they make a game feel substantial. One
screen, all data already tracked: levels cleared, total stars (`SaveData.total_stars()`),
best combo, lifetime coins earned, days played, current streak, % cottage
restored, decor owned, deepest endless level, battle-pass seasons completed.
Add a couple of counters that aren't tracked yet (best combo, lifetime coins,
days-played) — trivial `SaveData` keys.

### 2e. A thread of story + a companion

The game is warm mechanically but has zero narrative. For near-zero cost:

- **One paragraph of framing** on first launch: *"Your gran left you her
  cottage. It's a little wild now — but a good sort-out and it'll be home
  again."* One card, skippable, never shown again.
- **The cat as a companion.** "Sleepy cat" is already a decor item
  (`n_cat`, 300c). Promote it: a small cat that sits on the shelf on the puzzle
  screen, reacts to wins (stretch, purr), and occasionally "leaves" a small
  gift (a few coins / a booster) as a return hook. It's a face for the game.
- **Chapter intro cards.** Realms already exist (`realms.gd`, 6 chapters). When
  a new chapter starts, show a full-bleed card: chapter name, a line of flavour
  ("The Garden — everything's overgrown, but the roses remember"), the new
  palette. Currently it's a one-line toast.

### 2f. Name the moments

- **Level names / "corners".** The win screen says "Cottage corner tidied!"
  generically. Give the authored 40 short names ("The Jam Shelf", "Under the
  Stairs") — pure flavour text in `level_data.gd` or a parallel list.
- **The game's name is invisible in-game.** It appears nowhere on screen. The
  Home screen fixes this.

---

## 3. Content depth

### 3a. More authored levels

40 hand-shaped levels + endless. For a game that wants to feel full, that's
thin — the genre leaders ship hundreds. Endless (now ramping, M32) covers
"infinite" but reads as filler. Target **~120 authored** before wide launch,
in chapter-sized batches of ~15, each batch re-frozen via
`tools/bake_levels.gd`. This is the highest-effort item here but the most
direct answer to "more content".

### 3b. Level-goal variety

Every level is "sort every jar". Introduce 3–4 gentle variants, one new idea per
chapter, flagged in the stage knobs:

- **Beat par** — *done (M39)*: from L11 the win screen shows "par N" and a ✓ +
  30-coin bonus for `moves <= par`. A soft skill target under the stars.
- **Tidy pour** — a couple of jars start with a lid; clear the rest first to pop
  them (a soft "locked jar"). *Deferred — needs a new board mechanic.*
- **No spares** — a level with zero empty jars to start (the deferred
  1-spare/"challenge" idea from `DESIGN.md`). *Deferred — safe now that LevelGen
  verifies solvability; just a knob + label.*
- **Colour rush** — sort one *highlighted* colour first for an early bonus.
  *Deferred — needs highlight + tracking.*

Keep it rare and cosy — variety, not difficulty spikes.

### 3c. Endless milestones + a depth board

Endless has no reward structure — you just keep going. Add:

- Milestone chests at L50 / L75 / L100 / every 25 after (coins + gems + booster).
- Track **deepest endless level** in `SaveData`; show it on the stats page and
  splice it into the weekly leaderboard as a second tab ("This week" stars /
  "All-time" depth).

### 3d. Realm bead skins *(AUDIT_FUNCTIONAL #4)*

Beads are the same colours in every chapter. A per-realm tint or motif (jam jars
in the Pantry, seed packets in the Garden, spools in the Workshop) would make
the 6 chapters feel like different places rather than different wallpaper.
`board.gd` already reads `realm` for bg/shelf — extend it to a bead palette
shift.

### 3e. Cottage room 2 has no visual payoff *(AUDIT_FUNCTIONAL #3)*

`cottage_data.gd` has the Kitchen (4 slots, up to tier 3) but `cottage_view.gd`
only draws the exterior — buying Kitchen tiers changes nothing on screen. Draw
an interior strip or a second structure so the Kitchen purchases *land*.

---

## 4. Fun & feel polish (cheap, cumulative)

- **Flawless badge** on the win screen — 3-star with no undo/hint. A pride hook
  and a natural share moment. *(AUDIT_FUNCTIONAL #2)*
- **Per-colour pitch** — a tiny pitch shift on the pour SFX per bead colour
  makes sorting feel musical. Near-free. *(AUDIT_FUNCTIONAL #7)*
- **Last-jar juice** — when only one jar remains unsorted, lean the camera /
  add a heartbeat; make the final pour a bigger moment.
- **Near-miss tension** — at ≤3 moves left the budget text already turns red;
  add a soft pulse and a quieter music duck.
- **First-time celebrations** — first combo, first booster use, first decor
  bought, first room finished each deserve a one-time flourish.
- **Win-screen chapter bar** — "3 corners to the Garden" gives every win a
  visible next goal beyond "Next".

---

## 5. Monetization depth still on the table

From `AUDIT_FUNCTIONAL.md` — built systems, unbuilt money features:

- **BP tier skip** — buy 3–5 tiers for gems near season end. Standard, well-liked.
- **Cosmetic gem sink** — premium decor sets sold for gems (gems currently only
  buy boosters/continues; no vanity outlet).
- **Seasonal storefront** — bundle the live seasonal decor set at a gem discount
  during its 28-day window.
- **First-purchase doubler** — "your first gem pack, doubled", one-time.
- **Piggy-bank tier 2** — a bigger $9.99 bank that unlocks after the first crack.
- **Remove-ads → daily gem stipend** — makes the $2.99 feel subscription-lite.
- **Rotating daily deal** — the Shop is a static list; one rotating discounted
  slot adds a reason to open it.

---

## 6. Roadmap — recommended order (M33+)

| # | Item | Why | Effort |
|---|---|---|---|
| M33 | **Interactive FTUE** (§1) + first-pour juice + meta explainer | Biggest D1 lever. Pure design/UI on existing systems. | M |
| M34 | **Home screen** (§2a) + game name + chapter intro cards (§2e) | "Real product" signal; front door for Daily/Shop/Season. | S–M |
| M35 | **Achievements** (§2b) — screen + ~24 badges + rewards | Long-term goals; notification fuel; you asked for it. | M |
| M36 | **Collection album** (§2c) + **Stats page** (§2d) | Makes existing decor/stars *feel* like content. | M |
| M37 | **Story paragraph + the cat companion** (§2e) | Cheap warmth; a face for the game; return hook. | S–M |
| M38 | **Feel polish bundle** (§4) — flawless badge, per-colour pitch, last-jar juice, first-time flourishes | Cumulative "juice"; each piece is tiny. | S |
| M39 | **Level-goal variety** (§3b) + **realm bead skins** (§3d) + **Kitchen visual** (§3e) | Variety without difficulty; chapters feel distinct. | M |
| M40 | **Endless milestones + depth board** (§3c) | Rewards the grind; second leaderboard tab. | S–M |
| M41+ | **Author L41–120** (§3a), in chapter batches; re-bake each | The real "more content"; ongoing. | L |
| ongoing | **Monetization depth** (§5) — tier skip, gem cosmetics, seasonal storefront, first-buy doubler | Revenue depth once the above lifts retention. | S each |

## If you do only three things

1. **The interactive tutorial (M33).** Point at the first move, celebrate it,
   explain that coins rebuild the cottage, warn once about the move budget.
   Everything else is worth less if the first four minutes don't land.
2. **A Home screen (M34).** Logo, Play, the cottage as a living backdrop. It's
   one screen and it reframes the whole game as a place you visit, not a level
   you're dropped into.
3. **Achievements (M35).** The cheapest way to add dozens of hours of goals on
   top of systems you've already built, and the best notification source you're
   not using.
