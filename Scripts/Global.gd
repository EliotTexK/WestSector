extends Node

@onready var main_menu : PanelContainer = $CanvasLayer/MainMenu
@onready var address_entry : LineEdit = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const player = preload("res://Scenes/player.tscn")
const PORT : int = 6942
var enet_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func _unhandled_input(_event) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func _on_host_button_pressed() -> void:
	main_menu.hide()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	# add a player each time a peer is connected
	multiplayer.peer_connected.connect(add_player)

	add_player(multiplayer.get_unique_id())

func _on_join_button_pressed() -> void:
	main_menu.hide()
	
	enet_peer.create_client($CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

# called when a peer (client) is connected
func add_player(peer_id: int) -> void:
	var new_player = player.instantiate()
	new_player.name = str(peer_id)
	add_child(new_player)
