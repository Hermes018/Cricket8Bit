extends Control

@onready var lbl_currency = $VBoxContainer/LblCurrency
@onready var btn_buy_pack = $VBoxContainer/BtnBuyPack
@onready var btn_back = $VBoxContainer/BtnBack
@onready var lbl_feedback = $VBoxContainer/LblFeedback

var is_purchasing = false

func _ready():
	btn_buy_pack.pressed.connect(_on_buy_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	EconomyManager.inventory_updated.connect(_update_currency)
	EconomyManager.pack_purchased.connect(_on_pack_purchased)
	_update_currency()

func _update_currency():
	lbl_currency.text = "VC: " + str(EconomyManager.virtual_currency)
	if EconomyManager.virtual_currency < 100:
		btn_buy_pack.disabled = true
	elif not is_purchasing:
		btn_buy_pack.disabled = false

func _on_buy_pressed():
	if EconomyManager.virtual_currency >= 100:
		is_purchasing = true
		btn_buy_pack.disabled = true
		lbl_feedback.text = "Purchasing..."
		EconomyManager.buy_pack()

func _on_pack_purchased(success: bool, result_data: Dictionary):
	is_purchasing = false
	if success:
		lbl_feedback.text = "Purchase successful!"
		# Pass the pulled card data to the next scene via global or a singleton
		# For simplicity we'll just set it on a property in the root if we had one, 
		# or store in EconomyManager.last_pulled_card
		
		# Let's add last_pulled_card to EconomyManager dynamically
		EconomyManager.set_meta("last_pulled_card", result_data)
		get_tree().change_scene_to_file("res://src/client/ui/campaign/pack_opening_ui.tscn")
	else:
		lbl_feedback.text = "Purchase failed."
		_update_currency()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://src/client/ui/campaign/campaign_menu.tscn")
