extends Node2D

# bullet follows a parabola exactly so that
# its path can be predicted and we can reverse it
@export var initial_vel : Vector2
var time : float
var origin : Vector2
var curr_vel : Vector2
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var radius : float
var my_shield : Area2D # instance of the player's shield that shot this bullet
# upon exiting this area, allow bullet to hit my_shield
var my_self_damage_invincible_area : Area2D
var can_hit_my_shield = false

@export var grav_multiplier : float
@export var time_multiplier : float # how fast the bullet moves, including gravity
@export var color : Color

var sepx

func _ready() -> void:
	time = 0
	origin = position
	gravity *= grav_multiplier

func _physics_process(delta) -> void:
	# apply kinematics equations
	position = Vector2(origin.x + initial_vel.x * time,
		origin.y + initial_vel.y * time + 0.5 * gravity * time * time
	)
	curr_vel = Vector2(initial_vel.x, initial_vel.y + gravity * time)
	time += delta * time_multiplier
	queue_redraw()

# draw the bullet as a line with length porportional to its velocity
func _draw() -> void:
	draw_line(Vector2.ZERO,curr_vel/50,color,4,true)

# destroy the bullet when it goes off-screen, but not when it goes above the level
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if position.y > 0:
		queue_free()

# destroy the bullet when it collides with level geometry
func _on_collision_body_entered(_body) -> void:
	queue_free()

# allow the bullet to hit my_shield once it has exited my_self_damage_invincible_area
func _on_collision_area_exited(area) -> void:
	if area == my_self_damage_invincible_area:
		can_hit_my_shield = true
