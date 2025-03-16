extends Area2D

signal kill_player

var player_number

var radius : float
var shield_draw_thickness : float
var health_percent : float
var shield_angle : float
@onready var hit_effect_timer : Timer = $HitEffectTimer
@onready var collision_circle : CircleShape2D = $CollisionCircle.shape

var shield_regen_speed : float = 0.1

func _ready() -> void:
	radius = collision_circle.radius
	shield_draw_thickness = 0.7
	health_percent = 1

func _physics_process(_delta: float) -> void:
	queue_redraw()

func _process(delta) -> void:
	if health_percent < 1:
		health_percent += delta * shield_regen_speed

func _draw() -> void:
	var gr = global_rotation
	var angle_half = PI * health_percent
	draw_arc(
		Vector2.ZERO,
		radius,
		shield_angle - angle_half - gr,
		shield_angle + angle_half - gr,
		64, Color.WHITE, shield_draw_thickness,
		true
	)
	draw_arc(
		Vector2.ZERO,
		radius, -2*PI + shield_angle + angle_half - gr,
		shield_angle - angle_half - gr,
		64, Color.INDIAN_RED,
		0.25, true
	)

func _on_area_entered(area) -> void:
	var bullet = area.get_parent()
	if bullet.player_number == self.player_number and not bullet.can_hit_my_shield:
		return
	else:
		# figure out if the bullet is in the blockable area
		var angle_half = PI * health_percent
		var angle_bullet = global_position.angle_to_point(bullet.global_position)
		var min_angle = shield_angle - angle_half
		var max_angle = shield_angle + angle_half
		if (angle_bullet < min_angle or angle_bullet > max_angle) and not health_percent == 1.0:
			call_deferred("deferred_kill_player")
		else:
			hit_shield()
		bullet.queue_free()

func deferred_kill_player() -> void:
	emit_signal("kill_player")

func hit_shield() -> void:
	shield_draw_thickness = 3
	health_percent *= 0.95 * health_percent
	health_percent *= 0.7
	hit_effect_timer.start()

# timer for shield hit effect
func _on_hit_effect_timer_timeout() -> void:
	shield_draw_thickness = 0.7
