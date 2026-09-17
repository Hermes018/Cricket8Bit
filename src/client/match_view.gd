extends Node2D
## MatchView — Phase 5c: Interactive bowling/batting with 2.5D ball physics.
## Replaces the old "BOWL BALL" debug button with:
##   1. Pitch cursor placement (bowling player picks length/line)
##   2. Release meter (timing bar for speed/accuracy)
##   3. Ball flight via SimpleBallPhysics
##   4. Batting input via InputRouter (direction + timing window)

@onready var scorecard = $ScorecardUI
@onready var animation_controller = $AnimationController
@onready var pitch_rect_node: ColorRect = $Pitch
@onready var ball_physics: SimpleBallPhysics = $BallPhysics
@onready var input_router: InputRouter = $InputRouter

# Pitch Cursor (bowling target marker)
@onready var pitch_cursor: ColorRect = $PitchCursor
# Release Meter bar
@onready var release_meter_bg: ColorRect = $ReleaseMeterBG
@onready var release_meter_fill: ColorRect = $ReleaseMeterFill

var engine: MatchEngine

# --- Pitch Cursor state ---
var cursor_pitch_length: float = 0.5   # 0 = full, 0.5 = good length, 1.0 = short
var cursor_pitch_x: float = 0.5       # 0..1 lateral line
var is_placing_cursor: bool = false

# --- Release Meter state ---
enum MeterPhase { IDLE, RISING, FALLING, DONE }
var meter_phase: MeterPhase = MeterPhase.IDLE
var meter_value: float = 0.0          # 0..1, how full the meter bar is
var meter_speed: float = 1.8          # How fast the bar fills per second
var meter_result_pace: float = 0.0    # Computed pace from meter stop point

# --- Delivery flow state ---
enum DeliveryFlow { WAITING, PLACING_CURSOR, METER_ACTIVE, BALL_IN_FLIGHT, BATTING_INPUT, RESOLVING }
var flow_state: DeliveryFlow = DeliveryFlow.WAITING

func _ready():
	engine = MatchEngine.new()
	add_child(engine)

	# Apply GameManager configuration
	if GameManager.match_format == "T20":
		engine.rules.max_overs = 20
	elif GameManager.match_format == "ODI":
		engine.rules.max_overs = 50
	else:
		engine.rules.max_overs = 999

	# Engine signals
	engine.connect("innings_started", _on_innings_started)
	engine.connect("runs_scored", _on_runs_scored)
	engine.connect("wicket_fallen", _on_wicket_fallen)
	engine.connect("over_complete", _on_over_complete)
	engine.connect("innings_complete", _on_innings_complete)
	engine.connect("ball_bowled", _on_ball_bowled)
	engine.connect("delivery_started", _on_delivery_started)
	engine.connect("awaiting_batting_input", _on_awaiting_batting_input)

	# Ball physics signals
	ball_physics.ball_bounced.connect(_on_ball_bounced)
	ball_physics.ball_arrived_at_crease.connect(_on_ball_arrived_at_crease)

	# Input router signals
	input_router.shot_played.connect(_on_shot_played)

	# Initial UI state
	pitch_cursor.visible = false
	release_meter_bg.visible = false
	release_meter_fill.visible = false

	engine.start_match()

	# After engine starts, open cursor placement for first ball
	await get_tree().create_timer(0.3).timeout
	_begin_delivery_flow()


func _begin_delivery_flow():
	if engine.current_state != MatchEngine.State.BALL_READY:
		return
	flow_state = DeliveryFlow.PLACING_CURSOR
	is_placing_cursor = true
	pitch_cursor.visible = true
	_update_cursor_visual()


