class_name MatchEngine
extends Node

signal match_started
signal innings_started(innings: int)
signal over_started(over_number: int)
signal ball_bowled
signal runs_scored(amount: int, is_extra: bool)
signal wicket_fallen(type: String)
signal over_complete(over_number: int)
signal innings_complete(summary: String)
signal match_complete(result: String)

enum State {
	PRE_MATCH,
	TOSS,
	INNINGS_START,
	OVER_START,
	BALL_READY,
	BALL_IN_PLAY,
	BALL_RESOLVED,
	INNINGS_COMPLETE,
	MATCH_COMPLETE
}

var current_state: State = State.PRE_MATCH
var rules: MatchRules
var state: MatchState

func _init():
	rules = MatchRules.new()
	state = MatchState.new()

func start_match():
	current_state = State.TOSS
	# Simulate toss for now
	current_state = State.INNINGS_START
	emit_signal("match_started")
	start_innings()

func start_innings():
	current_state = State.OVER_START
	emit_signal("innings_started", state.current_innings)
	start_over()

func start_over():
	current_state = State.BALL_READY
	emit_signal("over_started", state.total_overs + 1)

func bowl_ball():
	if current_state != State.BALL_READY:
		return
	
	current_state = State.BALL_IN_PLAY
	emit_signal("ball_bowled")
	
	# In Phase 1 headless, we auto-resolve after a tiny delay or instantly.
	# We'll resolve instantly for headless simulation.
	call_deferred("resolve_ball")

func resolve_ball():
	if current_state != State.BALL_IN_PLAY:
		return
		
	var is_rigged = false
	var total_balls = state.total_overs * 6 + state.balls_bowled
	if total_balls == 0:
		# Ball 1: 6 runs
		state.add_runs(6)
		emit_signal("runs_scored", 6, false)
		is_rigged = true
	elif total_balls == 1:
		# Ball 2: Wicket (Caught)
		state.add_wicket()
		emit_signal("wicket_fallen", "caught")
		is_rigged = true
	elif total_balls == 2:
		# Ball 3: Dot ball
		emit_signal("runs_scored", 0, false)
		is_rigged = true
		
	if not is_rigged:
		# Phase 1: Pure RNG stat resolution
		var rand = randf()
		if rand < 0.05: # 5% chance of wicket
			state.add_wicket()
			emit_signal("wicket_fallen", "bowled")
		elif rand < 0.20: # 15% chance of dot ball
			emit_signal("runs_scored", 0, false)
		elif rand < 0.60: # 40% chance of 1 run
			state.add_runs(1)
			emit_signal("runs_scored", 1, false)
			state.swap_strike()
		elif rand < 0.80: # 20% chance of 2 runs
			state.add_runs(2)
			emit_signal("runs_scored", 2, false)
		elif rand < 0.90: # 10% chance of 4 runs
			state.add_runs(4)
			emit_signal("runs_scored", 4, false)
		else: # 10% chance of 6 runs
			state.add_runs(6)
			emit_signal("runs_scored", 6, false)
	
	state.add_ball()
	current_state = State.BALL_RESOLVED
	
	_check_state_transitions()

func _check_state_transitions():
	# Check if innings is over
	if state.wickets >= rules.wickets_per_innings or state.total_overs >= rules.max_overs or (state.target_score > 0 and state.runs >= state.target_score):
		current_state = State.INNINGS_COMPLETE
		emit_signal("innings_complete", "%d / %d in %s overs" % [state.runs, state.wickets, state.get_overs_string()])
		return
		
	# Check if over is complete
	if state.balls_bowled == 0: # reset to 0 by add_ball when reaching balls_per_over
		current_state = State.OVER_START
		state.swap_strike() # swap strike at end of over
		emit_signal("over_complete", state.total_overs)
		start_over()
	else:
		current_state = State.BALL_READY
