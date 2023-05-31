extends AnimatedSprite2D

var TipColorTimer : Timer

func _ready():
	TipColorTimer = get_node("TipColorTimer")

# change to different animation frame after firing
# then set a short timer to change back
func change_tip_color():
	frame = 1
	TipColorTimer.start()

func _on_tip_color_timer_timeout():
	frame = 0
