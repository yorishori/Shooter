# Script to make it easier to instance nodes.
# Global and autoloaded

extends Node

var bullet_name_index = 0
var is_multiplayer = false


# Player settings
var music = true
var sounds = true
var dark_game = true


func _ready() -> void:
	_load_player_settings()

# Instance a node into a parent
func instance_node(node : Object, parent : Object) -> Object:
	var node_instance = node.instance()
	parent.add_child(node_instance)
	return node_instance

# Instance a note into a parent at a given positions
func instance_node_at(node:Object, parent:Object, location:Vector2) -> Object:
	var node_instance = instance_node(node, parent)
	node_instance.global_position = location
	return node_instance
	
	

func _load_player_settings() -> void:
	var save_game = File.new()
	if not save_game.file_exists("user://user.data"):
		print("Save data doesn't exist")
		return
	
	save_game.open("user://user.data", File.READ)
	
	while save_game.get_position() < save_game.get_len():
		var data = parse_json(save_game.get_line())
		
		print("Loading settings: " + str(data))
		Network.username = data.username
		music = data.music
		sounds = data.sounds
		dark_game = data.dark_game
	
	save_game.close()
	
	

func _save_player_settings() -> void:
	var save_game = File.new()
	save_game.open("user://user.data", File.WRITE)
	
	var data = {
		"username": Network.username,
		"music": music,
		"sounds": sounds,
		"dark_game": dark_game
	}
	
	print("Saving settings: " + str(data))
	save_game.store_line(to_json(data))
	

func _exit_tree() -> void:
	_save_player_settings()
