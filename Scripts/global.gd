extends Node

# singletons, get your singletons, hot and ready!

const MAX_PEERS = 5

var root: Node
var my_player_number: int = -1
var is_dead: Dictionary

var my_bullets: Dictionary
var opponent_bullets: Dictionary
var bullet_uid: int = 0 # TODO: mutex guard this if it is ever accessed from different threads
var bullet_instance = preload("res://Scenes/bullet.tscn")

func add_new_bullet(player_number: int, pos: Vector2, initial_vel: Vector2):
	var bullet = bullet_instance.instantiate()
	bullet.uid = bullet_uid*MAX_PEERS + player_number - 1
	bullet_uid += 1
	bullet.player_number = player_number
	bullet.global_position = pos
	bullet.initial_vel = initial_vel
	my_bullets[bullet.uid] = bullet
	root.add_child(bullet)

func update_bullet(uid: int, player_number: int, x: float, y: float) -> void:
	if opponent_bullets.has(uid):
		var bullet = opponent_bullets[uid]
		if bullet:
			bullet.update_position_opponent(Vector2(x,y))
	else:
		var bullet = bullet_instance.instantiate()
		bullet.uid = uid
		bullet.player_number = player_number
		bullet.global_position = Vector2(x,y)
		opponent_bullets[bullet.uid] = bullet
		root.add_child(bullet)
		bullet.set_process(false)

func remove_bullet(bullet: Node2D):
	my_bullets.erase(bullet.uid)
	bullet.queue_free()

func kill_player(player):
	if player:
		is_dead[player.player_number] = true
		player.queue_free()
