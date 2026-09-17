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
- [x] Multiplayer: LAN/hotspot via ENet first (Android).
- [x] Python backend (FastAPI, WebSockets, Redis queue) for global matchmaking.
- [x] Exit check: Connect 2 clients over LAN; start match. Matchmake 2 web clients globally.tch over internet relay (including one browser client).

## Phase 5c: SimpleBallPhysics & Interactive Controls
- [x] 2.5D ball trajectory engine (SimpleBallPhysics) with altitude scalar + ground shadow.
- [x] Bowling pitch cursor (length/line placement) and release timing meter.
- [x] Batting InputRouter with direction, shot type, and timing-window quality resolution.
- [x] MatchEngine refactored: `bowl_ball_with_params()`, `submit_shot()`, `AWAITING_SHOT` state.
- [x] Exit check: Interactive over runs in Godot client; cursor dictates bounce, ball arcs in 2.5D, timed swing resolves into scorecard.

## Phase 6
- [x] Abstract OfflineMultiplayerInterface (signals + virtual methods).
- [x] OfflineMultiplayerMock loopback implementation for desktop/CI.
- [x] Android Nearby Connections Kotlin plugin scaffold (P2P_STAR, permissions, payload callbacks).
- [x] NearbyConnectionsBridge GDScript wrapper.
- [x] NetworkManager auto-detects provider (Android native vs. desktop mock).
- [x] MainMenu UI: "OFFLINE P2P: HOST" and "OFFLINE P2P: SEARCH" buttons.
- [x] Headless test: discovery, connection, packet send/decode — ALL PASSED.
- [x] Exit check: Mock provider simulates two air-gapped peers completing a match handshake with zero network sockets.

## Phase 7
- [x] Data Schemas (`src/data/schemas/`): `player_schema.json` and `team_schema.json`.
- [x] Initial JSON Payload (`src/data/db/roster.json`): Team A (Dhaka) and Team B (Generic Giants).
- [x] DataLoader Autoload (`src/core/data_loader.gd`): JSON parser singleton.
- [x] UI & Engine Wiring: MatchSetup queries DataLoader; MatchEngine pulls players into batting/fielding arrays.
- [x] MatchView injects `bat_hand` to AnimationController.
- [x] Exit check: Data loads without code changes, player names correctly show up in scorecard UI.

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
