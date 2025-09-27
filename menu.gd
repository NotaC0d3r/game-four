extends Control
var has_ran = false
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_help_pressed() -> void:
	get_tree().change_scene_to_file("res://options_menu.tscn")

func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://controls_menu.tscn")
