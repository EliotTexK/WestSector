extends CharacterBody2D

var player_number: int = -1

@export var move_speed : float
@export var jump_speed : float
@export var gravity_multiplier : float
@export var bullet_vel_multiplier : float # speed at which bullets come out

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation_player : AnimationPlayer = $CharacterRig/AnimationPlayer
@onready var character_rig : Node2D = $CharacterRig
@onready var shield : Area2D = $CharacterRig/Shield
@onready var self_damage_invincible_area : Area2D = $CharacterRig/SelfDamageInvincibleArea

enum ANIM_STATE {
	IDLE,
	WALK,
	JUMP,
}
var anim_state: ANIM_STATE # for sending to opponents

# desired rotation adjustment for CharacterRig, so that changes can be smoothed
# synced betweeen clients on update
var desired_rot : float

func set_player_number(number: int) -> void:
	player_number = number
	character_rig.set_hue_shift(number)
	shield.player_number = number
	self_damage_invincible_area.player_number = number

func set_opponent() -> void:
	character_rig.set_process(false)
	shield.set_process(false)
	set_process(false)

func _process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta * gravity_multiplier

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_speed
		desired_rot = 0
	
	move_and_slide()
	
	# fire bullets
	if Input.is_action_just_pressed("fire"):
		fire_bullet(get_viewport().get_camera_2d().get_global_mouse_position())
		
	if Input.is_action_just_pressed("death"):
		death()
	
	# smoothly transition to desired rotation
	character_rig.global_rotation += (desired_rot - character_rig.global_rotation) * delta * 20
	
	# Handle character animation state changes
	if is_on_floor():
		stick_to_floor()
		if direction:
			if is_on_wall():
				animation_player.play("leg_idle")
				anim_state = ANIM_STATE.IDLE
			else:
				animation_player.play("leg_walk",-1,1.5)
				anim_state = ANIM_STATE.WALK
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			animation_player.play("leg_idle")
			anim_state = ANIM_STATE.IDLE
	else:
		animation_player.play("leg_jump")
		anim_state = ANIM_STATE.JUMP
		adjust_air_rotation(delta)

func update_anim_from_state(new_anim_state: ANIM_STATE):
	anim_state = new_anim_state
	match anim_state:
		ANIM_STATE.IDLE: animation_player.play("leg_idle")
		ANIM_STATE.WALK: animation_player.play("leg_walk",-1,1.5)
		ANIM_STATE.JUMP: animation_player.play("leg_jump")

func death() -> void:
	queue_free()

func fire_bullet(cursor: Vector2) -> void:
	var ag = character_rig.active_gun
	if ag.frame == 0:
		ag.change_tip_color()
		var initial_vel = (cursor-ag.global_position).normalized()*bullet_vel_multiplier + velocity*global_scale.x*2
		Global.add_new_bullet(
			self.player_number,
			ag.global_position,
			initial_vel
		)

# updates desired adjustment of the character's position and rotation based
# on the angle of the floor
func stick_to_floor() -> void:
	var rot_floor = Vector2.UP.angle_to(get_floor_normal())
	# find discrepancy between floor angle and desired character rotation
	var rot_discrepancy = (rot_floor - desired_rot)
	# if this discrepancy is significant, update desired character rotation
	if abs(rot_discrepancy) > 0.1: desired_rot = rot_floor 
	# correct position so the character doesn't float above the ground
	var ideal_pos_offset = 150*sin(abs(rot_floor)*2)
	var pos_discrepancy = character_rig.position.y - ideal_pos_offset
	if abs(pos_discrepancy) > 2: character_rig.position.y = ideal_pos_offset

func adjust_air_rotation(delta: float) -> void:
	if character_rig.global_rotation_degrees > 0.1 or character_rig.global_rotation_degrees < -0.1:
		character_rig.global_rotation -= character_rig.global_rotation*0.2*delta
