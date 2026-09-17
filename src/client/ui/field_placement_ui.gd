extends Control

@onready var radar = $Radar
@onready var btn_proceed = $BtnProceed

func _ready():
	btn_proceed.pressed.connect(_on_proceed_pressed)
	# Setup 9 outfielders dynamically
	for i in range(9):
		var fielder = TextureRect.new()
		fielder.texture = load("res://icon.png") # Placeholder icon for fielder dot
		fielder.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fielder.size = Vector2(24, 24)
		fielder.position = Vector2(100 + randi() % 200, 100 + randi() % 200)
		fielder.set_script(load("res://src/client/ui/draggable_fielder.gd"))
		radar.add_child(fielder)

func _on_proceed_pressed():
	# Save positions to GameManager
	GameManager.field_placements.clear()
	for child in radar.get_children():
		if child is TextureRect: # Fielder
			GameManager.field_placements.append(child.position)
	get_tree().change_scene_to_file("res://src/client/match_view.tscn")
