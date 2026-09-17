# Cricket8Bit — Master Context

## 1. PROJECT IDENTITY
- **Name:** Cricket8Bit
- **Pitch:** A fast, offline-first, 8-bit cricket game with real cricket mechanics (batting, bowling, fielding, full match formats) that runs equally well in a browser tab and on a low-end Android phone — one codebase, two storefronts today, iOS added later without a rewrite.
- **Visual bar:** Nokia Cricket (2004) as the floor; Pokémon Black/White or BOTW-DS-era sprite work as the target ceiling. Readable silhouettes over detail; small sprite sheets over large ones.
- **Performance budget:** APK ≤ 60MB core; 60fps on a 3-year-old low-end Android device; browser build playable on a mid-range laptop with no dedicated GPU, and on a mid-range phone browser.
- **Offline-first requirement (hard constraint):** single-player vs. CPU, in every match format, must work with zero network access — no login wall, no "phone home" on launch, no asset fetched at runtime. Android: true by default once the APK is installed (all assets bundled at build time). Browser: the HTML5 export must ship with PWA/service-worker support enabled so the game is playable offline after the first visit. Multiplayer is the only mode allowed to require connectivity.
- **iOS, deferred:** no iOS work, testing, or CI happens in the current phase set. Godot's native multi-export model means resuming it later is adding an export preset and a macOS/CI build leg, not restructuring the engine or rewriting game logic — this is why the engine choice below still holds even with iOS off the table now.
- **Non-negotiables:** modular code, data-driven content (players/teams/tournaments as data, not hardcoded), security-conscious networking, verifiable phases, no duplicated game-logic between platforms.

## 2. TECH STACK
- **Client/game engine:** Godot 4.7.1 (stable), typed GDScript. Native HTML5/WASM export (PWA/offline support) and Android APK.
- **Backend/netcode:** FastAPI for services, PostgreSQL + Redis. Authoritative match server = Godot headless dedicated-server build.
- **Networking transport:** `WebSocketMultiplayerPeer` for online/cross-platform. `ENetMultiplayerPeer` for LAN (native builds). Fully offline local multiplayer via Android Nearby Connections API. 
- **Assumption:** Godot 4.7.1 (client + headless server) in GDScript, FastAPI/Postgres/Redis for services, WebSocket for online, ENet for LAN, a native Android Nearby Connections plugin for fully-offline local play.

## 3. ARCHITECTURE OVERVIEW
- **Client (Godot):** Menu, TeamSelect, MatchSetup, FieldPlacement, Innings (core sim + rendering), Scorecard, Settings, Multiplayer Lobby.
- **Shared core:** MatchEngine, AI, rules data loader. Must never be duplicated in another language.
- **Client-only systems:** AnimationController, SimpleBallPhysics, InputRouter, NetSync.
- **Data layer:** Players/teams/tournaments/match-format-rules as JSON/Godot `Resource` files.
- **Backend (Phase 5+):** FastAPI for auth/matchmaking/leaderboards/card economy; headless Godot server(s).

## 4. FEATURE CATALOG
- **Match formats:** Test, ODI, T20, T10. Data-driven rules.
- **Teams/tournaments:** Countries + tournament templates.
- **Batting animations:** Extensive left/right mirrored set.
- **Bowling animations:** Pace and Spin (mirrored), run-up, release, follow-through.
- **Fielding animations:** Catches, stops, run-outs, umpires.
- **Atmosphere:** Crowd, umpires, wickets, walk-outs, celebrations.
- **Multiplayer:** LAN/hotspot (ENet, Phase 5), online relay (WebSocket, Phase 5b), fully-offline local P2P (Nearby Connections, Phase 6).
- **Meta progression:** Card lootbox campaign mode (Phase 8+).
- **Custom fielding placement:** Drag-and-drop UI.

## 5. PHASED ROADMAP
- Phase 0: Repo scaffold, Godot project, CI, docs.
- Phase 1: MatchEngine core loop (T20).
- Phase 2: Pixel art pipeline, `docs/animations.md`.
- Phase 3: Full animation matrix.
- Phase 4: Menu system, match setup, screens.
- Phase 5: Multiplayer (LAN/ENet -> Online/WebSocket).
- Phase 6: Fully-offline local P2P.
- Phase 7: Real roster data.
- Phase 8: Card/lootbox campaign.
- Phase 9: Optimization, security, Play Store readiness.
- Phase 10: iOS (Deferred).

---
See `docs/master_context.md` for this snapshot.

### Architecture Update Phase 5 (Multiplayer) 
We use a Strict Dual-Transport protocol:
- **Local LAN / Android Hotspot**: Uses `ENetMultiplayerPeer` for low-overhead offline mobile play.
- **Global Matchmaking**: Connects via a Python FastAPI backend acting as a JWT broker and queue. Clients use `WebSocketMultiplayerPeer` exclusively to connect to Godot Headless dedicated servers. 
- **Authority**: The `MatchEngine` runs deterministically on the server. Outcomes are synchronized to clients strictly via `@rpc('authority')` calls, preventing any client-side divergence.

### Architecture Update Phase 6 (Offline P2P) 
We use a platform-agnostic `OfflineMultiplayerInterface` abstraction:
- **Android**: `NearbyConnectionsBridge` wraps a Kotlin plugin that calls `Nearby.getConnectionsClient()` with `Strategy.P2P_STAR`. Uses BLE for discovery and Wi-Fi Direct for high-bandwidth data � works in full airplane mode with local radios.
- **Desktop/CI**: `OfflineMultiplayerMock` provides a static-registry loopback so two instances in the same process can discover, connect, and exchange packets without any hardware.
- **iOS (Phase 10 deferred)**: Will add `MultipeerConnectivityBridge` conforming to the same interface � zero call-site changes required.
- `NetworkManager` auto-selects the provider at startup based on `OS.get_name()` and `Engine.has_singleton()`.
- Serialization: game state packets use Godot's `var_to_bytes()`/`bytes_to_var()` for cross-platform safety.

### Architecture Update Phase 8 (Card/Lootbox Campaign) 
We use a persistent SQLite database driven by FastAPI and SQLModel. 
- **Backend Models**: `User` (username, virtual_currency_balance), `CardTemplate` (player_id, rarity_tier), and `UserInventory` (junction table).
- **Endpoints**: `GET /inventory` and `POST /store/buy_pack`.
- **Lootbox RNG**: Weighted logic resolves pack drops on the backend (70% Common, 25% Rare, 5% Epic) to prevent client spoofing.
- **Godot Client**: `EconomyManager` Autoload handles JWT authentication and HTTP request state. UI layers (`CampaignMenu`, `StoreUI`, `PackOpeningUI`) respond to custom signals (`auth_completed`, `inventory_updated`, `pack_purchased`) to decouple rendering from netcode.