func _process(delta: float):
	# --- Pitch cursor movement ---
	if flow_state == DeliveryFlow.PLACING_CURSOR:
		var moved = false
		if Input.is_action_pressed("ui_up"):
			cursor_pitch_length = clampf(cursor_pitch_length - delta * 0.8, 0.0, 1.0)
			moved = true
		if Input.is_action_pressed("ui_down"):
			cursor_pitch_length = clampf(cursor_pitch_length + delta * 0.8, 0.0, 1.0)
			moved = true
		if Input.is_action_pressed("ui_left"):
			cursor_pitch_x = clampf(cursor_pitch_x - delta * 0.8, 0.0, 1.0)
			moved = true
		if Input.is_action_pressed("ui_right"):
			cursor_pitch_x = clampf(cursor_pitch_x + delta * 0.8, 0.0, 1.0)
			moved = true
		if moved:
			_update_cursor_visual()

	# --- Release meter animation ---
	if flow_state == DeliveryFlow.METER_ACTIVE:
		if meter_phase == MeterPhase.RISING:
			meter_value += delta * meter_speed
			if meter_value >= 1.0:
				meter_value = 1.0
				meter_phase = MeterPhase.FALLING
		elif meter_phase == MeterPhase.FALLING:
			meter_value -= delta * meter_speed * 0.8
			if meter_value <= 0.0:
				meter_value = 0.0
				meter_phase = MeterPhase.RISING
		_update_meter_visual()


func _unhandled_input(event: InputEvent):
	# Confirm cursor placement → start release meter
	if flow_state == DeliveryFlow.PLACING_CURSOR:
		if event.is_action_pressed("ui_accept") or (event is InputEventScreenTouch and event.pressed):
			_start_release_meter()
			get_viewport().set_input_as_handled()
			return

	# Stop release meter → fire delivery
	if flow_state == DeliveryFlow.METER_ACTIVE:
		if event.is_action_pressed("ui_accept") or (event is InputEventScreenTouch and event.pressed):
			_stop_release_meter()
			get_viewport().set_input_as_handled()
			return


func _update_cursor_visual():
	# Place cursor on the pitch rect based on cursor_pitch_length and cursor_pitch_x
	var pitch_rect = _get_pitch_screen_rect()
	var cx = pitch_rect.position.x + cursor_pitch_x * pitch_rect.size.x
	var cy = pitch_rect.position.y + (0.3 + cursor_pitch_length * 0.5) * pitch_rect.size.y
	pitch_cursor.position = Vector2(cx - 8, cy - 8)


func _start_release_meter():
	flow_state = DeliveryFlow.METER_ACTIVE
	is_placing_cursor = false
	pitch_cursor.visible = false  # Lock cursor position

	meter_phase = MeterPhase.RISING
	meter_value = 0.0
	release_meter_bg.visible = true
	release_meter_fill.visible = true
	_update_meter_visual()


func _stop_release_meter():
	meter_phase = MeterPhase.DONE
	release_meter_bg.visible = false
	release_meter_fill.visible = false

	# Compute pace from where meter stopped. Sweet spot is 0.75–0.9 range.
	meter_result_pace = clampf(meter_value, 0.3, 1.0)

	# Determine if no-ball (overstep): if meter was > 0.95 or < 0.15, it's a fault
	var is_no_ball = meter_value > 0.95 or meter_value < 0.1

	flow_state = DeliveryFlow.BALL_IN_FLIGHT

	# Build delivery params
	var params = {
		"pace": meter_result_pace,
		"pitch_x": cursor_pitch_x,
		"pitch_length": cursor_pitch_length,
		"swing": randf_range(-0.3, 0.3),   # Slight random swing for now
		"spin": randf_range(-0.2, 0.2),
		"is_no_ball": is_no_ball,
	}

	# Play bowler run-up animation
	var bowler_data = engine.state.get_current_bowler()
	var is_left_arm = bowler_data.get("bat_hand", "R") == "L"
	animation_controller.play_bowl_sequence(is_left_arm)
	var bowler = animation_controller.bowler_sprite
	var orig_y = bowler.position.y
	var tween = create_tween()
	tween.tween_property(bowler, "position:y", orig_y + 100, 0.4)
	await tween.finished
	animation_controller.stop_bowler()
	bowler.position.y = orig_y

	# Fire the ball through engine → physics
	engine.bowl_ball_with_params(params)


func _update_meter_visual():
	# The fill bar height is proportional to meter_value
	var max_height = release_meter_bg.size.y
	release_meter_fill.size.y = max_height * meter_value
	release_meter_fill.position.y = release_meter_bg.position.y + max_height - release_meter_fill.size.y

	# Color feedback: green in sweet spot, red at extremes
	if meter_value >= 0.7 and meter_value <= 0.9:
		release_meter_fill.color = Color(0.1, 0.9, 0.2)
	elif meter_value >= 0.5:
		release_meter_fill.color = Color(0.9, 0.8, 0.1)
	else:
		release_meter_fill.color = Color(0.9, 0.2, 0.1)


