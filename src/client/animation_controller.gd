class_name AnimationController
extends Node

@export var bowler_sprite: AnimatedSprite2D
@export var batsman_sprite: AnimatedSprite2D
@export var fielder_sprite: AnimatedSprite2D
@export var umpire_sprite: AnimatedSprite2D
@export var crowd_sprite: AnimatedSprite2D

func _ready():
	_build_sprite_frames()

func _build_sprite_frames():
	if not batsman_sprite: return
	
	# Batsman (10 frames)
	var bat_tex = load("res://assets/sprites/batsman_atlas.png")
	var bat_frames = SpriteFrames.new()
	var bat_anims = ["idle", "defensive", "defensive_back", "drive_prep", "drive", "pull_prep", "pull", "loft_prep", "lofted", "out"]
	for i in range(bat_anims.size()):
		bat_frames.add_animation(bat_anims[i])
		var atlas = AtlasTexture.new()
		atlas.atlas = bat_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		bat_frames.add_frame(bat_anims[i], atlas)
	batsman_sprite.sprite_frames = bat_frames
	batsman_sprite.play("idle")
	
	# Bowler (8 frames)
	var bowl_tex = load("res://assets/sprites/bowler_atlas.png")
	var bowl_frames = SpriteFrames.new()
	bowl_frames.add_animation("pace_run_up")
	bowl_frames.set_animation_speed("pace_run_up", 12.0)
	bowl_frames.set_animation_loop("pace_run_up", true)
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = bowl_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		bowl_frames.add_frame("pace_run_up", atlas)
	
	bowl_frames.add_animation("pace_release")
	var pr = AtlasTexture.new()
	pr.atlas = bowl_tex
	pr.region = Rect2(4 * 32, 0, 32, 32)
	bowl_frames.add_frame("pace_release", pr)
	
	bowl_frames.add_animation("idle")
	var bi = AtlasTexture.new()
	bi.atlas = bowl_tex
	bi.region = Rect2(0, 0, 32, 32)
	bowl_frames.add_frame("idle", bi)
	bowler_sprite.sprite_frames = bowl_frames
	bowler_sprite.play("idle")
	
	if not fielder_sprite: return
	
	# Fielder (3 frames)
	var f_tex = load("res://assets/sprites/fielder_atlas.png")
	var f_frames = SpriteFrames.new()
	var f_anims = ["idle", "catch", "throw"]
	for i in range(f_anims.size()):
		f_frames.add_animation(f_anims[i])
		var atlas = AtlasTexture.new()
		atlas.atlas = f_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		f_frames.add_frame(f_anims[i], atlas)
	fielder_sprite.sprite_frames = f_frames
	fielder_sprite.play("idle")
	
	# Umpire (5 frames)
	var u_tex = load("res://assets/sprites/umpire_atlas.png")
	var u_frames = SpriteFrames.new()
	var u_anims = ["idle", "six", "four", "out", "wide"]
	for i in range(u_anims.size()):
		u_frames.add_animation(u_anims[i])
		var atlas = AtlasTexture.new()
		atlas.atlas = u_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		u_frames.add_frame(u_anims[i], atlas)
	umpire_sprite.sprite_frames = u_frames
	umpire_sprite.play("idle")
	
	# Crowd (2 frames)
	var c_tex = load("res://assets/sprites/crowd_atlas.png")
	var c_frames = SpriteFrames.new()
	var c_anims = ["idle", "cheer"]
	for i in range(c_anims.size()):
		c_frames.add_animation(c_anims[i])
		var atlas = AtlasTexture.new()
		atlas.atlas = c_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		c_frames.add_frame(c_anims[i], atlas)
	crowd_sprite.sprite_frames = c_frames
	crowd_sprite.play("idle")


func play_bowl_sequence(is_left_arm: bool = false):
	bowler_sprite.flip_h = is_left_arm
	bowler_sprite.play("pace_run_up")
	
func play_outcome(runs: int, wicket: String, is_left_handed: bool = false):
	batsman_sprite.flip_h = is_left_handed
	
	bowler_sprite.play("pace_release")
	
	if wicket != "":
		batsman_sprite.play("out")
		umpire_sprite.play("out")
		if wicket == "caught":
			fielder_sprite.play("catch")
			
		await get_tree().create_timer(1.0).timeout
		batsman_sprite.play("idle")
		umpire_sprite.play("idle")
		fielder_sprite.play("idle")
		bowler_sprite.play("idle")
		return
		
	if runs == 0:
		batsman_sprite.play("defensive")
	elif runs == 1 or runs == 2:
		batsman_sprite.play("drive")
	elif runs == 4:
		batsman_sprite.play("pull")
		umpire_sprite.play("four")
		crowd_sprite.play("cheer")
	elif runs == 6:
		batsman_sprite.play("lofted")
		umpire_sprite.play("six")
		crowd_sprite.play("cheer")
		
	await get_tree().create_timer(1.0).timeout
	batsman_sprite.play("idle")
	umpire_sprite.play("idle")
	crowd_sprite.play("idle")
	bowler_sprite.play("idle")

func stop_bowler():
	# Keep in release pose or idle
	pass
