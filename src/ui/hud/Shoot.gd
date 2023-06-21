extends Control

signal shoot_pressed

# Scene nodes
onready var ShootFrame = $Shoot/ShootFrame

# Max distance of joystick detection
onready var shoot_detection_radius =  $Shoot/CollisionShape2D.shape.radius

# Pressed variables
var shoot_inputs = {}

func _input(event) -> void:
	if event is InputEventScreenTouch and event.pressed:		
		if event.position.distance_to(ShootFrame.global_position) <= shoot_detection_radius:
			shoot_inputs[event.index] = true
		else:
			shoot_inputs[event.index] = false
			
	elif event is InputEventScreenTouch:
		shoot_inputs[event.index] = false


func _process(_delta) -> void:	
	for index in shoot_inputs:
		if shoot_inputs[index]:
			_shoot_pressed(true)
			emit_signal("shoot_pressed")
		else:
			_shoot_pressed(false)
			

# Change color
func _shoot_pressed(is_pressed: bool) -> void:
	if is_pressed:
		ShootFrame.self_modulate.a = 1
	else:
		ShootFrame.self_modulate.a = 0.5
