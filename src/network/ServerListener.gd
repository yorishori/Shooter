extends Node

signal new_server
signal remove_server

var socket_upd = PacketPeerUDP.new()
var listen_port = Network.DEFAULT_PORT
var known_servers = {}

# Max time a server can be without broadcasting before it's removed
var cleanup_interval = 3

# Nodes from scene
onready var cleanUpTimer = $CleanUpTimer


func _ready() -> void:
	known_servers.clear()
	
	if socket_upd.listen(listen_port) != OK:
		socket_upd.listen(listen_port)
		print("Server Error: Failed to listen on port: "+str(listen_port))
	else:
		print("Listener Enabled")


func _process(_delta) -> void:
	if socket_upd.get_available_packet_count() > 0:
		print("Recieving UDP Packets")
		var server_ip = socket_upd.get_packet_ip()
		var server_port = socket_upd.get_packet_port()
		var byte_array = socket_upd.get_packet()
		
		if server_ip != "" and server_port > 0:
			if not known_servers.has(server_ip):
				print("IP found: " + server_ip)
				
				var server_message = byte_array.get_string_from_utf8()
				var server_info = parse_json(server_message)
				server_info.ip = server_ip
				server_info.last_seen = OS.get_unix_time()
				known_servers[server_ip] = server_info
				emit_signal("new_server", server_info)
			else:
				# Update last seen time
				print("IP found: " + server_ip)
				var server_info = known_servers[server_ip]
				server_info.last_seen = OS.get_unix_time()


func _on_CleanUpTimer_timeout():
	var now = OS.get_unix_time()
	
	for server_ip in known_servers:
		var server_info = known_servers[server_ip]
		if(now - server_info.last_seen) > cleanup_interval:
			known_servers.erase(server_ip)
			emit_signal("remove_server", server_ip)


func _exit_tree() -> void:
	print("Disabling Listener")
	cleanUpTimer.stop()
	if socket_upd != null:
		socket_upd.close()



