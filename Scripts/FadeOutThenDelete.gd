extends Node

@onready var alpha : float = 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	alpha -= delta
	if alpha <= 0:
		get_parent().queue_free()
