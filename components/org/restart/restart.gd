extends Node

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed \
     and InputMap.event_is_action(event, "switch_angle") \
     and not event.echo:
        get_tree().paused = false
        get_tree().reload_current_scene()