# Feeture (Godot)

A stealth **feet-photography friendslop roguelike**. You are a sneaky foot
photographer sneaking through public spaces, snapping candid shots of NPCs'
feet without getting caught. Creep meter too high? Game over. Get the shot,
stay unnoticed, and build your album of shame.

This is a **fresh Godot rebuild** of the game. The original Unity prototype
remains at [github.com/ChonkTK/Feeture](https://github.com/ChonkTK/Feeture).

## How to run (Windows)

1. Install **Godot 4.7.2** (Standard build) from [godotengine.org](https://godotengine.org/download/windows/).
2. Open this folder's `project.godot` in the Godot editor.
3. Press **Play** (F5).

An exported standalone binary will be provided in a later release; until then
the editor run is the supported way to play.

## Controls

| Action        | Key                          |
|---------------|------------------------------|
| Move          | WASD                         |
| Look          | Mouse                        |
| Crouch        | Shift                        |
| Sprint        | Ctrl                         |
| Lean          | Q / E                        |
| Zoom          | Right mouse button          |
| Photograph    | Left mouse button           |
| Interact / Hide| F                           |
| Album         | Tab                          |
| Pause         | Esc                          |

All actions are remappable in the in-game settings menu, and the game also
supports gamepad/controller input.

## What's implemented (M1–M3)

- **4 procedural levels**: Beach, Subway, Restaurant, Park — each with its own
  layout, props, and mood.
- **Creep meter rule**: being seen, making noise, or getting caught raises
  creep; maxing it out loses the run.
- **NPCs**: patrol states, vision cones, hearing/noise reactions, hiding spots,
  and suspicion behavior.
- **Photo system**: aim, zoom, and shoot; photos are scored **S / A / B / C**
  and stored in an album.
- **Objectives**: target NPCs to photograph, with win/lose conditions.
- **Toon look**: toon shader, per-level environment and lighting mood,
  vignette.
- **Procedural audio**: footsteps, shutter, crowd ambience, and tension cues —
  no audio assets needed.
- **Settings & UI**: settings menu with key remapping, HUD, album UI, and
  pause menu.

## Architecture

- **Autoloads**: `GameManager` (run state, creep, win/lose), `PhotoAlbum`
  (photo storage/scoring), `NoiseSystem` (noise propagation), `Settings`
  (remapping/persistence), `AudioManager` (procedural audio).
- **Scenes**: `scenes/main.tscn` (entry), `scenes/player/player.tscn`,
  `scenes/npc/npc.tscn`; levels are built procedurally at runtime.
- **Scripts**: `scripts/levels/` (level definitions + builder),
  `scripts/player/`, `scripts/npc/`, `scripts/stealth/` (noise, hiding),
  `scripts/photo/` (capture, album), `scripts/ui/` (HUD, album, pause,
  settings), `scripts/audio/`, `scripts/tests/` (headless test suite).

## Roadmap

- **M4**: roguelike loop — currency, gear, cosmetics, run meta; multiplayer.
- **M5**: polish — animations, more level variety, juice, and the first
  exported demo build.

## Tests

Headless test suite in `scripts/tests/` (run with
`godot --headless --script res://scripts/tests/<name>.gd`); smoke test via
`godot --headless -- --smoke`.
