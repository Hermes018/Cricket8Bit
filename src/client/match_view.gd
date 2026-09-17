extends Node2D

@onready var scorecard = $ScorecardUI
@onready var bowl_button = $BowlButton
@onready var animation_controller = $AnimationController

var engine: MatchEngine

func _ready():
	engine = MatchEngine.new()
	add_child(engine)
	
	engine.connect("innings_started", _on_innings_started)
	engine.connect("runs_scored", _on_runs_scored)
	engine.connect("wicket_fallen", _on_wicket_fallen)
	engine.connect("over_complete", _on_over_complete)
	engine.connect("innings_complete", _on_innings_complete)
	engine.connect("ball_bowled", _on_ball_bowled)
	
	bowl_button.pressed.connect(_on_bowl_button_pressed)
	
	engine.start_match()

func _on_bowl_button_pressed():
	if engine.current_state == MatchEngine.State.BALL_READY:
		bowl_button.disabled = true
		
		# 1. Play Bowler run-up client-side
		animation_controller.play_bowl_sequence()
		var bowler = animation_controller.bowler_sprite
		var orig_y = bowler.position.y
		var tween = create_tween()
		tween.tween_property(bowler, "position:y", orig_y + 100, 0.5)
		
		await tween.finished
		
		# 2. Bowler releases ball, stop animation, reset position
		animation_controller.stop_bowler()
		bowler.position.y = orig_y
		
		# 3. Trigger engine which instantly resolves and fires runs_scored/wicket
		engine.bowl_ball()
		
		await get_tree().create_timer(1.0).timeout
		bowl_button.disabled = false

func _on_ball_bowled():
	pass


func _update_ui():
	scorecard.update_score(engine.state.runs, engine.state.wickets, engine.state.get_overs_string())

func _on_innings_started(innings: int):
	_update_ui()

func _on_runs_scored(amount: int, is_extra: bool):
	print("Client: Scored ", amount)
	animation_controller.play_outcome(amount, "")
	_update_ui()
	
func _on_wicket_fallen(type: String):
	print("Client: WICKET ", type)
	animation_controller.play_outcome(0, type)
	_update_ui()

func _on_over_complete(over: int):
	print("Client: End of over")

func _on_innings_complete(summary: String):
	scorecard.show_innings_complete(summary)
	bowl_button.disabled = true

