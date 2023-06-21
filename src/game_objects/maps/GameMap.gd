extends Node2D

var player_spawn_points = []
var enemy_spawn_points = []
var health_spawn_points = []

func _ready():
	randomize()
	
	for node in get_children():
		if node.is_in_group("playerSpawn"):
			player_spawn_points.append(node.position)
		elif node.is_in_group("enemySpawn"):
			enemy_spawn_points.append(node.position)
		elif node.is_in_group("healthSpawn"):
			health_spawn_points.append(node.position) 


func get_player_spawn_point() -> Vector2:
	return player_spawn_points[randi() % player_spawn_points.size()]

func get_enemy_spawn_point() -> Vector2:
	return enemy_spawn_points[randi() % enemy_spawn_points.size()]

func get_health_spawn_point() -> Vector2:
	return health_spawn_points[randi() % health_spawn_points.size()]

func get_map_limit() -> Vector2:
	var used_cells = $Walls.get_used_cells()
	var pos_max = Vector2.ZERO
	
	for pos in used_cells:
		if pos.x * 64 > pos_max.x:
			pos_max.x = int(pos.x * 64)
		if pos.y * 64 > pos_max.y:
			pos_max.y = int(pos.y * 64)
	
	return pos_max
