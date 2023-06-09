extends Node

@onready var main_menu : PanelContainer = $CanvasLayer/MainMenu
@onready var address_entry : LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const player = preload("res://Scenes/player.tscn")
const PORT : int = 6942
var enet_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var player_colors : Dictionary
var players : int = 0

func _unhandled_input(_event) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed() -> void:
	main_menu.hide()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	# add a player each time a peer is connected
	multiplayer.peer_connected.connect(on_connect_peer)

	add_new_player(multiplayer.get_unique_id())

func _on_join_button_pressed() -> void:
	main_menu.hide()
	var text = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry.text
	if text == "":
		enet_peer.create_client("localhost", PORT)
	else:
		enet_peer.create_client(text, PORT)
	multiplayer.multiplayer_peer = enet_peer

func on_connect_peer(peer_id: int) -> void:
	add_new_player(peer_id)

# called when a peer (client) is connected
func add_new_player(peer_id: int) -> void:
	var id_str = str(peer_id)
	var new_player = player.instantiate()
	new_player.name = id_str
	# server will have the correct player_number, which will be fetched
	# by new players once spawned
	new_player.player_number = players
	add_child(new_player)
	players += 1
