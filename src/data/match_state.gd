class_name MatchState
extends Resource

@export var current_innings: int = 1
@export var runs: int = 0
@export var wickets: int = 0
@export var balls_bowled: int = 0
@export var total_overs: int = 0
@export var target_score: int = -1

# Simple representations for now
@export var current_striker: String = "Batsman 1"
@export var current_non_striker: String = "Batsman 2"
@export var current_bowler: String = "Bowler 1"

func add_runs(amount: int):
	runs += amount

func add_wicket():
	wickets += 1

func add_ball():
	balls_bowled += 1
	if balls_bowled == 6:
		balls_bowled = 0
		total_overs += 1

func swap_strike():
	var temp = current_striker
	current_striker = current_non_striker
	current_non_striker = temp

func get_overs_string() -> String:
	return str(total_overs) + "." + str(balls_bowled)
