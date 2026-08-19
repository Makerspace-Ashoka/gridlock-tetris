# GRIDLOCK: Sabotage Tetris

Competitive 1v1 Tetris built for large-format wall projection. One self-contained
HTML file, no dependencies, no build step, works offline.

---

## Running it

**Recommended: serve it over HTTP.** Some browsers refuse `localStorage` on
`file://` origins, and the scoreboard lives in `localStorage`. If storage is
blocked the game still plays but shows a red banner and forgets every result.

```bash
cd "/Users/rishivashist/Documents/Tetris:DoodleJump" && python3 -m http.server 8777
```

Then open `http://localhost:8777` and press **F11** for fullscreen.

Double-clicking `index.html` also works, but check that the red
"scores are not being saved" banner is absent before running an event on it.

Chrome or Edge are the safest picks, with the best Gamepad API coverage and the
most predictable fullscreen behaviour on a second display.

---

## Controls

Xbox and PlayStation pads both use the browser's standard mapping, so no setup is
needed: plug in, and the first two pads become P1 and P2. The attract screen
shows which pads it can see.

| Action | Gamepad | Player 1 keys | Player 2 keys |
|---|---|---|---|
| Move | D-pad ← → / left stick | `A` `D` | `←` `→` |
| Soft drop | D-pad ↓ / stick down | `S` | `↓` |
| Hard drop | D-pad ↑ / stick up | `W` | `↑` |
| Rotate CW | `A` button | `K` | `.` |
| Rotate CCW | `B` button | `J` | `,` |
| Rotate 180° | `X` button | `I` | `;` |
| Hold | `LT` | `L` | `/` |
| Select sabotage | `LB` / `RB` | `Q` `E` | `[` `]` |
| **Fire sabotage** | `RT` or `Y` | `F` | `Enter` |
| Pause / confirm | `START` | `1` | `2` |
| Back | `BACK` | `Esc` | n/a |

Keyboard is always live alongside the pads, so a dead controller mid-event is
never fatal.

On the **name screen** the keyboard becomes a plain typewriter: type a callsign,
press `Enter`, type the second, press `Enter`. On a pad, use up/down to spin the
letter wheel, left/right to move the cursor, `A` to confirm, `B` to backspace,
and `X` to recall a previous player's name.

---

## The twist: sabotage

Clearing lines charges an **energy bar** (0 to 100). T-spins, back-to-backs, combos
and perfect clears charge it much faster than flat clears. Spend it on six
abilities, selected with the shoulder buttons and fired with the trigger.

| Ability | Cost | Effect |
|---|---|---|
| **FOG** | 20 | Removes the opponent's ghost piece for 12s |
| **SHIELD** | 25 | *Self*: purges all incoming garbage, 6s immunity |
| **SCRAMBLE** | 30 | Inverts the opponent's left/right for 8s |
| **BLACKOUT** | 40 | Hides their next queue and hold, dims their well, 8s |
| **OVERCLOCK** | 45 | 5× gravity on the opponent for 6s |
| **MIRROR** | 55 | Instantly flips their entire stack horizontally |

Because `SHIELD` is defensive, holding energy in reserve is a real decision:
you can bank for a `MIRROR` or spend early to survive a garbage wave.

Standard Tetris attack still runs underneath: doubles, triples, tetrises,
T-spins, back-to-backs, combos and perfect clears all send garbage, your outgoing
attack cancels your own incoming first, and no more than 8 garbage lines land per
piece placement (the rest stays queued and telegraphed on the bar beside the well).

---

## Match structure and scoring

- A match is **best of N rounds** (1/3/5/7, set on the name screen with `LB`/`RB`,
  or in the operator panel). First to win `ceil(N/2)` rounds takes the match.
- A round ends when someone tops out. With an optional round timer set, the
  higher score wins when time expires.
- Each round shows a **winner and a full stat breakdown**: score, lines, garbage
  sent, best combo, tetrises, T-spins, sabotage fired, pieces/sec.
- Match end shows aggregate totals and flags a new personal best.
- Everything rolls into the **overall scoreboard**, ranked by match wins, then
  round wins, then total points, and kept per callsign across every session on
  that machine.

Round score rewards both style and aggression: standard guideline line values
scaled by level, ×1.5 for back-to-back, combo bonuses, big perfect-clear bonuses,
plus soft/hard drop points.

---

## Projection setup

Press **F1** for the operator panel.

1. **F3** opens the test grid. Focus the projector and align the outer pink border to the wall.
2. **F2** shows the warp handles. Drag the four cyan circles onto the wall's corners.
   Click a handle and nudge it with the arrow keys (hold `Shift` for 10× steps).
   The image is corrected with a true projective (homography) transform, so
   off-axis mounting is fine.
3. **Image** sliders for brightness, contrast, gamma, saturation and *black lift*.
   Black lift is the one to reach for when ambient light is washing the wall out.
4. **Look** covers scanlines, vignette, chromatic aberration and glow. Turn glow down
   if the wall texture is smearing the neon.
5. **Flip 180°** for a ceiling-mounted projector.
6. **Render scale**: leave at 1.00 for a 1080p projector. Raise for a 4K surface,
   lower if the FPS readout drops. **FPS READOUT** toggles an on-screen diagnostic.

All calibration persists automatically. `EXPORT JSON` in the panel dumps the
calibration, settings, scoreboard and match history in one blob, worth grabbing
after you've dialled the wall in, so you can restore it or move it to another
machine with `IMPORT` / `APPLY PASTED`.

The scene is authored at a fixed 1920×1080 and composited to the display through
WebGL, so the layout never reflows. What you calibrate is what you get.

---

## Hotkeys

| Key | |
|---|---|
| `F1` | Operator panel |
| `F2` | Warp handles |
| `F3` | Test grid |
| `F11` | Fullscreen |
| `START` (in match) | Pause |
| `Esc` (paused) | Abandon match, return to attract |

---

## Files

- `index.html`: the entire game. Everything else is optional.
- `README.md`: this document.
