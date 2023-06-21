extends Node

# Scene nodes
onready var healthbar 		= $HealthBar
onready var closeButton 	= $EscapeScreen/CloseButton

onready var startScreen 	= $StartScreen
onready var escapePanel 	= $EscapeScreen/Panel
onready var endScreen 		= $EndScreen
onready var winnerLabel 	= $EndScreen/WinnerLabel

# Loaded Scenes
var player_scene = load("res://src/game/game_objects/Player.tscn")

# Varibles
var is_spectating = false
var n_enemies = 2
var characters_playing = []
#[
#	{
#		network_id: int
#		username: String
#		spawn: Vector2
#		obj_name: String
#	},...
#]

func _ready() -> void:
	print("Entering game. Multiplayer: "+str(Global.is_multiplayer))
	#Block the screen while instanciating
	startScreen.visible = true
	
	# Hide not used GUI elements
	escapePanel.hide()
	endScreen.hide()
	closeButton.show()
	set_player_gui_enabled(true)
	
	
	# Connect multiplayer signals
	if Global.is_multiplayer:
		connect_multiplayer_signals()
		if get_tree().is_network_server():
			characters_playing = _assgin_spawn_points_multi()
			rpc("_spawn_characters", characters_playing)
	else:
		characters_playing = _assgin_spawn_points_single()
		_spawn_characters(characters_playing)


func connect_multiplayer_signals() -> void:
	# When a device connects/disconnects from the network
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

	# When the device is Client
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("server_disconnected", self, "_disconnected_from_server")


func _assgin_spawn_points_multi() -> Dictionary:
	print("Assigning spawn points...")
	var characters = []
	# Add players/enemies to dictionary with attactched spwan point
	for id in Network.connected_players:
		characters.push_back({
			'network_id': id,
			'username': Network.connected_players[id].username,
			'spawn':$GameMap.get_player_spawn_point(),
			'obj_name': str(id),
			'is_player': true
		})
	
	for i in n_enemies:
		characters.push_back({
			'network_id': get_tree().get_network_unique_id(),
			'username': "Enemy",
			'spawn':$GameMap.get_enemy_spawn_point(),
			'obj_name': "Enemy" + str(i),
			'is_player': false
		})
	
	return characters

func _assgin_spawn_points_single() -> Dictionary:
	print("Assigning spawn points...")
	var characters = []
	# Add players/enemies to dictionary with attactched spwan point
	characters.push_back({
		'spawn':$GameMap.get_player_spawn_point(),
		'username': "You",
		'obj_name': "Player",
		'is_player': true
	})
	
	for i in n_enemies:
		characters.push_back({
			'spawn':$GameMap.get_enemy_spawn_point(),
			'username': "Enemy",
			'obj_name': "Enemy" + str(i),
			'is_player': false
		})
	
	return characters


sync func _spawn_characters(characters) -> void:
	characters_playing = characters
	print("Instancing players")
	print(characters)
	for character in characters:
		_instance_character(character)
		
	# Unblock the screen
	startScreen.visible = false


func _instance_character(character: Dictionary) -> void:
	var player_instance = Global.instance_node_at(player_scene, PersistentNodes, character.spawn)
	print("Instancing Player: "+str(character.obj_name))
	if Global.is_multiplayer:
		player_instance.init(character.network_id, character.obj_name, character.is_player)
	else:
		player_instance.init(0, character.obj_name, character.is_player)
	
	player_instance.connect("player_died", self, "player_died")



func _spectate() -> void:
	is_spectating = false
	
	set_player_gui_enabled(false)
	
	for node in PersistentNodes.get_children():
		if node.is_in_group("player") and not node.ai_process:
			is_spectating = true
			node.set_camera_current(true)
			break
	
	if not is_spectating:
		_show_end_game_screen()


sync func _kill_player(obj_name: String) -> void:
	print("Killing player " + obj_name)
	if PersistentNodes.has_node(obj_name):
		PersistentNodes.get_node(obj_name).queue_free()
		for character in characters_playing:
			if character.obj_name == obj_name:
				characters_playing.erase(character)
	
	if Global.is_multiplayer:
		var characters_alive = 0
		for character in characters_playing:
			if character.is_player:
				characters_alive += 1

		if characters_alive <= 1:
			#TODO: Some fancy game over animation
			_show_end_game_screen()
	else:
		if characters_playing.size() <= 1:
			#TODO: Some fancy game over animation
			_show_end_game_screen()

func _show_end_game_screen() -> void:
	set_player_gui_enabled(false)
	winnerLabel.text = characters_playing[0].username + " won"
	endScreen.show()

func _exit_game() -> void:
	for node in PersistentNodes.get_children():
		node.queue_free()
	
	Network.refresh()
	
	Global.bullet_name_index = 0
	
	get_tree().change_scene("res://src/ui/menus/MainMenu.tscn")
	queue_free()

# Get map limit for the player to acces to control the camera
func get_map_limit() -> Vector2:
	return $GameMap.get_map_limit()

func set_player_gui_enabled(enabled: bool) -> void:
	if enabled:
		$PlayerControls.get_child(0).show()
		$PlayerControls.get_child(1).show()
		healthbar.get_child(0).show()
	else:
		$PlayerControls.get_child(0).hide()
		$PlayerControls.get_child(1).hide()
		healthbar.get_child(0).hide()
	
	$PlayerControls.get_child(0).set_process(enabled)
	$PlayerControls.get_child(1).set_process(enabled)


#### INTERNAL SIGNAL CONNECTIONS ####
func _on_CloseButton_pressed():
	# Hide Controls
	if not is_spectating:
		set_player_gui_enabled(false)
		
	
	# Show quitting panel
	closeButton.hide()
	escapePanel.show()


func _on_QuitButton_pressed():
	_exit_game()


func _on_ContinueButton_pressed():
	# Unhide Controls
	if not is_spectating:
		set_player_gui_enabled(true)
	
	# Show quitting panel
	closeButton.show()
	escapePanel.hide()

func player_died(obj_name: String) -> void:
	print("Player died: " + obj_name)
	
	if Global.is_multiplayer:
		var net_id = PersistentNodes.get_node(obj_name).network_id
		rpc("_kill_player", obj_name)
		
		if net_id == get_tree().get_network_unique_id() or is_spectating:
			_spectate()
	else:
		_kill_player(obj_name)


#### EXTERNAL SIGNAL CONNECTIONS ####
func _player_connected(id: int) -> void:
	if get_tree().is_network_server():
		Network.network.disconnect_peer(id, true)

func _player_disconnected(id: int) -> void:
	if PersistentNodes.has_node(str(id)):
		PersistentNodes.get_node(str(id)).queue_free()
	
	Network.connected_players.erase(id)
	for character in characters_playing:
		if character.network_id == id:
			characters_playing.erase(character)
	# TODO: Notify that this user has disconected

func _connection_failed() -> void:
	# TODO: Notify user that the server has been disconected
	_exit_game()
	pass

func _disconnected_from_server() -> void:
	# TODO: Notify user that the server has been disconected
	_exit_game()
	pass
