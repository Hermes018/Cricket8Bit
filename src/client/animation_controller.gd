class_name AnimationController
extends Node

@export var bowler_sprite: AnimatedSprite2D
@export var batsman_sprite: AnimatedSprite2D

func _ready():
	_build_sprite_frames()

func _build_sprite_frames():
	if not bowler_sprite or not batsman_sprite:
		return
		
	# Build Bowler frames
	var bowler_tex = load("res://assets/sprites/bowler_atlas.png")
	var bowler_frames = SpriteFrames.new()
	bowler_frames.add_animation("run_up")
	bowler_frames.set_animation_speed("run_up", 8.0)
	bowler_frames.set_animation_loop("run_up", true)
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = bowler_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		bowler_frames.add_frame("run_up", atlas)
		
	bowler_frames.add_animation("idle")
	var idle_atlas = AtlasTexture.new()
	idle_atlas.atlas = bowler_tex
	idle_atlas.region = Rect2(0, 0, 32, 32)
	bowler_frames.add_frame("idle", idle_atlas)
	
	bowler_sprite.sprite_frames = bowler_frames
	bowler_sprite.play("idle")
	
	# Build Batsman frames
	var bat_tex = load("res://assets/sprites/batsman_atlas.png")
	var bat_frames = SpriteFrames.new()
	bat_frames.add_animation("swing")
	bat_frames.set_animation_speed("swing", 12.0)
	bat_frames.set_animation_loop("swing", false)
	for i in range(3):
		var atlas = AtlasTexture.new()
		atlas.atlas = bat_tex
		atlas.region = Rect2(i * 32, 0, 32, 32)
		bat_frames.add_frame("swing", atlas)
		
	bat_frames.add_animation("idle")
	var bat_idle = AtlasTexture.new()
	bat_idle.atlas = bat_tex
	bat_idle.region = Rect2(0, 0, 32, 32)
	bat_frames.add_frame("idle", bat_idle)
	
	batsman_sprite.sprite_frames = bat_frames
	batsman_sprite.play("idle")

func play_bowl_sequence():
	bowler_sprite.play("run_up")
	
func play_bat_swing():
	batsman_sprite.play("swing")
	await get_tree().create_timer(0.3).timeout # Wait for swing to resolve
	batsman_sprite.play("idle")
	
func stop_bowler():
	bowler_sprite.play("idle")
