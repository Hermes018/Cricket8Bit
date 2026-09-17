extends Control

@onready var lbl_currency = $VBoxContainer/LblCurrency
@onready var btn_store = $VBoxContainer/BtnStore
@onready var btn_back = $VBoxContainer/BtnBack

func _ready():
	btn_store.pressed.connect(_on_store_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	EconomyManager.inventory_updated.connect(_update_currency)
	EconomyManager.auth_completed.connect(_on_auth)
	
	if EconomyManager.auth_token == "":
		lbl_currency.text = "Authenticating..."
		btn_store.disabled = true
		EconomyManager.authenticate()
	else:
		_update_currency()

func _on_auth():
	btn_store.disabled = false
	_update_currency()

func _update_currency():
	lbl_currency.text = "VC: " + str(EconomyManager.virtual_currency)

func _on_store_pressed():
	get_tree().change_scene_to_file("res://src/client/ui/campaign/store_ui.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://src/client/ui/main_menu.tscn")
