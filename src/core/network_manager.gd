extends Node

var peer: MultiplayerPeer
const PORT = 7000
const MAX_CLIENTS = 2

signal peer_connected(id)
signal peer_disconnected(id)
signal connected_to_server()
signal connection_failed()
signal server_disconnected()

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

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
