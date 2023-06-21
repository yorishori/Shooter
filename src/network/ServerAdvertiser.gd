extends Node

# Timer to broadcast this server's presence
var broadcast_timer = Timer.new()

var socket_upd
var broadcast_ip = "255.255.255.255"
var broadcast_port = Network.DEFAULT_PORT
var server_info = {"name": "LAN Game"}


# Nodes in scene
@onready var broadcastTimer = $BroadcastTimer

# Interval at which broadcasted packets are sent
var broadcast_interval = 1.0

func _ready() -> void:
	if get_tree().is_server():
		print("Advertiser Active")
		socket_upd = PacketPeerUDP.new()
		socket_upd.set_broadcast_enabled(true)
		socket_upd.set_dest_address(broadcast_ip, broadcast_port)


func _on_BroadcastTimer_timeout():
	server_info.name = Network.username
	var packet_message = JSON.new().stringify(server_info)
	socket_upd.put_packet(packet_message.to_utf8_buffer())


func _exit_tree() -> void:
	print("Disabling Advertiser")
	broadcast_timer.stop()
	if socket_upd != null:
		socket_upd.close()



