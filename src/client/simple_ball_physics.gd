class_name SimpleBallPhysics
extends Node2D
## 2.5D Ball trajectory engine.
## Uses 2D screen coordinates (x, y) plus a virtual altitude scalar (z).
## The ball sprite is offset upward by z; a separate shadow sprite stays on the ground.

signal ball_released(delivery_params: Dictionary)
signal ball_bounced(bounce_pos: Vector2)
signal ball_arrived_at_crease(arrival_data: Dictionary)

# --- Nodes ---
var ball_sprite: Sprite2D
var shadow_sprite: Sprite2D

# --- Trajectory state ---
var is_active: bool = false
var elapsed: float = 0.0
var total_flight_time: float = 0.0

# Delivery parameters (set by server before each ball)
var delivery: Dictionary = {}

# Computed waypoints in screen space
var release_pos: Vector2        # Where bowler releases (top of pitch)
var bounce_pos: Vector2         # Where ball pitches (configurable by pitch cursor)
var crease_pos: Vector2         # Batting crease arrival
var release_z: float = 80.0    # Ball height at release (pixels above ground)
var bounce_z: float = 0.0      # Ball hits ground
var crease_z: float = 20.0     # Stump height on arrival

# Phase splits (fraction of total_flight_time)
var phase1_ratio: float = 0.55  # Release -> Bounce
var has_bounced: bool = false

# Swing / Seam / Spin
var swing_drift: float = 0.0   # Horizontal pixels of pre-bounce lateral movement
var spin_deviation: float = 0.0 # Horizontal pixels of post-bounce deviation

func _ready():
	# Create ball sprite (small white circle)
	ball_sprite = Sprite2D.new()
	ball_sprite.visible = false
	add_child(ball_sprite)

	# Create shadow sprite (dark ellipse on ground)
	shadow_sprite = Sprite2D.new()
	shadow_sprite.visible = false
	shadow_sprite.modulate = Color(0, 0, 0, 0.35)
	add_child(shadow_sprite)

	# Generate simple textures procedurally
	_generate_ball_texture()

func _generate_ball_texture():
	# Ball: 8x8 red circle
	var ball_img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	ball_img.fill(Color.TRANSPARENT)
	for xx in range(8):
		for yy in range(8):
			var dx = xx - 3.5
			var dy = yy - 3.5
			if dx * dx + dy * dy <= 12.25:
				ball_img.set_pixel(xx, yy, Color(0.85, 0.1, 0.1))
	ball_sprite.texture = ImageTexture.create_from_image(ball_img)

	# Shadow: 10x6 dark ellipse
	var sh_img = Image.create(10, 6, false, Image.FORMAT_RGBA8)
	sh_img.fill(Color.TRANSPARENT)
	for xx in range(10):
		for yy in range(6):
			var dx = (xx - 4.5) / 5.0
			var dy = (yy - 2.5) / 3.0
			if dx * dx + dy * dy <= 1.0:
				sh_img.set_pixel(xx, yy, Color(0.15, 0.15, 0.15))
	shadow_sprite.texture = ImageTexture.create_from_image(sh_img)


## Call to start a delivery. `params` comes from the server/host.
## Expected keys:
##   pace: float (0.6 = slow spin, 1.0 = fast pace)
##   pitch_x: float (horizontal target on pitch, 0..1, 0.5 = middle stump)
##   pitch_length: float (0 = full toss, 0.3 = full, 0.5 = good length, 0.8 = short)
##   swing: float (-1..1, lateral drift pre-bounce)
##   spin: float (-1..1, deviation post-bounce)
func start_delivery(params: Dictionary, p_release: Vector2, p_crease: Vector2, pitch_rect: Rect2):
	delivery = params
	release_pos = p_release
	crease_pos = p_crease

	var pace: float = params.get("pace", 0.85)
	var pitch_length: float = params.get("pitch_length", 0.5)
	var pitch_x: float = params.get("pitch_x", 0.5)
	swing_drift = params.get("swing", 0.0) * 30.0
	spin_deviation = params.get("spin", 0.0) * 25.0

	# Compute bounce position: lerp between release and crease based on pitch_length
	var pitch_y = lerp(release_pos.y, crease_pos.y, 0.3 + pitch_length * 0.5)
	var pitch_center_x = (release_pos.x + crease_pos.x) * 0.5
	var lateral_offset = (pitch_x - 0.5) * pitch_rect.size.x * 0.3
	bounce_pos = Vector2(pitch_center_x + lateral_offset, pitch_y)

	# Flight time inversely proportional to pace
	total_flight_time = lerp(1.2, 0.5, pace)
	phase1_ratio = lerp(0.6, 0.5, pace)

	# Altitude values
	release_z = 70.0 + pace * 20.0
	crease_z = lerp(10.0, 35.0, clampf(1.0 - pitch_length, 0.0, 1.0)) # Short = higher bounce

	elapsed = 0.0
	has_bounced = false
	is_active = true
	ball_sprite.visible = true
	shadow_sprite.visible = true
	ball_sprite.scale = Vector2(3.0, 3.0)
	shadow_sprite.scale = Vector2(3.0, 3.0)

	ball_released.emit(delivery)

func _process(delta: float):
	if not is_active:
		return

	elapsed += delta
	var t = clampf(elapsed / total_flight_time, 0.0, 1.0)

	var ground_pos: Vector2
	var alt: float

	var bounce_t = phase1_ratio

	if t <= bounce_t:
		# Phase 1: Release -> Bounce
		var local_t = t / bounce_t
		ground_pos = release_pos.lerp(bounce_pos, local_t)
		# Add swing drift (curve before bounce)
		ground_pos.x += swing_drift * sin(local_t * PI)
		# Altitude: parabolic arc from release_z down to 0
		alt = release_z * (1.0 - local_t * local_t)

		if not has_bounced and local_t >= 0.98:
			has_bounced = true
			ball_bounced.emit(bounce_pos)
	else:
		# Phase 2: Bounce -> Crease
		var local_t = (t - bounce_t) / (1.0 - bounce_t)
		ground_pos = bounce_pos.lerp(crease_pos, local_t)
		# Add spin deviation (sharp lateral after bounce)
		ground_pos.x += spin_deviation * local_t
		# Altitude: rises from 0 to crease_z in a partial arc
		alt = crease_z * sin(local_t * PI * 0.5)

	# Position shadow on ground plane
	shadow_sprite.position = ground_pos
	shadow_sprite.scale = Vector2(3.0, 3.0) * (1.0 - alt * 0.003) # Shrinks when ball is high

	# Position ball sprite above ground by altitude
	ball_sprite.position = Vector2(ground_pos.x, ground_pos.y - alt)
	# Scale ball slightly larger when closer to camera (lower on screen)
	var depth_scale = remap(ground_pos.y, release_pos.y, crease_pos.y, 2.0, 4.0)
	ball_sprite.scale = Vector2(depth_scale, depth_scale)

	if t >= 1.0:
		_on_arrival()

func _on_arrival():
	is_active = false
	var arrival_data = {
		"final_pos": ball_sprite.position,
		"ground_pos": shadow_sprite.position,
		"altitude": crease_z,
		"pace": delivery.get("pace", 0.85),
		"spin": delivery.get("spin", 0.0),
	}
	ball_arrived_at_crease.emit(arrival_data)

func hide_ball():
	ball_sprite.visible = false
	shadow_sprite.visible = false
	is_active = false
