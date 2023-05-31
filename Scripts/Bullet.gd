extends Node2D

# bullet follows a parabola exactly so that
# its path can be predicted and we can reverse it
var time : float
var origin : Vector2
var curr_vel : Vector2
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var initial_vel : Vector2
var radius : float

@export var grav_multiplier : float
@export var time_multiplier : float # how fast the bullet moves, including gravity
@export var color : Color

func _ready():
	time = 0
	origin = position
	gravity *= grav_multiplier

func _process(delta):
	position = Vector2(origin.x + initial_vel.x * time,
		origin.y + initial_vel.y * time + 0.5 * gravity * time * time
	)
	curr_vel = Vector2(initial_vel.x, initial_vel.y + gravity * time)
	time += delta * time_multiplier
	queue_redraw()

func _draw():
	draw_line(Vector2.ZERO,curr_vel/50,color,4,true)

# destroy the bullet when it goes off-screen, but not when it goes above the level
func _on_visible_on_screen_notifier_2d_screen_exited():
	if position.y > 0:
		queue_free()

# destroy the bullet when it collides with level geometry
func _on_collision_body_entered(body):
	queue_free()
