class_name InputRouter
extends Node
## Captures player batting input (direction + shot type) and evaluates
## timing quality against the ball arrival window.

signal shot_played(shot_data: Dictionary)

# --- Shot directions ---
enum ShotDirection { OFF_SIDE, STRAIGHT, LEG_SIDE }
# --- Shot modifiers ---
enum ShotType { DEFENSIVE, GROUND_STROKE, LOFTED }

# --- Timing ---
var timing_window_open: bool = false
var window_center_time: float = 0.0  # Engine time when ball arrives at crease
var window_half_width: float = 0.12  # +/- seconds for "good" timing
var perfect_half_width: float = 0.04 # +/- seconds for "perfect" timing

# --- Current input state ---
var chosen_direction: ShotDirection = ShotDirection.STRAIGHT
var chosen_type: ShotType = ShotType.GROUND_STROKE
var has_swung: bool = false

## Called by MatchView when ball is released to open the timing window.
func open_timing_window(arrival_time: float):
	window_center_time = arrival_time
	timing_window_open = true
	has_swung = false
	chosen_direction = ShotDirection.STRAIGHT
	chosen_type = ShotType.GROUND_STROKE

func close_timing_window():
	timing_window_open = false

func _unhandled_input(event: InputEvent):
	if not timing_window_open or has_swung:
		return

	# Direction: Arrow keys or swipe
	if event.is_action_pressed("ui_left"):
		chosen_direction = ShotDirection.LEG_SIDE
	elif event.is_action_pressed("ui_right"):
		chosen_direction = ShotDirection.OFF_SIDE
	elif event.is_action_pressed("ui_up"):
		chosen_type = ShotType.LOFTED
	elif event.is_action_pressed("ui_down"):
		chosen_type = ShotType.DEFENSIVE

	# Swing trigger: Space bar or screen tap
	if event.is_action_pressed("ui_accept") or (event is InputEventScreenTouch and event.pressed):
		_execute_swing()

func _execute_swing():
	has_swung = true
	timing_window_open = false

	var now = Time.get_ticks_msec() / 1000.0
	var delta_t = now - window_center_time
	var abs_delta = absf(delta_t)

	var quality: String
	if abs_delta <= perfect_half_width:
		quality = "perfect"
	elif abs_delta <= window_half_width:
		quality = "good"
	elif abs_delta <= window_half_width * 2.5:
		quality = "mistimed"
	else:
		quality = "miss"

	var timing_side: String
	if delta_t < -perfect_half_width:
		timing_side = "early"
	elif delta_t > perfect_half_width:
		timing_side = "late"
	else:
		timing_side = "on_time"

	var shot_data = {
		"direction": chosen_direction,
		"type": chosen_type,
		"quality": quality,
		"timing_side": timing_side,
		"delta_t": delta_t,
	}
	shot_played.emit(shot_data)

## Evaluate the shot data into an outcome (runs / wicket).
## This runs on the authoritative server.
static func resolve_shot(shot_data: Dictionary, delivery_params: Dictionary) -> Dictionary:
	var quality = shot_data.get("quality", "miss")
	var direction = shot_data.get("direction", ShotDirection.STRAIGHT)
	var shot_type = shot_data.get("type", ShotType.GROUND_STROKE)
	var pace = delivery_params.get("pace", 0.85)
	var timing_side = shot_data.get("timing_side", "on_time")

	var runs: int = 0
	var wicket_type: String = ""
	var is_extra: bool = false

	match quality:
		"miss":
			# Complete miss — high chance of bowled or LBW
			var r = randf()
			if r < 0.4:
				wicket_type = "bowled"
			elif r < 0.7:
				wicket_type = "lbw"
			# else dot ball (ball misses stumps too)

		"mistimed":
			# Edge / top-edge — risky
			var r = randf()
			if r < 0.25:
				wicket_type = "caught"
			elif r < 0.35:
				# Thick edge, runs away
				runs = 4
			else:
				runs = randi_range(0, 1)

		"good":
			# Clean-ish contact
			if shot_type == ShotType.DEFENSIVE:
				runs = 0
			elif shot_type == ShotType.LOFTED:
				var r = randf()
				if r < 0.15:
					wicket_type = "caught" # doesn't quite clear
				elif r < 0.4:
					runs = 6
				else:
					runs = randi_range(1, 4)
			else: # GROUND_STROKE
				var weights = [0, 1, 1, 2, 2, 4]
				runs = weights[randi() % weights.size()]

		"perfect":
			# Textbook shot
			if shot_type == ShotType.DEFENSIVE:
				runs = 0
			elif shot_type == ShotType.LOFTED:
				runs = 6 if randf() < 0.7 else 4
			else:
				var r = randf()
				if r < 0.35:
					runs = 4
				elif r < 0.5:
					runs = 6
				else:
					runs = randi_range(1, 3)

	# Pace amplifier: faster balls punish bad timing harder
	if quality == "mistimed" and pace > 0.85:
		if randf() < 0.15:
			wicket_type = "bowled"

	return {
		"runs": runs,
		"wicket_type": wicket_type,
		"is_extra": is_extra,
		"quality": quality,
	}
