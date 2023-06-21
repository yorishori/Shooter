extends Control

# String variables
const GAME_TITLE = "Title of the game"


# Scene nodes
@onready var closeButton = $CloseButton
@onready var titleLabel = $Title

@onready var startPanel = $StartScreen
@onready var settingsPanel = $SettingsScreen
@onready var gamePanel = $GameScreen
@onready var creditsPanel = $CreditsScreen

@onready var musicToggle = $SettingsScreen/MusicToggle
@onready var soundToggle = $SettingsScreen/SoundToggle
@onready var darkGameToggle = $SettingsScreen/DarkGameToggle


func _ready() -> void:
	startPanel.show()
	settingsPanel.hide()
	gamePanel.hide()
	creditsPanel.hide()
	closeButton.hide()
	
	titleLabel.text = GAME_TITLE
	
	#_set_settings_buttons()
	
	
	
func _set_settings_buttons() -> void:
	musicToggle.button_pressed = Global.music
	soundToggle.button_pressed = Global.sounds
	darkGameToggle.button_pressed = Global.dark_game
	
	if Global.music:
		musicToggle.add_theme_stylebox_override("hover", musicToggle.get_stylebox("pressed"))
	else:
		musicToggle.add_theme_stylebox_override("hover", musicToggle.get_stylebox("normal"))
	
	if Global.sounds:
		soundToggle.add_theme_stylebox_override("hover", soundToggle.get_stylebox("pressed"))
	else:
		soundToggle.add_theme_stylebox_override("hover", soundToggle.get_stylebox("normal"))
	
	if Global.dark_game:
		darkGameToggle.add_theme_stylebox_override("hover", darkGameToggle.get_stylebox("pressed"))
	else:
		darkGameToggle.add_theme_stylebox_override("hover", darkGameToggle.get_stylebox("normal"))


func _on_Close_btn_pressed() -> void:
	get_tree().reload_current_scene()


func _on_Start_btn_pressed():
	startPanel.hide()
	gamePanel.show()
	closeButton.show()
	
	titleLabel.text = GAME_TITLE

func _on_Multi_btn_pressed():
	Global.is_multiplayer = true
	get_tree().change_scene_to_file("res://ui/menus/MultiplayerMenu.tscn")
	queue_free()


func _on_Single_btn_pressed():
	Global.is_multiplayer = false
	get_tree().change_scene_to_file("res://ui/Game.tscn")
	queue_free()



func _on_Settings_btn_pressed():
	startPanel.hide()
	settingsPanel.show()
	closeButton.show()
	
	titleLabel.text = "Settings"


func _on_Credits_btn_pressed():
	startPanel.hide()
	creditsPanel.show()
	closeButton.show()
	titleLabel.text = "Credits"





func _on_MusicToggle_toggled(button_pressed):
	Global.music = button_pressed
	Global._save_player_settings()
	if button_pressed:
		musicToggle.self_modulate.r = 1
		musicToggle.self_modulate.g = 1.5
		musicToggle.add_theme_stylebox_override("hover", musicToggle.get_stylebox("pressed"))
	else:
		musicToggle.self_modulate.r = 1.5
		musicToggle.self_modulate.g = 1
		musicToggle.add_theme_stylebox_override("hover", musicToggle.get_stylebox("normal"))
		


func _on_SoundToggle_toggled(button_pressed):
	Global.sounds = button_pressed
	Global._save_player_settings()
	if button_pressed:
		soundToggle.self_modulate.r = 1
		soundToggle.self_modulate.g = 1.5
		soundToggle.add_theme_stylebox_override("hover", soundToggle.get_stylebox("pressed"))
	else:
		soundToggle.self_modulate.r = 1.5
		soundToggle.self_modulate.g = 1
		soundToggle.add_theme_stylebox_override("hover", soundToggle.get_stylebox("normal"))


func _on_DarkGameToggle_toggled(button_pressed):
	Global.dark_game = button_pressed
	Global._save_player_settings()
	if button_pressed:
		darkGameToggle.self_modulate.r = 1
		darkGameToggle.self_modulate.g = 1.5
		darkGameToggle.add_theme_stylebox_override("hover", darkGameToggle.get_stylebox("pressed"))
	else:
		darkGameToggle.self_modulate.r = 1.5
		darkGameToggle.self_modulate.g = 1
		darkGameToggle.add_theme_stylebox_override("hover", darkGameToggle.get_stylebox("normal"))
