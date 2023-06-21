extends Control



# Nodes of the scene
onready var inputPanel = $InputScreen
onready var userInput = $InputScreen/UserInput

onready var browserPanel = $BrowserScreen
onready var serverContainer = $BrowserScreen/ScrollContainer/ServerContainer

onready var manualPanel = $ManualConnection
onready var manualInput = $ManualConnection/UserInput

onready var lobbyPanel = $LobbyScreen
onready var startButton = $LobbyScreen/StartButton
onready var playersContainer = $LobbyScreen/ScrollContainer/PlayersContainer
onready var ipLabel = $LobbyScreen/IP


# Loaded Scenes
var server_listener = load("res://src/network/ServerListener.tscn")
var server_advertiser = load("res://src/network/ServerAdvertiser.tscn")
var server_label = load("res://src/ui/labels/ServerLabel.tscn")
var player_label = load("res://src/ui/labels/PlayerLabel.tscn")

var advertiser_instance = null
var listener_instance = null
var first_screen = true

func _ready() -> void:
	print("Multiplayer Menu ready")
	Network.refresh()
	# When a device connects/disconnects from the network
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

	# When the device is Client
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("server_disconnected", self, "_disconnected_from_server")
	
	first_screen = true
	inputPanel.show()
	browserPanel.hide()
	lobbyPanel.hide()
	manualPanel.hide()
	
	if Network.username:
		userInput.text = Network.username


func _player_disconnected(id) -> void:
	if get_tree().is_network_server():
		print("Player disconnected: " + str(Network.connected_players[id]))
		Network.connected_players.erase(id)
		rpc("_update_player_list", Network.connected_players)
		
		if Network.connected_players.size()>1:
			startButton.show()
		else:
			startButton.hide()


func _connected_to_server() -> void:
	print("Device connected to server.")
	
	var player = {}
	player.network_id = get_tree().get_network_unique_id()
	player.username = Network.username
	print("Sending info: " + str(player))
	rpc_id(1, "_add_player", player)

	browserPanel.hide()
	manualPanel.hide()
	lobbyPanel.show()
	startButton.hide()
	ipLabel.hide()

func _connection_failed() -> void:
	#TODO: Notify player
	print("Device connection to server failed.")
	_on_Close_btn_pressed()

func _disconnected_from_server() -> void:
	#TODO: Notify player
	print("Device disconnected from server.")
	_on_Close_btn_pressed()


func _on_Close_btn_pressed():
	if first_screen:
		get_tree().change_scene("res://src/ui/menus/MainMenu.tscn")
		queue_free()
	else:
		# Disable listners if necessary
		if listener_instance:
			listener_instance.queue_free()
		if advertiser_instance:
			advertiser_instance.queue_free()
		
		get_tree().reload_current_scene()



func _on_Create_btn_pressed():
	if userInput.text.strip_edges().length() >= 3:
		first_screen = false
		
		Network.username = userInput.text

		if not Network.create_server():
			_on_Close_btn_pressed()
			return
		
		
		# Set-up server advertiser
		advertiser_instance = Global.instance_node(server_advertiser, self)
		inputPanel.hide()
		lobbyPanel.show()
		
		if Network.connected_players.size() > 1:
			startButton.show()
		else:
			startButton.hide()
		
		ipLabel.show()
		ipLabel.text = Network.ip
		
		# Add host to players list and update network
		var player = {}
		player.network_id = get_tree().get_network_unique_id()
		player.username = Network.username
		print("Creating server player: " + str(player))
		_add_player(player)


func _on_Join_btn_pressed():
	if userInput.text.strip_edges().length() >= 3:
		first_screen = false
		Network.username = userInput.text
		
		inputPanel.hide()
		browserPanel.show()
		
		listener_instance = Global.instance_node(server_listener, self)
		listener_instance.connect("new_server", self, "_new_server_found")
		listener_instance.connect("remove_server", self, "_server_removed")

# Server Listener Signals
func _new_server_found(server_info):
	var instance = Global.instance_node(server_label, serverContainer)
	instance.server_name = server_info.name
	instance.ip = server_info.ip
	instance.connect("join_pressed", self, "_server_join_pressed")

func _server_join_pressed(ip) -> void:
	Network.ip = ip
	# Disable Listener
	if listener_instance != null:
		listener_instance.queue_free()
	
	if not Network.join_server():
		_on_Close_btn_pressed()

func _server_removed(ip):
	# Match server and remove from list
	for node in serverContainer.get_children():
		if node.is_in_group("ServerLabel") and node.ip == ip:
			node.queue_free()
			break


func _on_Manual_btn_pressed():
	first_screen = false
	
	browserPanel.hide()
	manualPanel.show()
	manualInput.text = str(Network.ip)

func _on_ManualJoin_btn_pressed():
	if manualInput.text.strip_edges().length() > 0:
		Network.ip = manualInput.text
		
		# Disable Listener
		if listener_instance != null:
			listener_instance.queue_free()
			
		if not Network.join_server():
			_on_Close_btn_pressed()

func _on_Start_btn_pressed():
	rpc("_start_game")

sync func _start_game():
	get_tree().change_scene("res://src/ui/Game.tscn")
	queue_free()


# Remote Functions
sync func _update_player_list(new_players) -> void:
	print("Updating players list: "+str(new_players))
	
	for node in playersContainer.get_children():
		if node.is_class("Label"):
			node.queue_free()
	
	for id in new_players:
		var instance = Global.instance_node(player_label, playersContainer)
		instance.text = new_players[id].username
	
	Network.connected_players = new_players

# Server only function to update the players list and send the signal to 
remote func _add_player(player) -> void:
	print("Is network server: " + str(get_tree().is_network_server()))
	print(Network.connected_players)
	if get_tree().is_network_server():
		if not Network.connected_players.has(player.network_id):
			print("Adding player: "+str(player))
			Network.connected_players[player.network_id] = player
			rpc("_update_player_list", Network.connected_players)
			
			if Network.connected_players.size()>1:
				startButton.show()
			else:
				startButton.hide()



