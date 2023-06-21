extends Control

var game_title = "Angular Assault"


# Scene nodes
onready var titleLabel = $Title
onready var closeButton = $CloseButton

onready var startPanel = $StartScreen
onready var settingsPanel = $SettingsScreen
onready var gamePanel = $GameScreen
onready var creditsPanel = $CreditsScreen

onready var musicToggle = $SettingsScreen/MusicToggle
onready var soundToggle = $SettingsScreen/SoundToggle
onready var darkGameToggle = $SettingsScreen/DarkGameToggle


func _ready() -> void:
	startPanel.show()
	settingsPanel.hide()
	gamePanel.hide()
	creditsPanel.hide()
	closeButton.hide()
	
	titleLabel.text = game_title
	
	_set_settings_buttons()
	

func _on_Close_btn_pressed() -> void:
	get_tree().reload_current_scene()


##################
# Start Game Menu

func _on_Start_btn_pressed():
	startPanel.hide()
	gamePanel.show()
	closeButton.show()
	
	titleLabel.text = game_title

func _on_Multi_btn_pressed():
	Global.is_multiplayer = true
	get_tree().change_scene("res://src/ui/menus/MultiplayerMenu.tscn")
	queue_free()


func _on_Single_btn_pressed():
	Global.is_multiplayer = false
	get_tree().change_scene("res://src/ui/Game.tscn")
	queue_free()




##################
# Settings Menu

# Function to set the options from previous session
func _set_settings_buttons() -> void:
	musicToggle.pressed = Global.music
	soundToggle.pressed = Global.sounds
	darkGameToggle.pressed = Global.dark_game
	
	_toggle_button_color(musicToggle)
	_toggle_button_color(soundToggle)
	_toggle_button_color(darkGameToggle)

func _on_Settings_btn_pressed():
	startPanel.hide()
	settingsPanel.show()
	closeButton.show()
	
	titleLabel.text = "Settings"

func _on_MusicToggle_toggled(button_pressed):
	Global.music = button_pressed
	Global._save_player_settings()
	_toggle_button_color(musicToggle)


func _on_SoundToggle_toggled(button_pressed):
	Global.sounds = button_pressed
	Global._save_player_settings()
	_toggle_button_color(soundToggle)


func _on_DarkGameToggle_toggled(button_pressed):
	Global.dark_game = button_pressed
	Global._save_player_settings()
	_toggle_button_color(darkGameToggle)

# Visual representation of the state of the option
func _toggle_button_color(button_node) -> void:
	if button_node.pressed:
		button_node.self_modulate.r = 1
		button_node.self_modulate.g = 1.5
		button_node.self_modulate.b = 1
		button_node.add_stylebox_override("hover", button_node.get_stylebox("pressed"))
	else:
		button_node.self_modulate.r = 1.5
		button_node.self_modulate.g = 1
		button_node.self_modulate.b = 1
		button_node.add_stylebox_override("hover", button_node.get_stylebox("normal"))




##################
# Credits Menu

func _on_Credits_btn_pressed():
	startPanel.hide()
	creditsPanel.show()
	closeButton.show()
	titleLabel.text = "Credits"

