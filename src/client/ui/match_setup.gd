extends Control

@onready var label_toss_result = $VBoxContainer/LabelResult
@onready var btn_flip = $VBoxContainer/BtnFlip
@onready var btn_proceed = $VBoxContainer/BtnProceed
@onready var format_options = $VBoxContainer/HBoxFormat/OptionButton
@onready var team1_options = $VBoxContainer/HBoxTeam1/OptionButton
@onready var team2_options = $VBoxContainer/HBoxTeam2/OptionButton

var team_ids = []

func _ready():
	btn_flip.pressed.connect(_on_flip_pressed)
	btn_proceed.pressed.connect(_on_proceed_pressed)
	btn_proceed.hide()
	
	format_options.add_item("T20 (20 Overs)")
	format_options.add_item("ODI (50 Overs)")
	format_options.add_item("Test (Unlimited)")
	
	_populate_teams()

func _populate_teams():
	var teams = DataLoader.get_all_teams()
	for i in range(teams.size()):
		var t = teams[i]
		team_ids.append(t["id"])
		team1_options.add_item(t["team_name"], i)
		team2_options.add_item(t["team_name"], i)
		
	if teams.size() >= 2:
		team1_options.select(0)
		team2_options.select(1)

func _on_flip_pressed():
	btn_flip.disabled = true
	var rand = randf()
	if rand > 0.5:
		GameManager.is_player_batting_first = true
		label_toss_result.text = "You won the toss and elected to BAT!"
	else:
		GameManager.is_player_batting_first = false
		label_toss_result.text = "You lost the toss. The opponent elected to BAT!"
		
	var sel = format_options.get_selected_id()
	if sel == 0: GameManager.match_format = "T20"
	elif sel == 1: GameManager.match_format = "ODI"
	else: GameManager.match_format = "Test"
	
	if team_ids.size() > 0:
		GameManager.team_1 = team_ids[team1_options.get_selected_id()]
		GameManager.team_2 = team_ids[team2_options.get_selected_id()]
	
	btn_proceed.show()

func _on_proceed_pressed():
	if GameManager.is_player_batting_first:
		get_tree().change_scene_to_file("res://src/client/match_view.tscn")
	else:
		get_tree().change_scene_to_file("res://src/client/ui/field_placement_ui.tscn")
