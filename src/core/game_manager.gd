extends Node

var match_format: String = "T20" # "T20", "ODI", "Test"
var team_1: String = "India"
var team_2: String = "Australia"
var is_player_batting_first: bool = true
var field_placements: Array = []

func reset_match_state():
	field_placements = []
