extends Area2D

var radius : float
var shield_draw_thickness : float
@onready var hit_effect_timer : Timer = $HitEffectTimer

func _ready() -> void:
	radius = get_node("CollisionCircle").shape.radius
	shield_draw_thickness = 0.7

func _draw() -> void:
	draw_arc(Vector2(0,0),radius,0,2*PI,32,Color.WHITE,shield_draw_thickness,true)

# detect bullets
func _on_area_entered(area) -> void:
	var bullet = area.get_parent()
	if not (bullet.my_shield == self and not bullet.can_hit_my_shield):
		shield_draw_thickness = 3
		queue_redraw()
		hit_effect_timer.start()

# timer for shield hit effect
func _on_hit_effect_timer_timeout() -> void:
	shield_draw_thickness = 0.7
	queue_redraw()
