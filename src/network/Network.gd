# Script that manages network connections.
# Global and autoloaded
extends Node

# Used port
const DEFAULT_PORT = 30100
# Max number of players connected to server
const MAX_CLIENTS = 6


# Varibles for the server and client (when it applies)
var network = null

# IP Address of this machine
var ip = ""
var username = "" : set = _set_username

# Connected players
var connected_players = {}
#{
#	network_id:{
#		id: network_id
#		username: player_username
#	}
#}


func _ready() -> void:
	print("Network ready")
	refresh()


func refresh() -> void:
	# We get the IP Address from this device
	#	Depending on the OS, it's in a different location
	if OS.get_name() == "Windows":
		ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	elif OS.get_name() == "Android":
		ip = IP.get_local_addresses()[0]
	else:
		ip = IP.get_local_addresses()[3]
	#print(IP.get_local_addresses())
	
	connected_players.clear()
	
	if network:
		print("Closing Connection (Refresh)")
		network.close_connection()
	


# Function to create a server and assign it to this device
func create_server() -> bool:
	if network:
		print("Closing Connection (New server)")
		network.close_connection()
	
	network = ENetMultiplayerPeer.new()
	if network.create_server(DEFAULT_PORT, MAX_CLIENTS) != OK:
		print("Error creating server.")
		return false
	
	get_tree().set_multiplayer_peer(network)
	
	
	network.connect("peer_connected",Callable(self,"_peer_connected"))
	network.connect("peer_disconnected",Callable(self,"_peer_disconnected"))
	
	print("Server Created.")
	return true


# Function to join a server from this deveice to another
func join_server() -> bool:
	if network:
		print("Closing Connection (New Client)")
		network.close_connection()
	
	network = ENetMultiplayerPeer.new()
	if network.create_client(ip, DEFAULT_PORT) != OK:
		return false
	get_tree().set_multiplayer_peer(network)
	
	print("Joinded Server: "+ip)
	return true

func _peer_connected(id) -> void:
	print("Network: " + str(id) + " connected.")

func _peer_disconnected(id) -> void:
	print("Network: " + str(id) + " disconnected.")


func _set_username(new_username: String) -> void:
	username = new_username
	Global._save_player_settings()
