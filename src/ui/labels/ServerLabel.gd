extends Label

signal join_pressed(ip)

var ip = ""
var server_name = "" setget _set_name


func _set_name(new_name):
	text = new_name + "'s game"


func _on_Join_pressed():
	emit_signal("join_pressed", ip)
