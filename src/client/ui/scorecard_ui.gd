extends CanvasLayer

@onready var score_label = $Panel/ScoreLabel

func update_score(runs: int, wickets: int, overs_str: String):
	score_label.text = "Score: %d / %d\nOvers: %s" % [runs, wickets, overs_str]

func show_innings_complete(summary: String):
	score_label.text = "INNINGS COMPLETE\n" + summary
