extends Control

@onready var ip_input = $VBoxContainer/IpInput
@onready var btn_host_lan = $VBoxContainer/BtnHostLAN
@onready var btn_join_lan = $VBoxContainer/BtnJoinLAN
@onready var btn_quick_match = $VBoxContainer/BtnQuickMatch
@onready var btn_online = $VBoxContainer/BtnOnline

func _ready():
	btn_quick_match.pressed.connect(_on_quick_match)
	btn_host_lan.pressed.connect(_on_host_lan)
	btn_join_lan.pressed.connect(_on_join_lan)
	btn_online.pressed.connect(_on_online)
	
	NetworkManager.peer_connected.connect(_on_peer_connected)
	NetworkManager.connected_to_server.connect(_on_connected_to_server)

func _on_quick_match():
	# Local offline play
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
	print("Online matchmaking not fully implemented on client yet (requires HTTP request to FastAPI).")

func _on_peer_connected(id):
	# If we are host, and a peer connects, let's start the match
	if multiplayer.is_server():
		print("Client joined! Starting MatchSetup...")
		get_tree().change_scene_to_file("res://src/client/ui/match_setup.tscn")

func _on_connected_to_server():
	print("Connected to host! Waiting for host to start match...")
	# For now, just switch to match setup, though host should probably dictate this
	get_tree().change_scene_to_file("res://src/client/ui/match_setup.tscn")
