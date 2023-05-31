extends CharacterBody2D

@export var move_speed : float
@export var jump_speed : float
@export var gravity_multiplier : float
@export var bullet_vel_multiplier : float # speed at which bullets come out

var bullet_instance = preload("res://Scenes/bullet.tscn")

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
		velocity.y += gravity * delta * gravity_multiplier

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_speed

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * move_speed
		if is_on_wall():
			animation_player.play("leg_idle",-1,1.0,false)
		else:
			animation_player.play("leg_walk",-1,3.0,false)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
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
	
	# fire bullets
	if Input.is_action_just_pressed("fire"):
		var bullet = bullet_instance.instantiate()
		var ag = character_rig.get("active_gun")
		var cursor = get_viewport().get_mouse_position()
		bullet.position = ag.global_position
		bullet.set("initial_vel",(cursor-ag.global_position).normalized()*bullet_vel_multiplier)
		get_tree().root.get_child(0).add_child(bullet)
		ag.change_tip_color()
