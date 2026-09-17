extends Control

func _ready():
	$VBoxContainer/BtnQuickMatch.pressed.connect(_on_quick_match)
	$VBoxContainer/BtnSettings.pressed.connect(_on_settings)

func _on_quick_match():
	get_tree().change_scene_to_file("res://src/client/ui/match_setup.tscn")

func _on_settings():
	print("Settings not yet implemented")
