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

# Phase 5c: New signals for interactive delivery/batting
signal delivery_started(params: Dictionary)
signal awaiting_batting_input()

enum State {
	PRE_MATCH,
	TOSS,
	INNINGS_START,
	OVER_START,
	BALL_READY,
	BALL_IN_PLAY,       # Ball is physically in flight (client animating)
	AWAITING_SHOT,      # Ball arrived at crease, waiting for batsman input
	BALL_RESOLVED,
	INNINGS_COMPLETE,
	MATCH_COMPLETE
}

var current_state: State = State.PRE_MATCH
var rules: MatchRules
var state: MatchState

# Phase 5c: Current delivery parameters (set by bowling player)
var current_delivery_params: Dictionary = {}

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

## Phase 5c: The bowling player sets delivery parameters, then calls bowl_ball.
## params: { pace, pitch_x, pitch_length, swing, spin }
@rpc("any_peer", "call_local", "reliable")
func bowl_ball_with_params(params: Dictionary):
	if not multiplayer.is_server():
		return
	if current_state != State.BALL_READY:
		return

	current_delivery_params = params
	current_state = State.BALL_IN_PLAY
	emit_signal("ball_bowled")

	# Broadcast delivery to all clients so they can animate the ball
	rpc("client_start_delivery", params)

@rpc("authority", "call_local", "reliable")
func client_start_delivery(params: Dictionary):
	current_delivery_params = params
	current_state = State.BALL_IN_PLAY
	delivery_started.emit(params)

## Phase 5c: Called when ball arrives at crease — server waits for shot input.
func ball_arrived():
	if current_state != State.BALL_IN_PLAY:
		return
	current_state = State.AWAITING_SHOT
	awaiting_batting_input.emit()

## Phase 5c: The batting player submits their shot. Server resolves outcome.
@rpc("any_peer", "call_local", "reliable")
func submit_shot(shot_data: Dictionary):
	if not multiplayer.is_server():
		return
	if current_state != State.AWAITING_SHOT:
		return

	var outcome = InputRouter.resolve_shot(shot_data, current_delivery_params)
	rpc("client_sync_outcome", outcome.runs, outcome.is_extra, outcome.wicket_type)

@rpc("authority", "call_local", "reliable")
func client_sync_outcome(runs: int, is_extra: bool, wicket_type: String):
	if wicket_type != "":
		state.add_wicket()
		emit_signal("wicket_fallen", wicket_type)
	else:
		state.add_runs(runs)
		emit_signal("runs_scored", runs, is_extra)
		if runs % 2 != 0:
			state.swap_strike()

	state.add_ball()
	current_state = State.BALL_RESOLVED

	_check_state_transitions()

## Legacy fallback: simple RNG bowl (for AI opponent / offline quick-play).
@rpc("any_peer", "call_local", "reliable")
func bowl_ball():
	if not multiplayer.is_server():
		return
	if current_state != State.BALL_READY:
		return

	current_state = State.BALL_IN_PLAY
	emit_signal("ball_bowled")
	call_deferred("resolve_ball_rng")

func resolve_ball_rng():
	if current_state != State.BALL_IN_PLAY:
		return

	var rand = randf()
	var runs = 0
	var is_extra = false
	var wicket_type = ""

	if rand < 0.05:
		wicket_type = "bowled"
	elif rand < 0.20:
		runs = 0
	elif rand < 0.60:
		runs = 1
	elif rand < 0.80:
		runs = 2
	elif rand < 0.90:
		runs = 4
	else:
		runs = 6

	rpc("client_sync_outcome", runs, is_extra, wicket_type)

func _check_state_transitions():
	if state.wickets >= rules.wickets_per_innings or state.total_overs >= rules.max_overs or (state.target_score > 0 and state.runs >= state.target_score):
		current_state = State.INNINGS_COMPLETE
		emit_signal("innings_complete", "%d / %d in %s overs" % [state.runs, state.wickets, state.get_overs_string()])
		return

	if state.balls_bowled == 0:
		current_state = State.OVER_START
		state.swap_strike()
		emit_signal("over_complete", state.total_overs)
		start_over()
	else:
		current_state = State.BALL_READY
