# Phase Build Checklist

## Phase 0
- [x] Repo scaffold, Godot project with Web + Android export presets.
- [x] Web build with PWA/offline support enabled.
- [x] Doc system files created, lint/format config, security baseline.
- [x] Exit check: Web export succeeds and passes offline-reload test. Android export succeeds locally (or via CI).

## Phase 1
- [x] MatchEngine core loop for one format (T20).
- [x] Placeholder capsule/stick sprites.
- [x] Scoring + wickets + overs logic.
- [x] Written so it can also compile as a headless server target.
- [x] Zero network calls on the single-player path.
- [x] Exit check: A full T20 innings can be simulated headless and scorecard is correct; single-player runs with the device/network fully disabled.

## Phase 2
- [x] Pixel art pipeline decided.
- [x] `docs/animations.md` full clip list authored.
- [x] First right-handed batsman/bowler animation pair implemented.
- [x] Exit check: Visual playtest of one over with real sprites.

## Phase 3
- [x] Full animation matrix implemented.
- [x] Left/Right hand variants dynamically mirrored.
- [x] Outcomes correctly wired to visual sequences.
- [x] Exit check: Rigged visual sequence correctly displays a boundary, wicket, and dot ball in order.
- [x] **Phase 3b**: Advanced Authentic Cricket mechanics (Wicketkeeper, Stumps nodes, LBW appeals, Third Umpire TV delays, bails flying).

## Phase 4
- [x] Menu system, match setup flow, custom fielding placement UI, scorecard/stats screens.
- [x] Exit check: Full match simulation completed through UI with airplane mode enabled (offline-first compliance).

## Phase 5
- [ ] Multiplayer: LAN/hotspot via ENet first (Android).
- [ ] Multiplayer: Online via WebSocket + headless Godot server behind FastAPI.
- [ ] Exit check: Two Android clients match over LAN; two clients match over internet relay (including one browser client).

## Phase 6
- [ ] Fully-offline local P2P via native Android Nearby Connections plugin.
- [ ] Exit check: Two Android devices match with no network at all.

## Phase 7
- [ ] Real roster/team data integration.
- [ ] Exit check: Data loads without code changes.

## Phase 8
- [ ] Card/lootbox campaign meta system.
- [ ] Exit check: Pack opening, card economy, campaign progression testable.

## Phase 9
- [ ] Optimization + security + Play Store readiness pass.
- [ ] Exit check: Meets performance budget, no critical vulns, Play Store checklist complete.

## Phase 10 (Deferred)
- [ ] iOS export preset, native MultipeerConnectivity plugin.

---
See `docs/master_context.md`
