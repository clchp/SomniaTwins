class_name TransitionTrigger extends Area2D

@export var destination_scene_tag: String
@export var destination_trigger_tag: String
@export var spawn_direction: String = "up"

@onready var spawn = $Spawn


func _on_body_entered(body):
	if body is Player:
		NavigationManager.go_to_level(destination_scene_tag,destination_trigger_tag)
