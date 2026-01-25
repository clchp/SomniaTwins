extends Node2D

@export var track:String

func _ready():
	AudioPlayer.play_music_level(track)
	if NavigationManager.spawn_trigger_tag != null:
		_on_scene_spawn(NavigationManager.spawn_trigger_tag)
		
func _on_scene_spawn(destination_tag: String):
	var trigger_path:String  = "Transicion/Trigger" + destination_tag
	var trigger = get_node(trigger_path) as TransitionTrigger
	NavigationManager.trigger_player_spawn(trigger.spawn.global_position, trigger.spawn_direction)
