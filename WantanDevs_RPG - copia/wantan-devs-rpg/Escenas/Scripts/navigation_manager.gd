extends Node

const scene_test1 = preload("res://Escenas/Tests/test1.tscn")
const scene_test2 = preload("res://Escenas/Tests/test2.tscn")
const scene_test3 = preload("res://Escenas/Tests/test3.tscn")

signal on_trigger_player_spawn

var spawn_trigger_tag

func go_to_level(scene_tag,destination_tag):
	var scene_to_load
	
	match scene_tag:
		"test1":
			scene_to_load = scene_test1
		"test2":
			scene_to_load = scene_test2
		"test3":
			scene_to_load = scene_test3	
		
	if scene_to_load != null:
		TransitionScreen.transition()
		await TransitionScreen.on_transition_finished
		spawn_trigger_tag = destination_tag
		get_tree().call_deferred("change_scene_to_packed",scene_to_load)

func trigger_player_spawn(positions: Vector2, direction: String):
	on_trigger_player_spawn.emit(positions,direction)
