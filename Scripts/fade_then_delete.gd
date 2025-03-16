extends Node2D

var mod_left: float = 2.0
var vel: float

func _ready() -> void:
	set_process(false)
	vel = randf_range(0.7,1.0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	mod_left -= delta*vel
	self.modulate.a = min(1.0,mod_left)
	if mod_left <= 0:
		queue_free()
