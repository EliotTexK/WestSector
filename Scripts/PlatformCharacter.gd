extends CharacterBody2D

@export var move_speed : float
@export var jump_speed : float
@export var gravity_multiplier : float
@export var bullet_vel_multiplier : float # speed at which bullets come out

var bullet_instance = preload("res://Scenes/bullet.tscn")
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation_player : AnimationPlayer = $CharacterRig/AnimationPlayer
@onready var character_rig : Node2D = $CharacterRig
@onready var shield : Area2D = $CharacterRig/Shield
@onready var self_damage_invincible_area : Area2D = $CharacterRig/SelfDamageInvincibleArea

# sync animation between clients on update
var animation_state : String
# desired rotation adjustment for CharacterRig, so that changes can be smoothed
# synced betweeen clients on update
var desired_rot : float

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

func _ready() -> void:
	animation_state = "idle"
	sync_set_pos_offset.rpc(-115)

func _process(delta: float):
	# change animation based on state
	match animation_state:
		"idle": animation_player.play("leg_idle")
		"walk": animation_player.play("leg_walk",-1,3.0)
		"jump": animation_player.play("leg_jump")
	# smoothly transition to desired rotation
	character_rig.global_rotation += (desired_rot - character_rig.global_rotation) * delta * 20

func _physics_process(delta: float) -> void:
	# only process physics if this is a client-controlled character
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta * gravity_multiplier

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed
	
	# Handle character animation state changes
	if is_on_floor():
		stick_to_floor()
		if direction:
			if is_on_wall():
				change_animation_state("idle")
			else:
				change_animation_state("walk")
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			change_animation_state("idle")
	else:
		change_animation_state("jump")
		adjust_air_rotation(delta)
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_speed
		sync_set_pos_offset.rpc(-115)
		sync_set_desired_rot.rpc(0)
	
	move_and_slide()
	
	# fire bullets
	if Input.is_action_just_pressed("fire"):
		fire_bullet.rpc(get_viewport().get_mouse_position())

@rpc("call_local")
func fire_bullet(cursor: Vector2) -> void:
	var ag = character_rig.get("active_gun")
	ag.change_tip_color.rpc()
	
	var bullet = bullet_instance.instantiate()
	
	bullet.my_shield = shield
	bullet.my_self_damage_invincible_area = self_damage_invincible_area
	
	bullet.position = ag.global_position
	bullet.initial_vel = (cursor-ag.global_position).normalized()*bullet_vel_multiplier
	
	get_tree().root.get_child(0).add_child(bullet,true)
	

# check to see if animation state has changed before calling rpc
func change_animation_state(animation: String) -> void:
	if animation != animation_state:
		# upon landing, immediately to stick to floor
		if animation_state == "jump":
			var rot_floor = Vector2.UP.angle_to(get_floor_normal())
			sync_set_immediate_rot(rot_floor)
		sync_animation.rpc(animation)

# updates desired adjustment of the character's position and rotation based
# on the angle of the floor
func stick_to_floor() -> void:
	var rot_floor = Vector2.UP.angle_to(get_floor_normal())
	# find discrepancy between floor angle and desired character rotation
	var rot_discrepancy = (rot_floor - desired_rot)
	# if this discrepancy is significant, update desired character rotation
	if abs(rot_discrepancy) > 0.1: sync_set_desired_rot.rpc(rot_floor)
	# correct position so the character doesn't float above the ground
	var ideal_pos_offset = -115 + 60*abs(sin(rot_floor))
	var pos_discrepancy = character_rig.position.y - ideal_pos_offset
	if abs(pos_discrepancy) > 2: sync_set_pos_offset.rpc(ideal_pos_offset)

func adjust_air_rotation(delta: float) -> void:
	if character_rig.global_rotation_degrees > 0.1 or character_rig.global_rotation_degrees < -0.1:
		character_rig.global_rotation -= character_rig.global_rotation*0.2

@rpc("call_local")
func sync_animation(animation: String) -> void:
	animation_state = animation

@rpc("call_local")
func sync_set_immediate_rot(value: float) -> void:
	desired_rot = value
	character_rig.global_rotation = value

@rpc("call_local")
func sync_set_desired_rot(value: float) -> void:
	desired_rot = value 

@rpc("call_local")
func sync_set_pos_offset(value: float) -> void:
	character_rig.position.y = value
