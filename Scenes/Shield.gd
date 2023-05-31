extends Area2D

var radius : float

func _ready():
	radius = get_node("CollisionCircle").shape.radius

func _process(delta):
	pass

func _draw():
	draw_arc(Vector2(0,0),radius,0,2*PI,32,Color(1,1,1,1),0.5,true)
