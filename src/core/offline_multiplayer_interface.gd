class_name OfflineMultiplayerInterface
extends RefCounted
## Abstract contract for zero-network peer-to-peer multiplayer.
## Implementations: OfflineMultiplayerMock (desktop/CI), NearbyConnectionsBridge (Android).
## Phase 10 will add MultipeerConnectivityBridge (iOS) with zero call-site changes.

# --- Signals ---
# Emitted when a peer is discovered (advertising endpoint found by discoverer).
signal peer_found(peer_id: String, endpoint_name: String)
# Emitted when a previously discovered peer is no longer reachable.
signal peer_lost(peer_id: String)
# Emitted when a bidirectional connection to a peer is established.
signal connected_to_peer(peer_id: String)
# Emitted when a connected peer disconnects.
signal disconnected_from_peer(peer_id: String)
# Emitted when a raw byte payload is received from a connected peer.
signal packet_received(peer_id: String, data: PackedByteArray)

# --- Virtual methods (override in concrete implementations) ---

## Begin advertising this device as a host under `room_name`.
## Other devices running start_discovery() will see this endpoint.
func start_advertising(_room_name: String) -> Error:
	push_error("OfflineMultiplayerInterface.start_advertising() not implemented")
	return ERR_METHOD_NOT_FOUND

## Begin scanning for advertised endpoints.
func start_discovery() -> Error:
	push_error("OfflineMultiplayerInterface.start_discovery() not implemented")
	return ERR_METHOD_NOT_FOUND

## Request a connection to a discovered endpoint.
func connect_to_endpoint(_endpoint_id: String) -> Error:
	push_error("OfflineMultiplayerInterface.connect_to_endpoint() not implemented")
	return ERR_METHOD_NOT_FOUND

## Send a raw byte payload to a connected peer.
func send_packet(_peer_id: String, _payload: PackedByteArray) -> Error:
	push_error("OfflineMultiplayerInterface.send_packet() not implemented")
	return ERR_METHOD_NOT_FOUND

## Tear down all advertising, discovery, and connections.
func stop():
	push_error("OfflineMultiplayerInterface.stop() not implemented")

## Returns true if this provider is currently connected to at least one peer.
func is_connected_to_any() -> bool:
	return false

## Returns array of connected peer IDs.
func get_connected_peers() -> Array[String]:
	return []
