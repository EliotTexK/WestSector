extends Node

@export var player_scale : Vector2 = Vector2(.05,.05)
@export var main_menu : PanelContainer
@export var address_entry : LineEdit
@export var main_camera : Camera2D
@export var stage_container : Node

const player = preload("res://Scenes/player.tscn")
const PORT : int = 6942

var enet_peer: ENetMultiplayerPeer
var my_id : int
var my_player : Node2D
var my_total_peers_connected = 0
var peer_number : Dictionary
var peer_players : Dictionary

func _ready() -> void:
	Global.root = self

func _unhandled_input(_event) -> void:
	if Input.is_action_just_pressed("quit"):
		disconnect_peer.rpc(my_id)
		get_tree().quit()

func _on_host_button_pressed() -> void:
	enet_peer = ENetMultiplayerPeer.new()
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(on_connect_peer)
	multiplayer.peer_packet.connect(on_recieved_peer)
	my_id = multiplayer.get_unique_id()
	my_total_peers_connected = 1
	add_peer_player(my_id, my_total_peers_connected) # nobody to rpc here
	print("hosted game, my id is %d" % my_id)
	main_menu.hide()

func _on_join_button_pressed() -> void:
	var address = $MenuLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry.text
	if address == "": address = "127.0.0.1"
	enet_peer = ENetMultiplayerPeer.new()
	enet_peer.create_client(address, PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(on_connect_peer)
	multiplayer.peer_packet.connect(on_recieved_peer)
	my_id = multiplayer.get_unique_id()
	print("attempting to join game, my id is %d" % my_id)
	main_menu.hide()

func on_connect_peer(peer_id_from: int) -> void:
	print("%d: incoming connection from %d" % [my_id, peer_id_from])
	if my_total_peers_connected <= Global.MAX_PEERS:
		my_total_peers_connected += 1
		if my_id == 1:
			# host broadcast all joined players, so order isn't confused
			add_peer_player(my_id,1)
			for peer_id in peer_number.keys():
				add_peer_player.rpc(peer_id,peer_number[peer_id])
			add_peer_player.rpc(peer_id_from,my_total_peers_connected)
	else:
		print("%d: too many peers! Max is %d" % [my_id, Global.MAX_PEERS])

func add_player(player_number: int, is_opponent: bool) -> Node2D:
	var new_player = player.instantiate()
	new_player.scale = player_scale
	new_player.visible = false
	add_child(new_player)
	new_player.global_position = stage_container.get_child(0).spawnpoint_container.get_child(player_number-1).global_position
	if is_opponent: new_player.set_opponent()
	new_player.set_player_number(player_number)
	main_camera.targets.append(new_player)
	new_player.visible = true
	return new_player

@rpc("call_local","reliable")
func add_peer_player(peer_id: int, order: int) -> void:
	
	print("%d: setting peer order of peer %d to %d" % [my_id, peer_id, order])
	var is_new = peer_id not in peer_number.keys()
	if is_new:
		peer_number[peer_id] = order
		if peer_id == my_id:
			my_player = add_player(order,false)
		else:
			peer_players[peer_id] = add_player(order,true)

@rpc("call_local","reliable")
func disconnect_peer(peer_id: int) -> void:
	print("%d: peer %d disconnected" % [my_id, peer_id])
	multiplayer.disconnect_peer(peer_id)

func on_recieved_peer(peer_id: int, packet: PackedByteArray) -> void:
	if peer_id in peer_players and peer_id != my_id:
		var peer_player = peer_players[peer_id]
		if peer_player:
			var split_msg = packet.get_string_from_ascii().split(";")
			var player_data = split_msg[0].split(",")
			peer_player.global_position = Vector2(float(player_data[0]),float(player_data[1]))
			peer_player.update_anim_from_state(int(player_data[2]))
			peer_player.shield.health_percent = float(player_data[3])
			peer_player.character_rig.position.y = float(player_data[4])
			peer_player.character_rig.global_rotation = float(player_data[5])
			peer_player.character_rig.cursor = Vector2(float(player_data[6]),float(player_data[7]))
			for bullet_msg in split_msg.slice(1):
				var bullet_data = bullet_msg.split(",")
				if len(bullet_data) < 3: continue
				Global.update_bullet(
					int(bullet_data[0]),
					peer_number[peer_id],
					float(bullet_data[1]),
					float(bullet_data[2])
				)
				
func _process(_delta: float) -> void:
	if my_player:
		var msg = ""
		# player data
		msg += "%.2f," % my_player.global_position.x
		msg += "%.2f," % my_player.global_position.y
		msg += "%d," % my_player.anim_state
		msg += "%.2f," % my_player.shield.health_percent
		msg += "%.2f," % my_player.character_rig.position.y
		msg += "%.2f," % my_player.character_rig.global_rotation
		var mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
		msg += "%.2f," % mouse_pos.x
		msg += "%.2f," % mouse_pos.y
		# bullet data
		if len(Global.my_bullets.keys()) > 0:
			msg += ";"
			for bid in Global.my_bullets.keys():
				msg += "%d," % bid
				var bul = Global.my_bullets[bid]
				msg += "%.2f," % bul.global_position.x
				msg += "%.2f;" % bul.global_position.y
		multiplayer.send_bytes(msg.to_ascii_buffer())
