extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var stand_col = $CollisionStanding
@onready var crouch_col = $CollisionCrouching
@onready var ceiling_ray = $RayCast2D
@onready var teleport_sfx = $BlinkSFX

var facing_direction := 1.0

const SPEED = 300.0
const CROUCH_SPEED = 120.0
const JUMP_VELOCITY = -400.0

@export var teleport_distance := 200.0
@export var teleport_cooldown := 1.5
@export var max_jumps := 2

var jump_count := 0

var is_crouching := false
var can_teleport := true
var is_teleporting := false

func _physics_process(delta: float) -> void:
	if global_position.y > 640:
		get_tree().reload_current_scene()
		return
		
	if is_teleporting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if is_on_floor():
		jump_count = 0
	
	if Input.is_action_just_pressed("ui_accept") and not is_crouching and jump_count < max_jumps:
		velocity.y = JUMP_VELOCITY
		jump_count += 1
	
	if Input.is_action_just_pressed("teleport") and can_teleport and not is_teleporting:
		print("teleporting")
		start_teleport()
		return

	# Crouch
	var crouch_input = Input.is_action_pressed("crouch")

	if crouch_input and is_on_floor():
		is_crouching = true
	elif not crouch_input:
		if not ceiling_ray.is_colliding():
			is_crouching = false
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	
	var current_speed = SPEED
	if is_crouching:
		current_speed = CROUCH_SPEED
		
	if direction:
		facing_direction = direction
		velocity.x = direction * current_speed
		animated_sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
	
	# ===== ANIMATION LOGIC =====
	if is_crouching:
		play_anim("crouch")
	elif not is_on_floor():
		if velocity.y < 0:
			play_anim("jump")
		else:
			play_anim("fall")
	elif direction != 0:
		play_anim("walk")
	else:
		play_anim("idle")
	
	update_collider()
	move_and_slide()


func update_collider():
	if is_crouching:
		stand_col.disabled = true
		crouch_col.disabled = false
	else:
		stand_col.disabled = false
		crouch_col.disabled = true
		

func start_teleport():
	is_teleporting = true
	can_teleport = false
	
	velocity = Vector2.ZERO
	animated_sprite.play("clap")
	
	# hitung durasi animasi
	var anim_length = animated_sprite.sprite_frames.get_frame_count("clap") / animated_sprite.sprite_frames.get_animation_speed("clap")
	
	await get_tree().create_timer(anim_length).timeout
	
	do_teleport()


func do_teleport():
	var dir = Vector2(facing_direction, 0)
	var target_position = global_position + dir * teleport_distance
	
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		target_position
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		global_position = target_position
		teleport_sfx.play(0.30)
	else:
		print("Teleport blocked!")
	
	is_teleporting = false
	
	start_cooldown()

	
func play_anim(animation_name):
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

func start_cooldown():
	await get_tree().create_timer(teleport_cooldown).timeout
	can_teleport = true
