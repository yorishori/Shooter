extends CharacterBody2D

signal player_died(player_id)

# Characteristics of the player
const MAX_HEALTH = 100
var speed = 500
var health = 100

# Nodes of this scene
@onready var tween = $Tween	# Used to animate the players movement (multiplayer)
@onready var shootPoint = $Shootpoint
@onready var sprite = $Sprite2D
@onready var camera = $Camera2D
@onready var light = $PointLight2D

@onready var networkTimer = $NetworkTickRate
@onready var reloadTimer = $ReloadTimer

# Loaded Scenes
var bullet_scene = load("res://game/Bullet.tscn")

# Puppet variables
puppet var puppet_position = Vector2.ZERO : set = puppet_position_set
puppet var puppet_velocity = Vector2.ZERO
puppet var puppet_rotation = 0

# Control Varaibles
var is_reloading = false
var controls
var healthbar
var network_id


func _ready() -> void:
	# Connect Network timer if we are in multiplayer
	if Global.is_multiplayer:
		networkTimer.connect("timeout",Callable(self,"_on_NetworkTickRate_timeout"))
	
	# Set the camera limits
	var map_limit = get_tree().current_scene.get_map_limit()
	print(map_limit)
	camera.limit_bottom = map_limit.y
	camera.limit_right = map_limit.x

func init(id: int) -> void:
	name = str(id)
	set_multiplayer_authority(id)
	network_id = id
	
	# Get the hud and healthbar from the main scene
	for node in get_tree().current_scene.get_children():
		if node.is_in_group("controls"):
			controls = node
		if node.is_in_group("healthbar"):
			healthbar = node
	
	# Connect/Disconnect controls from the players and change their colors
	if not Global.is_multiplayer or is_multiplayer_authority():
		controls.connect("player_moved",Callable(self,"_move"))
		controls.connect("player_shoot",Callable(self,"_shoot"))
		sprite.self_modulate.r = 1
		sprite.self_modulate.g = 1.5
		sprite.self_modulate.b = 1
		set_camera_current(true)
	else:
		sprite.self_modulate.r = 1.5
		sprite.self_modulate.g = 1
		sprite.self_modulate.b = 1
		set_camera_current(false)

func set_camera_current(set: bool) -> void:
	camera.current = set
	light.enabled = set

# When the player moves
func _move(velocity):
	set_velocity(velocity * speed)
	move_and_slide()
	self.rotation = velocity.angle()

# When the player shoots
func _shoot():
	if not is_reloading:
		var id = get_tree().get_unique_id()
		var bullet_name = "Bullet"+str(id)+str(Global.bullet_name_index)
		
		# Instance the bullet with unique name and player id
		if not Global.is_multiplayer:
			_instance_bullet(id, bullet_name)
		elif is_multiplayer_authority():
			rpc("_instance_bullet", id, bullet_name)
		
		# Start reloading
		is_reloading = true
		reloadTimer.start()

# Timer to limit bullet rate
func _on_ReloadTimer_timeout():
	is_reloading = false


@rpc("any_peer", "call_local") func _instance_bullet(id, bulllet_name) -> void:
	var bullet_instance = Global.instance_node_at(bullet_scene, PersistentNodes, shootPoint.global_position)
	bullet_instance.init(bulllet_name, self.rotation, id)
	
	# Since a bullet was created, change the index
	Global.bullet_name_index += 1


func _process(delta) -> void:
	# Only move the puppet in the process function
	if Global.is_multiplayer and not is_multiplayer_authority():
		self.rotation = lerp_angle(rotation, puppet_rotation, delta * 8)
	
		# If packet hasn't been recieved, keep moving in the same direction
		if not tween.is_active():
			set_velocity(puppet_velocity * speed)
			move_and_slide()


# Function to set the puppet's position (called by rset, when its modifying the position)
func puppet_position_set(new_position):
	puppet_position = new_position
	
	# Animate the players position to compensate for lag
	tween.interpolate_property(self, "global_position", self.global_position, puppet_position, 0.1)
	tween.start()


# Send out this player's position to the other players puppets of this
func _on_NetworkTickRate_timeout():
	if is_multiplayer_authority():
		rset_unreliable("puppet_position", self.global_position)
		rset_unreliable("puppet_rotation", self.rotation)



func take_damage(amount) -> void:
	if not Global.is_multiplayer or is_multiplayer_authority():
		health -= amount
		
		healthbar.get_child(0).value = health
		if health <= 0:
			emit_signal("player_died", network_id)
		
