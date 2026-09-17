extends Node2D

@onready var scorecard = $ScorecardUI
@onready var bowl_button = $BowlButton
@onready var batsman = $Pitch/Batsman
@onready var bowler = $Pitch/Bowler

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

func _process(delta):
	if engine.current_state == MatchEngine.State.BALL_READY and !bowl_button.disabled:
		# Auto-bowl logic could go here, but we wait for user input
		pass

func _on_bowl_button_pressed():
	if engine.current_state == MatchEngine.State.BALL_READY:
		engine.bowl_ball()
		
		# In a real game with animation, we would wait for animation to finish.
		# Since Phase 1 uses instant resolution, we just quickly animate the bowler for visual feedback.
		var tween = create_tween()
		var orig_y = bowler.position.y
		tween.tween_property(bowler, "position:y", orig_y + 50, 0.1)
		tween.tween_property(bowler, "position:y", orig_y, 0.1)
		
		# Resolve the ball after the visual delay (to simulate the client waiting for the server/engine)
		await get_tree().create_timer(0.2).timeout
		engine.resolve_ball()
		_update_ui()

func _update_ui():
	scorecard.update_score(engine.state.runs, engine.state.wickets, engine.state.get_overs_string())

func _on_innings_started(innings: int):
	_update_ui()

func _on_runs_scored(amount: int, is_extra: bool):
	print("Client: Scored ", amount)
	
func _on_wicket_fallen(type: String):
	print("Client: WICKET")

func _on_over_complete(over: int):
	print("Client: End of over")

func _on_innings_complete(summary: String):
	scorecard.show_innings_complete(summary)
	bowl_button.disabled = true

func _on_ball_bowled():
	pass
