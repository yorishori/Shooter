extends Node

# Scene nodes
@onready var playerControls = $PlayerControls
@onready var healthbar = $HealthBar
@onready var gameMap = $GameMap
@onready var closeButton = $EscapeScreen/CloseButton
@onready var escapePanel = $EscapeScreen/Panel
@onready var startScreen = $StartScreen
@onready var endScreen = $EndScreen
@onready var winnerLabel = $EndScreen/WinnerLabel
@onready var darkFilter = $NightFilter
# Loaded Scenes
var player_scene = load("res://game/Player.tscn")

# Varibles
var is_spectating = false
var players_playing = []
#[
#	{
#		network_id: int
#		username: String
#		spawn: Vector2
#	},...
#]

func _ready() -> void:
	# Enable Dark game
	if Global.dark_game:
		darkFilter.show()
	else:
		darkFilter.hide()
		
	print("Entering game. Multiplayer: "+str(Global.is_multiplayer))
	#Block the screen while instanciating
	startScreen.visible = true
	
	if Global.is_multiplayer:
		# When a device connects/disconnects from the network
		get_tree().connect("peer_connected",Callable(self,"_player_connected"))
		get_tree().connect("peer_disconnected",Callable(self,"_player_disconnected"))

		# When the device is Client
		get_tree().connect("connected_to_server",Callable(self,"_connected_to_server"))
		get_tree().connect("connection_failed",Callable(self,"_connection_failed"))
		get_tree().connect("server_disconnected",Callable(self,"_disconnected_from_server"))
		
		if get_tree().is_server():
			_assgin_spawn_points()
		
	else:
		print("Instancing player")
		_instance_player(get_tree().get_unique_id(), gameMap.get_player_spawn_point())
		startScreen.visible = false
	
	escapePanel.hide()
	endScreen.hide()
	closeButton.show()
	playerControls.get_child(0).show()
	playerControls.get_child(0).set_process(true)
	playerControls.get_child(1).show()
	playerControls.get_child(1).set_process(true)
	
	is_spectating = false

func _player_connected(id: int) -> void:
	if get_tree().is_server():
		Network.network.disconnect_peer(id, true)

func _player_disconnected(id: int) -> void:
	if PersistentNodes.has_node(str(id)):
		PersistentNodes.get_node(str(id)).queue_free()
	
	Network.connected_players.erase(id)
	for player in players_playing:
		if player.network_id == id:
			players_playing.erase(player)
	# TODO: Notify that this user has disconected

func _connection_failed() -> void:
	# TODO: Notify user that the server has been disconected
	_exit_game()
	pass

func _disconnected_from_server() -> void:
	# TODO: Notify user that the server has been disconected
	_exit_game()
	pass


func _assgin_spawn_points() -> void:
	print("Assigning spawn points...")
	for id in Network.connected_players:
		players_playing.push_back(Network.connected_players[id])
		players_playing[-1].spawn = gameMap.get_player_spawn_point()
	
	rpc("_spawn_players", players_playing)
	
	
@rpc("any_peer", "call_local") func _spawn_players(players) -> void:
	players_playing = players
	print("Instancing players")
	print(players_playing)
	for player in players_playing:
		_instance_player(player.network_id, player.spawn)
		
	# Unblock the screen
	startScreen.visible = false
	
	
	
@rpc("any_peer", "call_local") func _instance_player(id: int, spawn : Vector2) -> void:
	var player_instance = Global.instance_node_at(player_scene, PersistentNodes, spawn)
	print("Instancing Player: "+str(id))
	player_instance.init(id)
	player_instance.connect("player_died",Callable(self,"player_died"))


func player_died(player_id: int) -> void:
	print("Player died: " + str(player_id))
	if Global.is_multiplayer:
		rpc("_kill_player", player_id)
		
		if player_id == get_tree().get_unique_id() or is_spectating:
			_spectate()
	else:
		_kill_player(player_id)

func _spectate() -> void:
	is_spectating = false
	
	playerControls.get_child(0).hide()
	playerControls.get_child(0).set_process(false)
	
	
	for node in PersistentNodes.get_children():
		if node.is_in_group("player"):
			is_spectating = true
			node.set_camera_current(true)
			break
	
	if not is_spectating:
		_show_end_game_screen()


@rpc("any_peer", "call_local") func _kill_player(id: int) -> void:
	if PersistentNodes.has_node(str(id)):
		PersistentNodes.get_node(str(id)).queue_free()
		for player in players_playing:
			if player.network_id == id:
				players_playing.erase(player)
		
	if players_playing.size() <= 1:
		_show_end_game_screen()

func _show_end_game_screen() -> void:
	playerControls.get_child(0).hide()
	playerControls.get_child(0).set_process(false)
	winnerLabel.text = players_playing[0].username + " won"
	endScreen.show()




func _exit_game() -> void:
	for node in PersistentNodes.get_children():
		node.queue_free()
	
	Network.refresh()
	
	Global.bullet_name_index = 0
	
	get_tree().change_scene_to_file("res://ui/menus/MainMenu.tscn")
	queue_free()



func _on_CloseButton_pressed():
	# Hide Controls
	if not is_spectating:
		playerControls.get_child(0).hide()
		playerControls.get_child(0).set_process(false)
		playerControls.get_child(1).hide()
		playerControls.get_child(1).set_process(false)
	
		healthbar.get_child(0).hide()
	
	# Show quitting panel
	closeButton.hide()
	escapePanel.show()


func _on_QuitButton_pressed():
	_exit_game()


func _on_ContinueButton_pressed():
	# Unhide Controls
	if not is_spectating:
		playerControls.get_child(0).show()
		playerControls.get_child(0).set_process(true)
		playerControls.get_child(1).show()
		playerControls.get_child(1).set_process(true)
	
		healthbar.get_child(0).show()
	
	# Show quitting panel
	closeButton.show()
	escapePanel.hide()

# Get map limit for the player to acces to control the camera
func get_map_limit() -> Vector2:
	return gameMap.get_map_limit()
