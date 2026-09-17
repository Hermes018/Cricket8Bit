extends Node

var players: Dictionary = {}
var teams: Dictionary = {}

func _ready():
	_load_roster_data()

func _load_roster_data():
	var file_path = "res://src/data/db/roster.json"
	if not FileAccess.file_exists(file_path):
		push_error("Roster data not found at " + file_path)
		return
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error != OK:
		push_error("Failed to parse roster data: " + json.get_error_message())
		return
		
	var data = json.get_data()
	
	if data.has("players"):
		for p in data["players"]:
			players[p["id"]] = p
			
	if data.has("teams"):
		for t in data["teams"]:
			teams[t["id"]] = t
			
	print("[DataLoader] Loaded %d teams and %d players." % [teams.size(), players.size()])

func get_player(id: String) -> Dictionary:
	return players.get(id, {})

func get_team(id: String) -> Dictionary:
	return teams.get(id, {})

func get_all_teams() -> Array:
	return teams.values()
