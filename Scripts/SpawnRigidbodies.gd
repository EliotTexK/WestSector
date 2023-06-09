extends Node2D

func _ready() -> void:
	correct_scale()

# sets the scale of child rigidbodies:
# since you can't scale rigidbodies directly, scale children
func correct_scale() -> void:
	for rigidbody in get_children():
		for child in rigidbody.get_children():
			child.scale = self.global_scale

func spawn() -> void:
	for rigidbody in get_children():
		var gp = rigidbody.global_position
		var gr = rigidbody.global_rotation
		remove_child(rigidbody)
		# not sure why we need to do this, but godot's
		# error log told me to, and it fixed many issues
		get_tree().root.get_child(0).add_child(rigidbody)
		rigidbody.global_position = gp
		rigidbody.global_rotation = gr
		rigidbody.freeze = false
		rigidbody.visible = true
