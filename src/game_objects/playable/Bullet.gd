extends Node2D

# Bullet characteristics
var speed = 2000
var velocity = Vector2.RIGHT
var bullet_damage = 25

var player_rotation
var owner_id = 0

# Puppet Variables
puppet var puppet_position : set = _set_puppet_position
puppet var puppet_velocity = Vector2.ZERO
puppet var puppet_rotation = 0



func init(bullet_name: String, initial_rotation: float, bullet_owner_id: int) -> void:
	name = bullet_name
	player_rotation = initial_rotation
	owner_id = bullet_owner_id
	
	if Global.is_multiplayer:
		set_multiplayer_authority(bullet_owner_id)
		


func _ready() -> void:
	self.visible = false
	await get_tree().idle_frame
	
	if not Global.is_multiplayer or is_multiplayer_authority():
		velocity = velocity.rotated(player_rotation)
		rotation = player_rotation
		
		if Global.is_multiplayer:
			rset_unreliable("puppet_position", global_position)
			rset_unreliable("puppet_velocity", velocity)
			rset_unreliable("puppet_rotation", rotation)
		
	visible = true


func _set_puppet_position(new_puppet_position) -> void:
	puppet_position = new_puppet_position
	global_position = puppet_position


func _process(delta) -> void:
	if not Global.is_multiplayer or is_multiplayer_authority():
		global_position += velocity * speed * delta
	else:
		global_position += puppet_velocity * speed * delta
		rotation = puppet_rotation




# Destroy bullet after some time withouth collision
func _on_DestroyTimer_timeout():
	if Global.is_multiplayer and is_multiplayer_authority():
		rpc("_destroy")
	elif not Global.is_multiplayer:
		_destroy()


# Destroy when it hits an object
func _on_Hitbox_body_entered(body):
	if body.name != str(owner_id) and (not Global.is_multiplayer or is_multiplayer_authority()):
		# Deal damage if player
		if body.is_in_group("player"):
			if Global.is_multiplayer:
				rpc_id(body.network_id, "_damage_player", bullet_damage)
			else:
				body.take_damage(bullet_damage) 
			
		# Destroy bullet
		if Global.is_multiplayer and is_multiplayer_authority():
			rpc("_destroy")
		elif not Global.is_multiplayer:
			_destroy()

@rpc("any_peer", "call_local") func _damage_player(bullet_damage) -> void:
	PersistentNodes.get_node(str(get_tree().get_unique_id())).take_damage(bullet_damage)

 
@rpc("any_peer", "call_local") func _destroy() -> void:
	queue_free()

