extends Control

@onready var label_toss_result = $VBoxContainer/LabelResult
@onready var btn_flip = $VBoxContainer/BtnFlip
@onready var btn_proceed = $VBoxContainer/BtnProceed
@onready var format_options = $VBoxContainer/HBoxFormat/OptionButton

func _ready():
	btn_flip.pressed.connect(_on_flip_pressed)
	btn_proceed.pressed.connect(_on_proceed_pressed)
	btn_proceed.hide()
	
	format_options.add_item("T20 (20 Overs)")
	format_options.add_item("ODI (50 Overs)")
	format_options.add_item("Test (Unlimited)")

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
	
	btn_proceed.show()

func _on_proceed_pressed():
	if GameManager.is_player_batting_first:
		# If batting first, just go straight to match view, no field placement
		get_tree().change_scene_to_file("res://src/client/match_view.tscn")
	else:
		# If fielding first, go to field placement UI
		get_tree().change_scene_to_file("res://src/client/ui/field_placement_ui.tscn")
