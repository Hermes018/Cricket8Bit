extends Control

@onready var ip_input = $VBoxContainer/IpInput
@onready var btn_quick_match = $VBoxContainer/BtnQuickMatch
@onready var btn_host_lan = $VBoxContainer/BtnHostLAN
@onready var btn_join_lan = $VBoxContainer/BtnJoinLAN
@onready var btn_online = $VBoxContainer/BtnOnline
@onready var btn_nearby_host = $VBoxContainer/BtnNearbyHost
@onready var btn_nearby_search = $VBoxContainer/BtnNearbySearch
@onready var label_nearby_status = $VBoxContainer/LabelNearbyStatus

func _ready():
	btn_quick_match.pressed.connect(_on_quick_match)
	btn_host_lan.pressed.connect(_on_host_lan)
	btn_join_lan.pressed.connect(_on_join_lan)
	btn_online.pressed.connect(_on_online)
	btn_nearby_host.pressed.connect(_on_nearby_host)
	btn_nearby_search.pressed.connect(_on_nearby_search)

	NetworkManager.peer_connected.connect(_on_peer_connected)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)
	NetworkManager.offline_peer_found.connect(_on_offline_peer_found)
	NetworkManager.offline_connected.connect(_on_offline_connected)

func _on_quick_match():
	get_tree().change_scene_to_file("res://src/client/ui/match_setup.tscn")

func _on_host_lan():
	if NetworkManager.host_lan_game():
		btn_host_lan.text = "Hosting..."
		btn_host_lan.disabled = true
		btn_join_lan.disabled = true

func _on_join_lan():
	var ip = ip_input.text
	if ip == "": ip = "127.0.0.1"
	if NetworkManager.join_lan_game(ip):
		btn_join_lan.text = "Joining..."
		btn_host_lan.disabled = true
		btn_join_lan.disabled = true

func _on_online():
	print("Online matchmaking — connect to FastAPI backend (future work).")

func _on_nearby_host():
	var err = NetworkManager.start_offline_host("Cricket8Bit_Match")
	if err == OK:
		btn_nearby_host.text = "Advertising..."
		btn_nearby_host.disabled = true
		btn_nearby_search.disabled = true
		label_nearby_status.text = "Waiting for opponent..."
	else:
		label_nearby_status.text = "Failed to start (err %d)" % err

func _on_nearby_search():
	var err = NetworkManager.start_offline_search()
	if err == OK:
		btn_nearby_search.text = "Searching..."
		btn_nearby_host.disabled = true
		btn_nearby_search.disabled = true
		label_nearby_status.text = "Scanning for hosts..."
	else:
		label_nearby_status.text = "Failed to start (err %d)" % err

# --- Offline P2P signal handlers ---

func _on_offline_peer_found(peer_id: String, endpoint_name: String):
	label_nearby_status.text = "Found: %s" % endpoint_name
	# Auto-connect to the first found peer
	NetworkManager.connect_offline_peer(peer_id)
	label_nearby_status.text = "Connecting to %s..." % endpoint_name

func _on_offline_connected(peer_id: String):
	label_nearby_status.text = "Connected! Starting match..."
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://src/client/ui/match_setup.tscn")

# --- Standard multiplayer signal handlers ---

func _on_peer_connected(id):
	if multiplayer.is_server():
		get_tree().change_scene_to_file("res://src/client/ui/match_setup.tscn")

func _on_connected_to_server():
	get_tree().change_scene_to_file("res://src/client/ui/match_setup.tscn")
