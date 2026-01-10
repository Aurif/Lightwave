extends Node

@export var speed: float = 0.1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    var parent: Node2D = get_parent()
    parent.rotate(speed*delta)
