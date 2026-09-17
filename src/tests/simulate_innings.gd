extends SceneTree

var engine: MatchEngine

func _init():
	print("Starting headless T20 innings simulation...")
	
	engine = MatchEngine.new()
	# Hook up signals
	engine.connect("match_started", _on_match_started)
	engine.connect("innings_started", _on_innings_started)
	engine.connect("over_started", _on_over_started)
	engine.connect("ball_bowled", _on_ball_bowled)
	engine.connect("runs_scored", _on_runs_scored)
	engine.connect("wicket_fallen", _on_wicket_fallen)
	engine.connect("over_complete", _on_over_complete)
	engine.connect("innings_complete", _on_innings_complete)
	
	# Start the match
	engine.start_match()

func _process(delta):
	if engine.current_state == MatchEngine.State.INNINGS_COMPLETE or engine.current_state == MatchEngine.State.MATCH_COMPLETE:
		print("Simulation complete. Exiting.")
		quit(0)
		return false
		
	if engine.current_state == MatchEngine.State.BALL_READY:
		engine.bowl_ball()
		
	return false

func _on_match_started():
	print("Match Started.")

func _on_innings_started(innings: int):
	print("Innings ", innings, " Started.")

func _on_over_started(over: int):
	pass # print("Over ", over, " Started.")

func _on_ball_bowled():
	pass

func _on_runs_scored(amount: int, is_extra: bool):
	pass # print("Scored ", amount, " runs.")

func _on_wicket_fallen(type: String):
	print("WICKET! (", type, ") Score: ", engine.state.runs, "/", engine.state.wickets)

func _on_over_complete(over: int):
	print("End of Over ", over, ". Score: ", engine.state.runs, "/", engine.state.wickets)

func _on_innings_complete(summary: String):
	print("==================================")
	print("INNINGS COMPLETE: ", summary)
	print("==================================")