func _get_pitch_screen_rect() -> Rect2:
	return Rect2(pitch_rect_node.position, pitch_rect_node.size)


# --- Engine signal handlers ---

func _on_ball_bowled():
	pass

func _on_delivery_started(params: Dictionary):
	# Start the 2.5D ball flight
	var pitch_rect = _get_pitch_screen_rect()
	var release_pos = Vector2(pitch_rect.position.x + pitch_rect.size.x * 0.5, pitch_rect.position.y + 60)
	var crease_pos = Vector2(pitch_rect.position.x + pitch_rect.size.x * 0.5, pitch_rect.position.y + 420)
	ball_physics.start_delivery(params, release_pos, crease_pos, pitch_rect)


func _on_ball_bounced(bounce_pos: Vector2):
	# Visual feedback: small flash or dust effect at bounce point (placeholder)
	pass


func _on_ball_arrived_at_crease(arrival_data: Dictionary):
	# Ball has reached the batsman — tell engine, open batting input window
	engine.ball_arrived()


func _on_awaiting_batting_input():
	flow_state = DeliveryFlow.BATTING_INPUT
	# Open the timing window in the input router
	# Use engine time + a short reaction buffer
	input_router.open_timing_window(Time.get_ticks_msec() / 1000.0)

	# Auto-miss timeout: if player doesn't swing within 0.5s, it's a leave/miss
	await get_tree().create_timer(0.5).timeout
	if flow_state == DeliveryFlow.BATTING_INPUT and not input_router.has_swung:
		# Player didn't swing — treat as a leave (dot ball or bowled if on stumps)
		var auto_shot = {
			"direction": InputRouter.ShotDirection.STRAIGHT,
			"type": InputRouter.ShotType.DEFENSIVE,
			"quality": "miss",
			"timing_side": "late",
			"delta_t": 0.5,
		}
		_on_shot_played(auto_shot)


func _on_shot_played(shot_data: Dictionary):
	if flow_state != DeliveryFlow.BATTING_INPUT:
		return
	flow_state = DeliveryFlow.RESOLVING
	input_router.close_timing_window()
	ball_physics.hide_ball()

	# Submit shot to engine for authoritative resolution
	engine.submit_shot(shot_data)

	# Wait for outcome signals, then re-enable next delivery
	await get_tree().create_timer(1.5).timeout
	if engine.current_state != MatchEngine.State.INNINGS_COMPLETE:
		_begin_delivery_flow()


func _update_ui():
	scorecard.update_score(engine.state.runs, engine.state.wickets, engine.state.get_overs_string())
	var striker = engine.state.get_current_striker()
	var bowler = engine.state.get_current_bowler()
	scorecard.update_stats(
		striker.get("name", "Batsman"), engine.state.runs, engine.state.balls_bowled,
		"Non-Striker", 0, 0,
		bowler.get("name", "Bowler"), engine.state.runs, engine.state.wickets, engine.state.get_overs_string()
	)


func _on_innings_started(innings: int):
	_update_ui()
	scorecard.clear_timeline()

func _on_runs_scored(amount: int, is_extra: bool):
	print("Client: Scored ", amount)
	var striker_data = engine.state.get_current_striker()
	var is_left_handed = striker_data.get("bat_hand", "R") == "L"
	animation_controller.play_outcome(amount, "", is_left_handed)
	scorecard.add_timeline_event(str(amount))
	_update_ui()

func _on_wicket_fallen(type: String):
	print("Client: WICKET ", type)
	var striker_data = engine.state.get_current_striker()
	var is_left_handed = striker_data.get("bat_hand", "R") == "L"
	animation_controller.play_outcome(0, type, is_left_handed)
	scorecard.add_timeline_event("W")
	_update_ui()

func _on_over_complete(over: int):
	print("Client: End of over")
	scorecard.clear_timeline()

func _on_innings_complete(summary: String):
	print("INNINGS COMPLETE: ", summary)
	ball_physics.hide_ball()
	flow_state = DeliveryFlow.WAITING
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://src/client/ui/main_menu.tscn")
