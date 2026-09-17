class_name MatchState
extends Resource

@export var current_innings: int = 1
@export var runs: int = 0
@export var wickets: int = 0
@export var balls_bowled: int = 0
@export var total_overs: int = 0
@export var target_score: int = -1

# Phase 7: Roster data tracking
@export var batting_team_id: String = ""
@export var fielding_team_id: String = ""
@export var batting_order: Array = [] # Array of player IDs
@export var fielding_order: Array = [] # Array of player IDs

@export var current_striker_idx: int = 0
@export var current_non_striker_idx: int = 1
@export var current_bowler_idx: int = 10 # Usually open with last player

func init_innings(bat_team: String, field_team: String):
	batting_team_id = bat_team
	fielding_team_id = field_team
	runs = 0
	wickets = 0
	balls_bowled = 0
	total_overs = 0
	current_striker_idx = 0
	current_non_striker_idx = 1
	current_bowler_idx = 10
	
	var bat_data = DataLoader.get_team(batting_team_id)
	var field_data = DataLoader.get_team(fielding_team_id)
	
	if bat_data.has("player_ids"): batting_order = bat_data["player_ids"]
	if field_data.has("player_ids"): fielding_order = field_data["player_ids"]

func get_current_striker() -> Dictionary:
	if current_striker_idx < batting_order.size():
		return DataLoader.get_player(batting_order[current_striker_idx])
	return {}
	
func get_current_bowler() -> Dictionary:
	if current_bowler_idx < fielding_order.size():
		return DataLoader.get_player(fielding_order[current_bowler_idx])
	return {}

func add_runs(amount: int):
	runs += amount

func add_wicket():
	wickets += 1
	# Next batsman comes in
	if wickets < batting_order.size() - 1:
		current_striker_idx = max(current_striker_idx, current_non_striker_idx) + 1

func add_ball():
	balls_bowled += 1
	if balls_bowled == 6:
		balls_bowled = 0
		total_overs += 1

func swap_strike():
	var temp = current_striker_idx
	current_striker_idx = current_non_striker_idx
	current_non_striker_idx = temp

func get_overs_string() -> String:
	return str(total_overs) + "." + str(balls_bowled)
