extends SceneTree

func _init():
	var root = get_root()
	print("Starting Economy Test...")
	
	await create_timer(1.0).timeout
	var EconomyManager = root.get_node("EconomyManager")
	
	EconomyManager.authenticate()
	await EconomyManager.auth_completed
	print("Auth success! Token: ", EconomyManager.auth_token)
	
	await EconomyManager.inventory_updated
	print("Initial VC: ", EconomyManager.virtual_currency)
	print("Initial Inventory: ", EconomyManager.inventory)
	
	print("Buying pack...")
	EconomyManager.buy_pack()
	
	var res = await EconomyManager.pack_purchased
	print("Pack purchase success: ", res[0])
	print("Card Data: ", res[1])
	print("New VC: ", EconomyManager.virtual_currency)
	print("New Inventory: ", EconomyManager.inventory)
	
	quit(0)
