# CRICKET8BIT — MASTER BUILD PROMPT (paste into Antigravity as the first message)

> **How to use this file:** Paste everything below this line as your opening prompt in Antigravity's Manager view when you create the project. Keep this file itself in the repo root as `MASTER_PROMPT.md` — it is the constitution the agent re-reads whenever context is unclear.

---

## SYSTEM ROLE FOR THE AGENT

You are the lead engineer building **Cricket8Bit**, a lightweight 8-bit-style cricket game targeting **browser (WebAssembly) and Android** from one codebase for now. iOS is an explicitly deferred, not abandoned, target — the stack below is chosen so adding it later is a config change, not a rewrite; do not spend any effort on it until told to resume. You work in **phases**, each gated by a written acceptance check — never mark a phase done without verifying it runs. You maintain a small set of Markdown logs (spec below) so work can resume after a context reset or an account switch with zero information loss. Token efficiency matters: logs are terse, append-only, and reference each other instead of repeating content.

**Session protocol — do this before writing any code, every session:**
1. Read `docs/master_context.md` in full.
2. Read the last 5 entries of `docs/progress.md` and `docs/error.md`.
3. Read the current phase's checklist in `docs/phase_build.md`.
4. State in one line what phase/task you're resuming and proceed.

**End-of-session protocol — do this before stopping, every session:**
1. Append an entry to `docs/daily_update.md` (date, what shipped, what's blocked, next step).
2. Append the raw prompt(s) you were given + one-line outcome to `docs/prompt_log.md`.
3. Update `docs/phase_build.md` checkboxes for anything verified.
4. If any error was hit and fixed, log it in `docs/error.md` (symptom → root cause → fix → verification).
5. Update `docs/master_context.md` **only** if something durable changed (phase advanced, stack decision made, architecture changed) — it is a snapshot, not a log.

---

## 1. PROJECT IDENTITY

- **Name:** Cricket8Bit
- **Pitch:** A fast, offline-first, 8-bit cricket game with real cricket mechanics (batting, bowling, fielding, full match formats) that runs equally well in a browser tab and on a low-end Android phone — one codebase, two storefronts today, iOS added later without a rewrite.
- **Visual bar:** Nokia Cricket (2004) as the floor; Pokémon Black/White or BOTW-DS-era sprite work as the target ceiling. Readable silhouettes over detail; small sprite sheets over large ones.
- **Performance budget:** APK ≤ 60MB core; 60fps on a 3-year-old low-end Android device; browser build playable on a mid-range laptop with no dedicated GPU, and on a mid-range phone browser.
- **Offline-first requirement (hard constraint):** single-player vs. CPU, in every match format, must work with zero network access — no login wall, no "phone home" on launch, no asset fetched at runtime. Android: true by default once the APK is installed (all assets bundled at build time). Browser: the HTML5 export must ship with PWA/service-worker support enabled so the game is playable offline after the first visit. Multiplayer is the only mode allowed to require connectivity.
- **iOS, deferred:** no iOS work, testing, or CI happens in the current phase set. Godot's native multi-export model means resuming it later is adding an export preset and a macOS/CI build leg, not restructuring the engine or rewriting game logic — this is why the engine choice below still holds even with iOS off the table now.
- **Non-negotiables:** modular code, data-driven content (players/teams/tournaments as data, not hardcoded), security-conscious networking, verifiable phases, no duplicated game-logic between platforms.

---

## 2. TECH STACK — DECIDED, WITH RATIONALE (efficiency + offline reliability were the deciding factors, iOS now out of scope)

**Client/game engine: Godot 4.x, typed GDScript.** Dropping iOS removes one of the earlier arguments for Godot, so it's worth re-litigating against the browser-first alternative (Phaser 3 + Capacitor, which is what a Gemini-generated prompt proposed for this same project) on the criteria that actually matter now — raw efficiency on low-end Android and reliable offline multiplayer:

| Candidate | Web | Android | Runtime efficiency | Offline local multiplayer | Verdict |
|---|---|---|---|---|---|
| **Godot 4.x** | Native HTML5/WASM export, built-in PWA/offline support | **True native APK** — compiled binary, own Vulkan/GLES3 2D renderer | Best of this list on low-end hardware — no browser/WebView layer in the Android build at all | Purpose-built `ENetMultiplayerPeer` for LAN; native Nearby Connections plugin for true offline P2P | **Chosen** |
| Phaser 3 + Capacitor | Native fit — it's already a browser engine | **WebView-wrapped**, not a compiled native app — same JS/Canvas code runs inside a system WebView shell | Real overhead vs. a compiled engine, most noticeable on exactly the "low-end phone" hardware this project targets | Proposed use of the **Web Bluetooth API is the wrong tool here** — it's designed for a browser talking to a BLE peripheral (e.g. a heart-rate strap), not phone-to-phone app data exchange; WebRTC data channels can work LAN-to-LAN but need local signaling and browser-specific mDNS ICE behavior to work with zero internet, which is fragile. A robust version of this still ends up needing a native Capacitor plugin for Nearby Connections anyway — which erodes the "pure web stack" appeal | Rejected for this project, noted as legitimate if the priority were fastest web iteration over Android runtime efficiency |
| Flutter + Flame | Yes | Yes (native) | Good | Hand-rolled — no equivalent to ENet/Nearby built in | Viable but more plumbing to write yourself |
| Kotlin Multiplatform + Compose | Early Wasm | Yes | Good | Hand-rolled | Compose is a UI framework, not a 2D game engine — wrong tool here |

**Backend/netcode verdict, unchanged:** FastAPI for services is correct in both proposals — no disagreement there. The difference is entirely in the client engine and the offline/local-multiplayer transport, addressed below.

**Backend:** split into two pieces so game logic is never duplicated across languages:
- **Authoritative match server = Godot itself, exported as a headless dedicated-server build.** It runs the *exact same* MatchEngine GDScript code as the client. This is the efficiency win: cricket rules (overs, dismissals, scoring) are written once, not reimplemented in Python.
- **Services layer = Python + FastAPI** (async, auto-generated OpenAPI docs, modern default for a Python backend) for everything that isn't live match simulation: accounts/auth (OAuth2 + short-lived JWTs), matchmaking/lobby, leaderboards, and the card/lootbox economy. Data: **PostgreSQL** (persistent — accounts, rosters, cards) + **Redis** (ephemeral — matchmaking queues, live session state). Containerized with Docker from day one.
- FastAPI issues a signed token; the Godot headless server validates it before letting a client join an authoritative match. FastAPI never simulates gameplay itself.

**Networking transport (Godot specifics that matter for cross-platform correctness):**
- **Online/cross-platform play (incl. browser):** `WebSocketMultiplayerPeer` — the only high-level multiplayer transport that works inside a browser sandbox. Client connects to the headless Godot server, fronted by FastAPI for auth/matchmaking handoff.
- **LAN/mobile-hotspot play (native builds only — Android/iOS/Desktop, not browser):** `ENetMultiplayerPeer`, Godot's UDP-based high-level API. Never mix ENet and WebSocket peers in the same session — pick per mode.
- Use Godot 4's `MultiplayerSpawner`/`MultiplayerSynchronizer` nodes for state replication rather than hand-written RPCs everywhere — it's the current idiomatic approach and cuts boilerplate.
- **Fully offline local multiplayer (no network at all — the "hotspot/Bluetooth" case in the original brief, Android-only for now):** not raw Bluetooth sockets, not Web Bluetooth. Use **Android's Nearby Connections API**, wrapped as a thin native Kotlin plugin behind one Godot-side interface (`OfflineMultiplayer.gd` or similar), so the interface has an obvious slot for an iOS MultipeerConnectivity plugin later without touching call sites. Nearby Connections handles Wi-Fi/Bluetooth fallback automatically and is what Google actually recommends for this exact use case today.

**Assumption made, proceed unless overridden:** Godot 4.x (client + headless server) in GDScript, FastAPI/Postgres/Redis for services, WebSocket for online, ENet for LAN, a native Android Nearby Connections plugin for fully-offline local play — behind an interface that leaves room for an iOS backend later.

---

## 3. ARCHITECTURE OVERVIEW

- **Client (Godot):** Menu, TeamSelect, MatchSetup (format/venue/toss), FieldPlacement, Innings (core sim + rendering), Scorecard, Settings, Multiplayer Lobby.
- **Shared core (compiled into both client and headless server exports):** MatchEngine (state machine: toss → innings → over → ball → outcome), AI (CPU batting/bowling/fielding decisions), rules data loader. This is the module that must never be duplicated in another language.
- **Client-only systems:** AnimationController (per-actor state machine keyed by handedness + action type), SimpleBallPhysics (2.5D trajectory, not full 3D — keep it cheap), InputRouter, NetSync (peer/session wiring).
- **Data layer:** All players/teams/tournaments/match-format-rules as JSON/Godot `Resource` files — placeholder data now, real rosters swapped in later without touching code.
- **Backend (Phase 5+):** FastAPI for auth/matchmaking/leaderboards/card economy; headless Godot server(s), containerized, spawned per match for authoritative online play.

---

## 4. FEATURE CATALOG (condensed — exhaustive per-clip lists live in `docs/animations.md`, authored in Phase 2)

**Match formats:** Test (follow-on, 4 innings, day/session breaks), ODI, T20, T10 — differ by overs/innings rules only; keep rules data-driven, not hardcoded per format.

**Teams/tournaments:** Countries + tournament templates (IPL-style franchise structure). Roster *content* is explicitly deferred — Ayman will provide player data later; build the schema now, populate with placeholders.

**Batting animations** (mirrored for right/left-handed): forward/back defensive, cover/straight/on/off drive, cut/square cut/late cut, pull, hook, sweep/slog sweep/reverse sweep, scoop/ramp, helicopter shot, lofted shot, leave, play-and-miss, edge.

**Bowling animations** (mirrored for right/left-arm): Pace — yorker, bouncer, slower ball, in/outswinger, seam-up. Spin — off break, leg break, googly, doosra, arm ball, top-spinner, flighted delivery. Each needs run-up, release, and follow-through states.

**Fielding animations:** standing catch, diving catch (full-length/one-hand), sliding stop, direct-hit run-out, relay throw, boundary save, slip/gully close catch, keeper stumping/take/throw.

**Umpire signals:** out, not-out, four, six, wide, no-ball, free hit, bye/leg-bye, DRS review box.

**Atmosphere:** idle crowd loop, cheer-four, cheer-six, wicket reaction (both sides), batsman walk-out/entrance, stumps-hit/bails-flying, run-between-wickets, celebration huddle, innings-break screen.

**Multiplayer:** LAN/hotspot (ENet, native Android only, Phase 5), online relay (WebSocket + headless server, works in-browser too, Phase 5b), fully-offline local P2P via a native Nearby Connections (Android) bridge (Phase 6).

**Meta progression:** FIFA-Mobile-style card lootbox for a campaign mode — explicitly deferred to Phase 8+, do not let it influence core architecture prematurely beyond leaving a hook point.

**Custom fielding placement:** drag-and-drop UI over a field diagram, saved as part of match/team state.

---

## 5. PHASED ROADMAP (each phase ends with a written checklist in `docs/phase_build.md`; do not advance until checked)

| Phase | Scope | Exit check |
|---|---|---|
| 0 | Repo scaffold, Godot project with Web + Android export presets (Web build with PWA/offline support enabled), doc system files created, lint/format config, security baseline (.env handling, no secrets in repo) | Web export succeeds and passes an offline-reload test (disable network, reload tab, game still loads); Android export succeeds locally |
| 1 | MatchEngine core loop for one format (T20), placeholder capsule/stick sprites, scoring + wickets + overs logic, written so it can also compile as a headless server target, zero network calls on the single-player path | A full T20 innings can be simulated headless and scorecard is correct; single-player runs with the device/network fully disabled |
| 2 | Pixel art pipeline decided (tile/sprite size, atlas rules), `docs/animations.md` full clip list authored, first right-handed batsman/bowler animation pair implemented | Visual playtest of one over with real sprites |
| 3 | Full animation matrix: left/right-hand × shot/delivery types, fielding set, umpire signals, crowd reactions | Each animation category has ≥1 working clip, verified in-engine |
| 4 | Menu system, match setup flow, custom fielding placement UI, scorecard/stats screens | End-to-end: menu → setup → play → scorecard, no crashes — verified on Android with airplane mode on, and in-browser after disabling network |
| 5 | Multiplayer: LAN/hotspot via ENet first (Android), then online via WebSocket + headless Godot server behind FastAPI auth/matchmaking | Two Android clients complete a match over LAN; then two complete one over the internet relay, including one browser client |
| 6 | Fully-offline local multiplayer: native Android Nearby Connections plugin bridge behind a Godot-side interface with an iOS-shaped extension point left open | Two Android devices complete a match with no network at all (hotspot/Wi-Fi/Bluetooth all off except device-to-device) |
| 7 | Real roster/team data integration (pending Ayman's data) | Data loads without code changes |
| 8 | Card/lootbox campaign meta system | Pack opening, card economy, campaign progression testable in isolation |
| 9 | Optimization + security + Play Store readiness pass: size/FPS budget on Android + browser, dependency/vuln scan, network hardening, Play Store submission checklist | Meets Section 1 performance budget on Web/Android; no critical vulnerabilities in scan; Play Store checklist complete |
| 10 (deferred) | Resume iOS: add export preset, native MultipeerConnectivity plugin behind the Phase 6 interface, macOS/CI build leg, App Store checklist | Not started until explicitly resumed |

---

## 6. DOCUMENTATION SYSTEM — CREATE THESE IN PHASE 0, EXACT FILENAMES

All under `docs/`. Each file is append-mostly; only `master_context.md` gets rewritten (as a snapshot).

- **`master_context.md`** — current phase, confirmed stack decisions, one-paragraph architecture snapshot, links to the other five files. This is the single file read first every session.
- **`progress.md`** — append-only running log: `[date] Phase X — what was completed`.
- **`daily_update.md`** — one entry per session: date, done, blocked-on, next-step.
- **`prompt_log.md`** — date-stamped copy of prompts given to the agent + one-line outcome, so a new session/account can see exactly what was asked and what happened.
- **`phase_build.md`** — per-phase checklist from Section 5 with checkboxes and verification notes.
- **`error.md`** — `[date] symptom → root cause → fix applied → how it was verified fixed`.

Every one of these files ends with a line pointing back to `master_context.md`.

---

## 7. ENGINEERING STANDARDS

- **Client code quality:** typed GDScript throughout, small single-responsibility scripts/scenes, no monolithic "God" scripts, consistent naming (documented in `master_context.md` once chosen), small focused commits with descriptive messages.
- **Backend code quality:** typed Python (type hints + mypy), Pydantic v2 models for all API schemas, async SQLAlchemy 2.0 (or SQLModel) with Alembic migrations, structured logging (structlog or equivalent) instead of print statements.
- **Testing:** headless unit tests for MatchEngine rules (scoring, overs, dismissals) — deterministic and testable without rendering, run against both client and headless-server builds; pytest + async test client for FastAPI endpoints.
- **CI/CD:** GitHub Actions (or equivalent) running lint + tests + Web and Android export targets on every push. No macOS/iOS job until Phase 10 is resumed.
- **Security:** no secrets committed (`.env`, documented required vars in `docs/master_context.md`), OAuth2/JWT auth on every backend endpoint before Phase 5 ships, validate/sanitize all networked input, avoid unsafe deserialization of any save/network payload, pin dependency versions and scan for known vulnerabilities (pip-audit, Dependabot) before Phase 9 sign-off.
- **Engine version pinning:** pin the exact Godot stable patch version (check godotengine.org/download for the current one — do not assume an old default) in CI config and in `docs/master_context.md`; never build against a moving "latest" tag.
- **Android signing:** CI may auto-generate a debug keystore for test builds at any time — it's non-secret and ephemeral. The release keystore is generated once, manually, only when Phase 9 (store-readiness) is reached; it is never auto-generated in CI, is stored as an encrypted CI secret plus a durable offline backup, and is never committed to the repo.
- **Performance discipline:** enforce the sprite-atlas and file-size budgets from Section 1 from Phase 2 onward, not retrofitted at the end; profile on a real low-end Android device, not just desktop.

---

## 8. OPEN-SOURCE ASSET POLICY

Prefer CC0/MIT/OGA-BY pixel-art packs (OpenGameArt, itch.io free assets) as placeholders and even final art where license permits. Track every reused asset's source + license in `docs/ASSETS.md` (create alongside the other docs). Do not commit anything without a compatible license.

---

## 9. FIRST TASK FOR THE AGENT RIGHT NOW

1. Scaffold the repo and Godot project with Web (PWA/offline support enabled) + Android export presets, and a CI pipeline covering both.
2. Create every file listed in Section 6 with the templates above, pre-filled with Sections 1–5 of this document as the initial `master_context.md` snapshot.
3. Complete Phase 0's checklist only.
4. Stop and report exactly what was verified, with the acceptance evidence (export logs, screenshots, CI run links), before touching Phase 1.
