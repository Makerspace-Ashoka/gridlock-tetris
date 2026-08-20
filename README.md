# GRIDLOCK: Sabotage Tetris

Competitive 1v1 Tetris built for projection mapping onto a tiled facade. One
self-contained HTML file, no dependencies, no build step, works offline.

The game is authored on a **physical tile grid**, so one Tetris cell is drawn as
exactly one tile of the wall.

---

## The wall

The target surface is a lattice facade with an archway punched through the
bottom centre. Geometry is described as three columns and a row count:

```
    left pillar        archway         right pillar
    10 tiles           12 tiles        10 tiles          = 32 across
    +--------------+---------------+--------------+
    |              |               |              |
    |   P1 WELL    |   HUD BAND    |   P2 WELL    |   6 rows
    |   10 x 12    |   12 x 6      |   10 x 12    |
    |              +---------------+              |
    |              |               |              |
    |              |   ARCHWAY     |              |   6 rows
    |              |   NEVER LIT   |              |
    +--------------+---------------+--------------+
                                                      12 rows down
```

Both pillars are solid top to bottom, so each holds a complete 10-wide, 12-tall
well. Everything that is not a well lives in the band above the arch. The
archway region is painted black as the very last step of every frame and its
projection region is excluded from the output, so no screen can ever spill light
into the opening.

Geometry is adjustable live in the operator panel (F1): left pillar, arch width,
right pillar, rows down, arch height. Wells resize to match, and the garbage cap
and perfect-clear bonus rescale with the well height automatically.

---

## Running it

**Serve it over HTTP.** Some browsers block `localStorage` on `file://`, and the
scoreboard lives there. The game shows a red banner if storage is blocked.

```bash
cd "/Users/rishivashist/Documents/Tetris:DoodleJump" && python3 -m http.server 8777
```

Open `http://localhost:8777`, then F11 for fullscreen. Chrome or Edge are the
safest picks for Gamepad API coverage.

---

## Projection setup

| Key | |
|---|---|
| `F1` | Operator panel |
| `F2` | Mapping mode |
| `F3` | Test grid |
| `F4` | Input diagnostics |
| `F5` | Tile grid overlay |
| `F11` | Fullscreen |

**Recommended order on site:**

1. `F3` test grid. Focus the projector, then align the outer pink border to the
   facade edges. The grid draws one square per wall tile, and the arch is
   outlined in pink and labelled.
2. `F2` mapping mode. Drag the four **GLOBAL** handles onto the facade corners.
   The wall is flat, so this single four-corner homography is mathematically
   exact for the whole surface. This is usually all you need.
3. Still in mapping mode, press `2`, `3` or `4` to select the **LEFT**, **MID**
   or **RIGHT** region and nudge it onto the lattice by itself. Regions start
   *linked* to the global warp, which keeps them seamless; dragging a region
   handle unlinks it. `RESET REGION` relinks it.
4. `F5` tile grid overlay while the game is running, to confirm blocks land on
   real tiles.
5. Image sliders: brightness, contrast, gamma, saturation and **black lift**.
   Black lift is the one to reach for when ambient light washes the wall out.

Arrow keys nudge the selected corner, `Shift` for 10x steps, `Tab` cycles
corners. Everything persists automatically. `EXPORT JSON` dumps calibration,
settings, scoreboard and history in one blob for backup or transfer.

---

## Controls

Xbox and PlayStation pads both use the browser's standard mapping. Plug in and
the first two pads become P1 and P2. The full control diagram is shown on the
attract screen and again during name entry, so walk-up players never need to be
told how to play.

| Action | Gamepad | Player 1 | Player 2 |
|---|---|---|---|
| Move | D-pad left/right | `A` `D` | `LEFT` `RIGHT` |
| Soft drop | D-pad down | `S` | `DOWN` |
| Hard drop | D-pad up | `W` | `UP` |
| Rotate CW / CCW | `A` / `B` | `K` / `J` | `.` / `,` |
| Rotate 180 | `X` | `I` | `;` |
| Hold | `LT` | `L` | `/` |
| Select sabotage | `LB` / `RB` | `Q` / `E` | `[` / `]` |
| Fire sabotage | `RT` or `Y` | `F` | `ENTER` |
| Pause / confirm | `START` | `1` | `2` |

Keyboard stays live alongside the pads, so a dead controller mid-event is never
fatal. On the name screen the keyboard becomes a plain typewriter.

---

## Controller latency

Polling gamepads once per animation frame is the usual cause of input that feels
buffered: a tap shorter than a frame is dropped entirely, and every press is read
up to a frame late. This build instead runs a **high-rate sampler** (250 Hz by
default) that does its own edge detection and latches rising edges; the frame
loop just drains the latch. The frame loop also samples as a floor, so throttled
timers degrade to old behaviour rather than stalling.

`F4` opens **input diagnostics**:

- **Sample age** is the number that matters. It is `now - gamepad.timestamp`,
  literally how stale the reading was when polled. A wired pad sits under 5 ms;
  a Bluetooth pad typically reports 20 to 40 ms stale. If one controller feels
  behind, this is where you will see it, and the fix is usually to wire that pad
  up rather than to change anything in software.
- **Report rate** is how often the pad actually pushes new state.
- **Longest gap** catches a pad that intermittently stops reporting.
- **Latch to frame** is how long a press waited between detection and use.
- **Relative lag test**: press a button on both pads at the same instant and it
  shows the delta in milliseconds and which pad registered first.
- Live button and axis readouts for verifying mapping on unusual hardware.

`HIGH-RATE POLLING` can be toggled off in the panel to A/B the difference. Poll
rate, DAS and ARR are all adjustable live.

---

## Gameplay

Standard guideline engine: SRS with wall kicks, 7-bag randomiser, hold, ghost
piece, lock delay with move-reset cap, T-spin detection, back-to-back, combos and
perfect clears.

**Sabotage** is the twist. Clearing lines charges an energy bar; T-spins,
back-to-backs, combos and perfect clears charge it much faster. Spend it on six
abilities, selected with the shoulder buttons and fired with the trigger.

| Ability | Cost | Effect |
|---|---|---|
| FOG | 20 | Removes the opponent's ghost piece, 12s |
| SHIELD | 25 | *Self.* Purges all incoming garbage, 6s immunity |
| SCRAMBLE | 30 | Inverts the opponent's left/right, 8s |
| BLACKOUT | 40 | Hides their queue and hold, dims their well, 8s |
| OVERCLOCK | 45 | 5x gravity on the opponent, 6s |
| MIRROR | 55 | Instantly flips their entire stack horizontally |

SHIELD being defensive makes banking energy a real decision rather than a
spend-on-cooldown meter.

**Balance note.** A 12-row well is 40% of a standard one, so a burst that is
merely nasty at 20 rows is lethal here. Garbage is capped per lock and the
perfect-clear bonus is scaled, both derived from well height, so changing the
row count in the panel keeps the balance sane. At 12 rows the cap is 4 lines per
placement, with the remainder staying queued and telegraphed.

---

## Match structure and scoring

- Best of N rounds (1/3/5/7), set on the name screen with `LB`/`RB` or in the
  panel. First to `ceil(N/2)` round wins takes the match.
- A round ends on a top-out, or on higher score if a round timer is set.
- Each round shows a winner plus a full stat breakdown per player.
- Match end shows aggregate totals and flags a new personal best.
- Everything rolls into a persistent overall scoreboard, ranked by match wins,
  then round wins, then total points, kept per callsign across sessions.

---

## Files

- `index.html`: the entire game.
- `README.md`: this document.
