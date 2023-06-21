extends CanvasLayer

signal player_moved(velocity)
signal player_shoot

func _ready() -> void:
	$Move.connect("joystick_pressed", self, "_joystick_pressed")
	$Shoot.connect("shoot_pressed", self, "_shoot_pressed")


func _joystick_pressed(velocity):
	emit_signal("player_moved", velocity)


func _shoot_pressed():
	emit_signal("player_shoot")
