extends Node

# Diccionario de escenas con sus rutas
var scenes := {
	"test1": "res://Escenas/Tests/test1.tscn",
	"test2": "res://Escenas/Tests/test2.tscn",
	"test3": "res://Escenas/Tests/test3.tscn",
	"inicio": "res://Escenas/Places/inicio.tscn",
	"place1": "res://Escenas/Places/place1.tscn"
}

signal on_trigger_player_spawn
var spawn_trigger_tag

var previous_scene_tag := ""
var previous_spawn_tag := ""

func go_to_level(scene_tag,destination_tag):
	if scenes.has(scene_tag):
		var scene_to_load = load(scenes[scene_tag])
		if scene_to_load:
			TransitionScreen.transition()
			await TransitionScreen.on_transition_finished
			spawn_trigger_tag = destination_tag
			get_tree().call_deferred("change_scene_to_packed", scene_to_load)


func trigger_player_spawn(positions: Vector2, direction: String):
	on_trigger_player_spawn.emit(positions,direction)
