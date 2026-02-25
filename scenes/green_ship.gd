extends CharacterBody2D

@export var gravity: float = 200.0
@export var walk_speed: float = 200.0
@export var jump_speed: float = -300.0


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta

	if is_on_floor() and Input.is_action_just_pressed("ui_up"):
		velocity.y = jump_speed

	if Input.is_action_pressed("ui_left"):
		velocity.x = -walk_speed
	elif Input.is_action_pressed("ui_right"):
		velocity.x = walk_speed
	else:
		velocity.x = 0.0

	# move_and_slide() already takes delta into account
	move_and_slide()
