extends Area2D

var player_number

var radius : float
var shield_draw_thickness : float
var health_percent : float
var shield_angle : float
@onready var hit_effect_timer : Timer = $HitEffectTimer
@onready var collision_circle : CircleShape2D = $CollisionCircle.shape
# TODO: shield radius should be constant with respect to screen size
# TODO: shield should have "inverted color" shader
# TODO: shield should only shrink once the hit_effect timer has worn off, to better indicate where the shield sector was when it was hit
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
	if not bullet is Bullet:
		print("HANDLE THIS COLLISION")
		return
	if bullet.player_number == self.player_number and not bullet.can_hit_my_shield:
		return
	Global.remove_bullet(bullet)
	if hit_effect_timer.is_stopped():
		hit_shield_or_die(bullet)

func hit_shield_or_die(bullet: Node2D) -> void:
	# figure out if the bullet is in the blockable area
	var angle_half = PI * health_percent
	var angle_bullet = global_position.angle_to_point(bullet.global_position)
	# TODO: come back here if/when we want more network synchronization
	if player_number == Global.my_player_number:
		if (abs(angle_bullet - shield_angle) > angle_half) and not health_percent >= 0.99:
			print("%d: hit!" % Global.my_player_number)
			call_deferred("deferred_kill_player")
		else:
			print("%d: miss!" % Global.my_player_number)
			hit_shield()
	else:
		hit_shield()

func deferred_kill_player() -> void:
	Global.kill_player(Global.root.my_player)

func hit_shield() -> void:
	shield_draw_thickness = 3
	health_percent *= 0.95 * health_percent
	health_percent *= 0.7
	hit_effect_timer.start()

# timer for shield hit effect
func _on_hit_effect_timer_timeout() -> void:
	shield_draw_thickness = 0.7
