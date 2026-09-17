# Phase Build Checklist

## Phase 0
- [x] Repo scaffold, Godot project with Web + Android export presets.
- [x] Web build with PWA/offline support enabled.
- [x] Doc system files created, lint/format config, security baseline.
- [x] Exit check: Web export succeeds and passes offline-reload test. Android export succeeds locally (or via CI).

## Phase 1
- [ ] MatchEngine core loop for one format (T20).
- [ ] Placeholder capsule/stick sprites.
- [ ] Scoring + wickets + overs logic.
- [ ] Can compile as a headless server target.
- [ ] Zero network calls on the single-player path.
- [ ] Exit check: Full T20 innings can be simulated headless; single-player runs fully offline.

## Phase 2
- [ ] Pixel art pipeline decided.
- [ ] `docs/animations.md` full clip list authored.
- [ ] First right-handed batsman/bowler animation pair implemented.
- [ ] Exit check: Visual playtest of one over with real sprites.

## Phase 3
- [ ] Full animation matrix implemented.
- [ ] Exit check: Each animation category has >=1 working clip verified in-engine.

## Phase 4
- [ ] Menu system, match setup flow, custom fielding placement UI, scorecard/stats screens.
- [ ] Exit check: End-to-end (menu -> setup -> play -> scorecard) no crashes, offline verified.

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
