extends Area2D

signal hit_player

var radius : float
var shield_draw_thickness : float
var health_percent : float
var shield_angle : float
@onready var hit_effect_timer : Timer = $HitEffectTimer

var shield_regen_speed : float = 0.1

func _enter_tree() -> void:
	set_multiplayer_authority(str(get_parent().get_parent().name).to_int())

func _ready() -> void:
	radius = get_node("CollisionCircle").shape.radius
	shield_draw_thickness = 0.7
	health_percent = 1

func _process(_delta) -> void:
	queue_redraw()

func _physics_process(delta) -> void:
	if health_percent < 1:
		health_percent += delta * shield_regen_speed

func _draw() -> void:
	var angle_half = PI * health_percent
	draw_arc(Vector2.ZERO, radius, shield_angle - angle_half, shield_angle + angle_half, 32, Color.WHITE, shield_draw_thickness, true)
	draw_arc(Vector2.ZERO, radius, -2*PI + shield_angle + angle_half, shield_angle - angle_half, 32, Color.INDIAN_RED, 0.25, true)

# each client is responsible for detecting hits
# for this game, gameplay smoothness is more important
# than preventing cheating
func _on_area_entered(area) -> void:
	if is_multiplayer_authority():
		var bullet = area.get_parent()
		if not (bullet.my_shield == self and not bullet.can_hit_my_shield):
			# figure out if the bullet is in the blockable area
			var angle_half = PI * health_percent
			var angle_bullet = global_position.angle_to(bullet.global_position)
			if angle_bullet < shield_angle - angle_half or angle_bullet > shield_angle + angle_half:
				call_deferred("defer_hit_player")
			else:
				hit_shield.rpc()
	area.get_parent().queue_free()

@rpc("call_local")
func hit_shield() -> void:
	shield_draw_thickness = 3
	health_percent *= 0.95 * health_percent
	health_percent *= 0.7
	hit_effect_timer.start()

# this is necessary because _on_area_entered() blocks
# the physics thread, causing problems if we don't defer
# the call
func defer_hit_player() -> void:
	emit_signal("hit_player")

# timer for shield hit effect
func _on_hit_effect_timer_timeout() -> void:
	shield_draw_thickness = 0.7
