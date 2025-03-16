extends Camera2D

@export var targets: Array[Node2D] = []  # Nodes to track
@export var padding_ratio: float = 0.2  # Space around targets, percent of screen
@export var vertical_padding_factor: float = 0.2  # Reduce vertical padding sensitivity
@export var min_zoom: float = 0.2  # Min zoom level
@export var max_zoom: float = 1.0  # Max zoom level
@export var zoom_smoothness: float = 5.0  # Higher = smoother zoom
@export var move_smoothness: float = 5.0  # Higher = smoother movement

func _process(delta: float):
	if targets.is_empty():
		return

	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	for target in targets:
		if target:
			min_pos = min_pos.min(target.global_position)
			max_pos = max_pos.max(target.global_position)

	var padding = get_viewport_rect().size.x * padding_ratio
	var center = (min_pos + max_pos) * 0.5
	var size = (max_pos - min_pos) + Vector2(padding * 2, padding * 2 * vertical_padding_factor)
	var viewport_size = get_viewport_rect().size
	var target_zoom = min(viewport_size.x / size.x, viewport_size.y / size.y)
	target_zoom = clamp(target_zoom, min_zoom, max_zoom)

	position = position.lerp(center, 1.0 - exp(-move_smoothness * delta))
	zoom = zoom.lerp(Vector2(target_zoom, target_zoom), 1.0 - exp(-zoom_smoothness * delta))
