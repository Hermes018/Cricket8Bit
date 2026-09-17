extends Node

var peer: MultiplayerPeer
const PORT = 7000
const MAX_CLIENTS = 2

signal peer_connected(id)
signal peer_disconnected(id)
signal connected_to_server()
signal connection_failed()
signal server_disconnected()

# --- Phase 6: Offline P2P provider ---
var offline_provider: OfflineMultiplayerInterface = null
signal offline_peer_found(peer_id: String, endpoint_name: String)
signal offline_connected(peer_id: String)
signal offline_disconnected(peer_id: String)
signal offline_packet(peer_id: String, data: PackedByteArray)

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	# Auto-detect offline P2P provider
	_init_offline_provider()

func _init_offline_provider():
	if OS.get_name() == "Android" and Engine.has_singleton("NearbyConnections"):
		offline_provider = NearbyConnectionsBridge.new()
		print("[NetworkManager] Using NearbyConnections native bridge")
	else:
		offline_provider = OfflineMultiplayerMock.new()
		print("[NetworkManager] Using OfflineMultiplayerMock (desktop/CI fallback)")

	# Wire signals from the provider to NetworkManager's public signals
	offline_provider.peer_found.connect(func(pid, name): offline_peer_found.emit(pid, name))
	offline_provider.connected_to_peer.connect(func(pid): offline_connected.emit(pid))
	offline_provider.disconnected_from_peer.connect(func(pid): offline_disconnected.emit(pid))
	offline_provider.packet_received.connect(func(pid, data): offline_packet.emit(pid, data))

# --- Offline P2P methods ---

func start_offline_host(room_name: String) -> Error:
	return offline_provider.start_advertising(room_name)

func start_offline_search() -> Error:
	return offline_provider.start_discovery()

func connect_offline_peer(endpoint_id: String) -> Error:
	return offline_provider.connect_to_endpoint(endpoint_id)

func send_offline_packet(peer_id: String, payload: PackedByteArray) -> Error:
	return offline_provider.send_packet(peer_id, payload)

func stop_offline():
	offline_provider.stop()

# --- LAN (ENet) methods ---

func host_lan_game():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Failed to host LAN: ", error)
		return false
	multiplayer.multiplayer_peer = peer
	print("LAN Host started on port ", PORT)
	return true

func join_lan_game(ip: String):
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	if error != OK:
		print("Failed to join LAN: ", error)
		return false
	multiplayer.multiplayer_peer = peer
	print("Joining LAN at ", ip)
	return true

# --- WebSocket (Online) methods ---

func host_websocket_game(port: int):
	peer = WebSocketMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error != OK:
		print("Failed to host WS: ", error)
		return false
	multiplayer.multiplayer_peer = peer
	print("WebSocket Host started on port ", port)
	return true

func join_websocket_game(ip: String, port: int):
	peer = WebSocketMultiplayerPeer.new()
	var url = "ws://" + ip + ":" + str(port)
	var error = peer.create_client(url)
	if error != OK:
		print("Failed to connect WS: ", error)
		return false
	multiplayer.multiplayer_peer = peer
	print("Connecting to WebSocket ", url)
	return true

# --- High-level Multiplayer API signal handlers ---

func _on_peer_connected(id):
	print("Peer Connected: ", id)
	peer_connected.emit(id)

func _on_peer_disconnected(id):
	print("Peer Disconnected: ", id)
	peer_disconnected.emit(id)

func _on_connected_to_server():
	print("Connected to Server successfully!")
	connected_to_server.emit()

func _on_connection_failed():
	print("Connection Failed!")
	connection_failed.emit()

func _on_server_disconnected():
	print("Server Disconnected!")
	server_disconnected.emit()
