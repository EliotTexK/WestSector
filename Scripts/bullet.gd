extends Node2D

var player_number: int
var uid: int
var can_hit_my_shield = false

var pos_prev : Vector2
var initial_vel : Vector2
var time : float
var time_prev : float
var origin : Vector2
@export var curr_vel : Vector2
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var radius : float

@export var grav_multiplier : float
@export var time_multiplier : float # how fast the bullet moves through time
@export var color : Color

@onready var shot_sprite: Sprite2D = $StarSprite

func _ready() -> void:
	time = 0
	time_prev = 0
	origin = position
	pos_prev = position
	gravity *= grav_multiplier
   
func _process(delta) -> void:
	# apply kinematics equations
	position = Vector2(origin.x + initial_vel.x * time,
		origin.y + initial_vel.y * time + 0.5 * gravity * time * time
	)
	pos_prev = Vector2(origin.x + initial_vel.x * time_prev,
		origin.y + initial_vel.y * time_prev + 0.5 * gravity * time_prev * time_prev
	)
	curr_vel = Vector2(initial_vel.x, initial_vel.y + gravity * time)
	time_prev = time
	time += delta * time_multiplier
	queue_redraw()

# draw the bullet as a line with length porportional to its velocity
func _draw() -> void:
	var vel = pos_prev-position
	draw_line(vel*2,Vector2.ZERO,Color.WHITE,7,true)
	shot_sprite.rotation = 5*time

# destroy the bullet when it goes off-screen, but not when it goes above the level
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if position.y > 0:
		Global.remove_bullet(self)

# destroy the bullet when it collides with level geometry
func _on_collision_body_entered(_body) -> void:
	Global.remove_bullet(self)

# allow the bullet to hit my_shield once it has exited my_self_damage_invincible_area
func _on_collision_area_exited(area) -> void:
	if area is SelfDamageInvincibleArea and area.player_number == self.player_number:
		can_hit_my_shield = true
