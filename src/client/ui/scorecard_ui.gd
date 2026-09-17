extends CanvasLayer

@onready var score_label = $Panel/ScoreLabel
@onready var overs_label = $Panel/OversLabel
@onready var batsman_label = $Panel/BatsmanLabel
@onready var bowler_label = $Panel/BowlerLabel
@onready var timeline = $Panel/TimelineContainer

func update_score(runs: int, wickets: int, overs_str: String):
	score_label.text = "%d / %d" % [runs, wickets]
	overs_label.text = "Overs: %s" % overs_str

func update_stats(striker_runs: int, striker_balls: int, non_striker_runs: int, non_striker_balls: int, bowler_runs: int, bowler_wkts: int, bowler_overs: String):
	batsman_label.text = "Striker: %d (%d)\nNon-Striker: %d (%d)" % [striker_runs, striker_balls, non_striker_runs, non_striker_balls]
	bowler_label.text = "Bowler: %d-%d (%s)" % [bowler_wkts, bowler_runs, bowler_overs]

func add_timeline_event(event: String):
	var lbl = Label.new()
	lbl.text = event
	lbl.add_theme_font_size_override("font_size", 18)
	if event == "W":
		lbl.add_theme_color_override("font_color", Color(1, 0, 0))
	elif event == "4" or event == "6":
		lbl.add_theme_color_override("font_color", Color(0, 1, 0))
	timeline.add_child(lbl)

func clear_timeline():
	for child in timeline.get_children():
		child.queue_free()
