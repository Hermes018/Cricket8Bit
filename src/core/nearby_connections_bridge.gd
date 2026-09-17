class_name NearbyConnectionsBridge
extends OfflineMultiplayerInterface
## GDScript bridge to the NearbyConnectionsPlugin Kotlin Android plugin.
## Falls back gracefully if the plugin is not available (e.g. running on desktop).

var _plugin: Object = null  # The native Android GodotPlugin instance
var _connected_peers: Array[String] = []

func _init():
	if Engine.has_singleton("NearbyConnections"):
		_plugin = Engine.get_singleton("NearbyConnections")
		_plugin.connect("peer_found", _on_peer_found)
		_plugin.connect("peer_lost", _on_peer_lost)
		_plugin.connect("connected_to_peer", _on_connected)
		_plugin.connect("disconnected_from_peer", _on_disconnected)
		_plugin.connect("packet_received", _on_packet)
		print("[NearbyBridge] Native plugin loaded.")
	else:
		push_warning("[NearbyBridge] NearbyConnections singleton not found. Is the plugin installed?")

func start_advertising(room_name: String) -> Error:
	if not _plugin:
		return ERR_UNAVAILABLE
	_plugin.requestPermissions()
	_plugin.startAdvertising(room_name)
	return OK

func start_discovery() -> Error:
	if not _plugin:
		return ERR_UNAVAILABLE
	_plugin.requestPermissions()
	_plugin.startDiscovery()
	return OK

func connect_to_endpoint(endpoint_id: String) -> Error:
	if not _plugin:
		return ERR_UNAVAILABLE
	_plugin.connectToEndpoint(endpoint_id)
	return OK

func send_packet(peer_id: String, payload: PackedByteArray) -> Error:
	if not _plugin:
		return ERR_UNAVAILABLE
	_plugin.sendPacket(peer_id, payload)
	return OK

func stop():
	if _plugin:
		_plugin.stopAll()
	_connected_peers.clear()

func is_connected_to_any() -> bool:
	return _connected_peers.size() > 0

func get_connected_peers() -> Array[String]:
	return _connected_peers

# --- Native signal handlers ---

func _on_peer_found(peer_id: String, endpoint_name: String):
	peer_found.emit(peer_id, endpoint_name)

func _on_peer_lost(peer_id: String):
	peer_lost.emit(peer_id)

func _on_connected(peer_id: String):
	if peer_id not in _connected_peers:
		_connected_peers.append(peer_id)
	connected_to_peer.emit(peer_id)

func _on_disconnected(peer_id: String):
	_connected_peers.erase(peer_id)
	disconnected_from_peer.emit(peer_id)

func _on_packet(peer_id: String, data):
	# data comes as a byte array from Kotlin
	var packed = data as PackedByteArray if data is PackedByteArray else PackedByteArray(data)
	packet_received.emit(peer_id, packed)
