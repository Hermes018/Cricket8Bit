class_name OfflineMultiplayerMock
extends OfflineMultiplayerInterface
## Loopback / local simulation for desktop editor, headless CI, and unit tests.
## Simulates peer discovery, connection handshake, and raw byte transfers
## without any network sockets or hardware.

# --- Internal state ---
var _is_advertising: bool = false
var _is_discovering: bool = false
var _room_name: String = ""
var _connected_peers: Array[String] = []
var _local_id: String = ""

# Static registry: all active mock instances share this so two instances
# in the same process can "find" each other (for dual-window testing).
static var _registry: Dictionary = {}  # id -> OfflineMultiplayerMock

func _init():
	_local_id = "mock_%d" % randi()

func start_advertising(room_name: String) -> Error:
	_room_name = room_name
	_is_advertising = true
	_registry[_local_id] = self
	print("[MockP2P] Advertising as '%s' (id: %s)" % [room_name, _local_id])
	return OK

func start_discovery() -> Error:
	_is_discovering = true
	print("[MockP2P] Discovery started (id: %s)" % _local_id)

	# Scan the registry for advertisers
	for peer_id in _registry:
		if peer_id == _local_id:
			continue
		var other: OfflineMultiplayerMock = _registry[peer_id]
		if other._is_advertising:
			print("[MockP2P] Found peer: %s ('%s')" % [peer_id, other._room_name])
			peer_found.emit(peer_id, other._room_name)
	return OK

func connect_to_endpoint(endpoint_id: String) -> Error:
	if endpoint_id not in _registry:
		push_warning("[MockP2P] Endpoint %s not found in registry" % endpoint_id)
		return ERR_DOES_NOT_EXIST

	var other: OfflineMultiplayerMock = _registry[endpoint_id]

	# Simulate bidirectional connection
	_connected_peers.append(endpoint_id)
	other._connected_peers.append(_local_id)

	print("[MockP2P] Connected: %s <-> %s" % [_local_id, endpoint_id])
	connected_to_peer.emit(endpoint_id)
	other.connected_to_peer.emit(_local_id)
	return OK

func send_packet(peer_id: String, payload: PackedByteArray) -> Error:
	if peer_id not in _connected_peers:
		return ERR_CONNECTION_ERROR
	if peer_id not in _registry:
		return ERR_DOES_NOT_EXIST

	var other: OfflineMultiplayerMock = _registry[peer_id]
	# Deliver asynchronously via call_deferred to simulate real latency
	other.packet_received.emit(_local_id, payload)
	return OK

func stop():
	# Notify connected peers of disconnect
	for pid in _connected_peers:
		if pid in _registry:
			var other: OfflineMultiplayerMock = _registry[pid]
			other._connected_peers.erase(_local_id)
			other.disconnected_from_peer.emit(_local_id)

	_connected_peers.clear()
	_is_advertising = false
	_is_discovering = false
	_registry.erase(_local_id)
	print("[MockP2P] Stopped (id: %s)" % _local_id)

func is_connected_to_any() -> bool:
	return _connected_peers.size() > 0

func get_connected_peers() -> Array[String]:
	return _connected_peers

## --- Test helpers ---

## Simulate discovering a fake peer (for unit tests without a second instance).
func inject_fake_peer(fake_id: String, fake_name: String):
	peer_found.emit(fake_id, fake_name)

## Simulate receiving a packet from a fake peer.
func inject_fake_packet(fake_id: String, data: PackedByteArray):
	packet_received.emit(fake_id, data)
