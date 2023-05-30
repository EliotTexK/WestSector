extends CharacterBody2D

const SPEED = 400.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var animation_player : AnimationPlayer
var character_rig : Node2D

func _ready():
	animation_player = get_node("CharacterRig/AnimationPlayer")
	animation_player.set_current_animation("leg_idle")
	character_rig = get_node("CharacterRig")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		if is_on_wall():
			animation_player.play("leg_idle",-1,1.0,false)
		else:
			animation_player.play("leg_walk",-1,3.0,false)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animation_player.play("leg_idle",-1,1.0,false)

	if is_on_floor():
		var rot = Vector2.UP.angle_to(get_floor_normal())
		# set player angle based on slope, smooth the transition
		var correct = (rot - character_rig.global_rotation)
		if correct != 0: character_rig.global_rotation += correct * delta * 30
		# correct position so he doesn't float above the ground
		character_rig.position.y = -115 + 60*abs(sin(rot))
	else:
		character_rig.position.y = -115
		animation_player.play("leg_jump",-1,1.0,false)
		if character_rig.global_rotation_degrees > 0.1 or character_rig.global_rotation_degrees < -0.1:
			character_rig.global_rotation -= character_rig.global_rotation*0.2

	move_and_slide()
