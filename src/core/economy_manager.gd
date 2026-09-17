extends Node

signal inventory_updated
signal pack_purchased(success: bool, result_data: Dictionary)
signal auth_completed

var auth_token: String = ""
var username: String = "TestUser" + str(randi() % 1000)
var virtual_currency: int = 0
var inventory: Array = []

var base_url = "http://127.0.0.1:8000"

var http_auth: HTTPRequest
var http_inv: HTTPRequest
var http_buy: HTTPRequest

func _ready():
	http_auth = HTTPRequest.new()
	add_child(http_auth)
	http_auth.request_completed.connect(_on_auth_completed)
	
	http_inv = HTTPRequest.new()
	add_child(http_inv)
	http_inv.request_completed.connect(_on_inv_completed)
	
	http_buy = HTTPRequest.new()
	add_child(http_buy)
	http_buy.request_completed.connect(_on_buy_completed)

func authenticate():
	var body = JSON.stringify({"username": username})
	var headers = ["Content-Type: application/json"]
	http_auth.request(base_url + "/token", headers, HTTPClient.METHOD_POST, body)

func _on_auth_completed(result, response_code, headers, body):
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data and data.has("access_token"):
			auth_token = data["access_token"]
			print("[EconomyManager] Authenticated successfully.")
			auth_completed.emit()
			fetch_inventory()
		else:
			print("Auth failed: Invalid response")
	else:
		print("Auth failed with code ", response_code)

func fetch_inventory():
	if auth_token == "": return
	var headers = ["Authorization: Bearer " + auth_token]
	http_inv.request(base_url + "/inventory", headers, HTTPClient.METHOD_GET)

func _on_inv_completed(result, response_code, headers, body):
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data:
			virtual_currency = data.get("balance", 0)
			inventory = data.get("cards", [])
			inventory_updated.emit()
			print("[EconomyManager] Inventory fetched. VC: ", virtual_currency, " Cards: ", inventory.size())

func buy_pack():
	if auth_token == "": return
	var headers = ["Authorization: Bearer " + auth_token, "Content-Length: 0"]
	http_buy.request(base_url + "/store/buy_pack", headers, HTTPClient.METHOD_POST)

func _on_buy_completed(result, response_code, headers, body):
	var data = null
	if body.size() > 0:
		data = JSON.parse_string(body.get_string_from_utf8())
		
	if response_code == 200 and data and data.get("success"):
		virtual_currency = data.get("balance", virtual_currency)
		var card = data.get("card", {})
		inventory.append(card)
		pack_purchased.emit(true, card)
	else:
		print("[EconomyManager] Pack purchase failed: ", response_code)
		pack_purchased.emit(false, {})
