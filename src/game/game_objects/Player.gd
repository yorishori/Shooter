extends KinematicBody2D

signal player_died(player_id)

# Characteristics of the player
var MAX_HEALTH = 100
var speed = 500
var health = MAX_HEALTH

# Nodes of this scene
onready var tween = $Tween	# Used to animate the players movement (multiplayer)
onready var shootPoint = $Shootpoint
onready var sprite = $Sprite
onready var camera = $Camera2D
onready var light = $Light2D

onready var networkTimer = $NetworkTickRate
onready var reloadTimer = $ReloadTimer

# Loaded Scenes
var bullet_scene = load("res://src/game/game_objects/Bullet.tscn")

# Puppet variables
puppet var puppet_position = Vector2.ZERO setget puppet_position_set
puppet var puppet_velocity = Vector2.ZERO
puppet var puppet_rotation = 0

# Control Varaibles
var is_reloading = false
var controls
var healthbar
var network_id:int

# AI Enemy variables
var ai_process


func _ready() -> void:
	# Connect Network timer if we are in multiplayer
	if Global.is_multiplayer:
		networkTimer.connect("timeout",self, "_on_NetworkTickRate_timeout")
	
	# Set the camera limits
	var map_limit = get_tree().current_scene.get_map_limit()
	print(map_limit)
	camera.limit_bottom = map_limit.y
	camera.limit_right = map_limit.x


func init(net_id: int, obj_name: String, is_player:bool) -> void:
	name = obj_name
	if(Global.is_multiplayer):
		set_network_master(net_id)
	
	network_id = net_id
	
	if is_player and (not Global.is_multiplayer or is_network_master()):
		# Assign camera and controls to this player
		set_player_controls()
		set_camera_current(true)
		
		# Change player color
		sprite.self_modulate = Color(1.0, 1.5, 1.0)
	else:
		set_camera_current(false)
		sprite.self_modulate = Color(1.5, 1.0, 1.0)
		
	ai_process = not is_player

func set_player_controls() -> void:
	# Get the hud and healthbar from the main scene
	for node in get_tree().current_scene.get_children():
		if node.is_in_group("controls"):
			controls = node
		if node.is_in_group("healthbar"):
			healthbar = node
	
	controls.connect("player_moved", self, "_move")
	controls.connect("player_shoot", self, "_shoot")

func set_camera_current(set: bool) -> void:
	camera.current = set
	light.enabled = set

# When the player moves
func _move(velocity):
	move_and_slide(velocity * speed)
	self.rotation = velocity.angle()

# When the player shoots
func _shoot():
	if not is_reloading:
		var id = get_tree().get_network_unique_id()
		var bullet_name = "Bullet"+str(id)+str(Global.bullet_name_index)
		
		# Since a bullet was created, change local index
		Global.bullet_name_index += 1
		
		# Instance the bullet with unique name and player id
		if not Global.is_multiplayer:
			_instance_bullet(id, bullet_name)
		elif is_network_master():
			rpc("_instance_bullet", id, bullet_name)
		
		# Start reloading
		is_reloading = true
		reloadTimer.start()

# Timer to limit bullet rate
func _on_ReloadTimer_timeout():
	is_reloading = false


sync func _instance_bullet(id, bulllet_name) -> void:
	var bullet_instance = Global.instance_node_at(bullet_scene, PersistentNodes, shootPoint.global_position)
	bullet_instance.init(bulllet_name, self.rotation, id)



func _process(delta) -> void:
	# Only move the puppet in the process function
	if Global.is_multiplayer and not is_network_master():
		self.rotation = lerp_angle(rotation, puppet_rotation, delta * 8)
	
		# If packet hasn't been recieved, keep moving in the same direction
		if not tween.is_active():
			move_and_slide(puppet_velocity * speed)
	
	if ai_process and (not Global.is_multiplayer or is_network_master()):
		# Process ai stuff
		pass
	


# Function to set the puppet's position (called by rset, when its modifying the position)
func puppet_position_set(new_position):
	puppet_position = new_position
	
	# Animate the players position to compensate for lag
	tween.interpolate_property(self, "global_position", self.global_position, puppet_position, 0.1)
	tween.start()


# Send out this player's position to the other players puppets of this
func _on_NetworkTickRate_timeout():
	if is_network_master():
		rset_unreliable("puppet_position", self.global_position)
		rset_unreliable("puppet_rotation", self.rotation)



func take_damage(amount) -> void:
	if not Global.is_multiplayer or is_network_master():
		health -= amount
		
		if not ai_process:
			healthbar.get_child(0).value = health
		
		print(name + "'s health: " + str(health))
		if health <= 0:
			emit_signal("player_died", name)
		
