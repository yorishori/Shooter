extends Control

signal joystick_pressed(velocity)


# Scene nodes
@onready var JoystickFrame = $Move/JoystickFrame
@onready var JoystickPoint = $Move/JoystickFrame/JoystickPoint



# Max distance of joystick detection
@onready var joystick_detection_radius = $Move/CollisionShape2D.shape.radius

# Pressed variables
var joystick_inputs = {}

func _input(event) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if event.position.distance_to(JoystickFrame.global_position) <= joystick_detection_radius:
			joystick_inputs[event.index] = true
		else:
			JoystickPoint.hide()
			joystick_inputs[event.index] = false
			
	elif event is InputEventScreenTouch:
		joystick_inputs[event.index] = false
	



func _process(_delta) -> void:
	for index in joystick_inputs:
		if joystick_inputs[index]:
			_joystick_pressed(true)
			var velocity = Vector2()
			velocity.x = JoystickPoint.position.x/joystick_detection_radius
			velocity.y = JoystickPoint.position.y/joystick_detection_radius
			
			emit_signal("joystick_pressed", velocity * 1.5)
			break
		else:
			_joystick_pressed(false)


# Change color and show/hide pointing circle
func _joystick_pressed(is_pressed: bool) -> void:
	if is_pressed:
		JoystickPoint.show()
		JoystickPoint.self_modulate.a = 1
		JoystickFrame.self_modulate.a = 1
		
		JoystickPoint.global_position = get_global_mouse_position()
		var center_position = JoystickFrame.position
		JoystickPoint.position = center_position + (JoystickPoint.position - center_position).limit_length(joystick_detection_radius)
	else:
		JoystickPoint.hide()
		JoystickPoint.self_modulate.a = 0.5
		JoystickFrame.self_modulate.a = 0.5
