extends Control

@onready var card_pivot = $CardPivot
@onready var card_back = $CardPivot/CardBack
@onready var card_front = $CardPivot/CardFront
@onready var lbl_rarity = $CardPivot/CardFront/LblRarity
@onready var lbl_name = $CardPivot/CardFront/LblName
@onready var particles = $CardPivot/CPUParticles2D
@onready var btn_continue = $BtnContinue

var card_data = {}

func _ready():
	btn_continue.pressed.connect(_on_continue_pressed)
	
	if EconomyManager.has_meta("last_pulled_card"):
		card_data = EconomyManager.get_meta("last_pulled_card")
		
	# Populate card details
	var player_id = card_data.get("player_id", "Unknown")
	var rarity = card_data.get("rarity", "Common")
	
	# Attempt to get real name from DataLoader if loaded
	var p_data = DataLoader.get_player(player_id)
	if p_data.has("name"):
		lbl_name.text = p_data["name"]
	else:
		lbl_name.text = player_id
		
	lbl_rarity.text = rarity
	
	if rarity == "Epic":
		card_front.color = Color(1, 0.84, 0)
		particles.color = Color(1, 0.84, 0)
	elif rarity == "Rare":
		card_front.color = Color(0.2, 0.5, 1)
		particles.color = Color(0.2, 0.5, 1)
	else:
		card_front.color = Color(0.8, 0.8, 0.8)
		particles.color = Color(1, 1, 1)
	
	_start_animation()

func _start_animation():
	card_pivot.scale = Vector2.ZERO
	
	# Scale up (suspense)
	var tween = create_tween()
	tween.tween_property(card_pivot, "scale", Vector2.ONE, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	
	# Shake
	tween.tween_method(_shake_card, -10.0, 10.0, 0.5)
	
	# Flip
	tween.tween_callback(_do_flip)
	
func _shake_card(val: float):
	card_pivot.rotation_degrees = randf_range(-val, val)
	
func _do_flip():
	card_pivot.rotation_degrees = 0
	
	var tween = create_tween()
	tween.tween_property(card_pivot, "scale:x", 0.0, 0.2)
	tween.tween_callback(func():
		card_back.hide()
		card_front.show()
		particles.emitting = true
	)
	tween.tween_property(card_pivot, "scale:x", 1.0, 0.2)
	tween.tween_callback(func():
		btn_continue.show()
	)

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://src/client/ui/campaign/store_ui.tscn")
