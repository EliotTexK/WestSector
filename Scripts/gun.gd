extends AnimatedSprite2D

@onready var TipColorTimer : Timer = $TipColorTimer

# change to different animation frame after firing
# then set a short timer to change back
func change_tip_color() -> void:
	frame = 1
	TipColorTimer.start()

func _on_tip_color_timer_timeout() -> void:
	frame = 0
