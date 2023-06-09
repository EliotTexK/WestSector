extends Node2D

@export var desired_cursor : Vector2 # sync this with some latency
var cursor : Vector2 # follow desired_cursor so it doesn't look laggy

@export var hand_radius : float
@onready var torso : Node2D = $Torso
@onready var leftGun : Node2D = $Torso/LeftGun
@onready var rightGun : Node2D = $Torso/RightGun
@onready var leftWrist : Node2D = $Torso/LeftGun/LeftWrist # read-only
@onready var rightWrist : Node2D = $Torso/RightGun/RightWrist # read-only
@onready var upperLeftArm : Node2D = $Torso/UpperLeftArm # center of aim radius for left hand
@onready var lowerLeftArm : Node2D = $Torso/UpperLeftArm/LowerLeftArm
@onready var upperRightArm : Node2D = $Torso/UpperRightArm # center of aim radius for left hand
@onready var lowerRightArm : Node2D = $Torso/UpperRightArm/LowerRightArm
@onready var defaultLeftGunPos : Node2D = $Torso/DefaultLeftGunPos # return to this position when not aiming left gun
@onready var defaultRightGunPos : Node2D = $Torso/DefaultRightGunPos # return to this position when not aiming right gun
@onready var shield : Node2D = $Shield
var upperArmLength : float 
var lowerArmLength : float
var total_arm_length : float
var active_gun : Node2D

func _enter_tree() -> void:
	set_multiplayer_authority(str(get_parent().name).to_int())

func _ready() -> void:
	upperArmLength = (lowerLeftArm.global_position - upperLeftArm.global_position).length()
	lowerArmLength = (leftWrist.global_position - lowerLeftArm.global_position).length()
	total_arm_length = upperArmLength + lowerArmLength
		
func _process(delta) -> void:
	if is_multiplayer_authority():
		desired_cursor = get_viewport().get_mouse_position()
		cursor = desired_cursor
	else:
		cursor += (desired_cursor - cursor) * 20 * delta
	var center_to_cursor = torso.global_position.angle_to_point(cursor)
	shield.shield_angle = center_to_cursor
	# if the cursor is left of the character, aim the left gun, etc.
	if abs(center_to_cursor) > PI/2:
		# move/rotate left hand to at the cursor
		# if the cursor is close enough to the character,
		# take that into account
		var dist = (upperLeftArm.global_position - cursor).length()
		if dist > hand_radius/8:
			if dist <= hand_radius:
				var offset = (upperLeftArm.global_position - leftGun.global_position).normalized() * 3
				leftGun.global_position = cursor + offset
			else:
				var dir_to_cursor = (upperLeftArm.global_position - cursor).normalized()
				leftGun.global_position = upperLeftArm.global_position - hand_radius * dir_to_cursor
			leftGun.look_at(cursor)
		# right hand: smoothly reset back to default position and rotation
		var vec = defaultRightGunPos.position - rightGun.position
		vec.x *= 2
		if vec.length() > 0.1: rightGun.position += vec * 5 * delta
		if rightGun.rotation_degrees > 0.1 or rightGun.rotation_degrees < -0.1:
			rightGun.rotation -= rightGun.rotation * 5 * delta
		# set position of active gun
		active_gun = leftGun
	else:
		# move/rotate right hand to at the cursor
		# if the cursor is close enough to the character,
		# take that into account
		var dist = (upperRightArm.global_position - cursor).length()
		if dist > hand_radius/8:
			if dist <= hand_radius:
				var offset = (upperRightArm.global_position - rightGun.global_position).normalized() * 3
				rightGun.global_position = cursor + offset
			else:
				var dir_to_cursor = (upperRightArm.global_position - cursor).normalized()
				rightGun.global_position = upperRightArm.global_position - hand_radius * dir_to_cursor
			rightGun.look_at(cursor)
		# left hand: smoothly reset back to default position and rotation
		var vec = defaultLeftGunPos.position - leftGun.position
		vec.x *= 2
		if vec.length() > 0.1: leftGun.position += vec * 5 * delta
		if leftGun.rotation_degrees > 180.1:
			leftGun.rotation_degrees -= (leftGun.rotation_degrees - 180) * 5 * delta
		if leftGun.rotation_degrees < 179.9:
			leftGun.rotation_degrees += (180 - leftGun.rotation_degrees) * 5 * delta
		# set position of active gun
		active_gun = rightGun
	# use 2 bone IK to update arm positions
	var t1 = upperRightArm.global_position.angle_to_point(rightWrist.global_position)
	var t2 = (total_arm_length - (rightWrist.global_position - upperRightArm.global_position).length()) / total_arm_length
	t2 = t2*2
	upperRightArm.global_rotation = t1 + t2
	lowerRightArm.look_at(rightWrist.global_position)
	lowerRightArm.rotate(PI)
	t1 = upperLeftArm.global_position.angle_to_point(leftWrist.global_position) + PI
	t2 = (total_arm_length - (leftWrist.global_position - upperLeftArm.global_position).length()) / total_arm_length
	t2 = t2*2
	upperLeftArm.global_rotation = t1 - t2
	lowerLeftArm.look_at(leftWrist.global_position)
	lowerLeftArm.rotate(PI)
