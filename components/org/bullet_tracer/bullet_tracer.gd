extends Node

@export var laser: Area2D 
@export var light_pass: Node2D

var current_path: Array[Vector2] = []
const LASER_SPEED: float = 400

func _physics_process(delta: float) -> void:
    if not is_active:
        return
    
    for area in laser.get_overlapping_areas():
        area.queue_free()
    _update_laser_pos(LASER_SPEED*delta)
    if len(current_path) < 2:
        _on_laser_finished()
    
func _update_laser_pos(distance_to_travel: float) -> void:
    if len(current_path) < 2:
        return
    
    var current_pos: Vector2 = laser.global_position
    while distance_to_travel > 0 and len(current_path) >= 2:
        var current_start: Vector2 = current_path[0]
        var current_end: Vector2 = current_path[1]
        
        var line_vec: Vector2 = current_end - current_start
        var line_len: float = line_vec.length()
        if line_len == 0.0:
            return
        
        var dir: Vector2 = line_vec.normalized()
        var current_traveled: float = (current_pos - current_start).dot(dir)
        
        if line_len-current_traveled <= distance_to_travel:
            current_pos = current_end
            distance_to_travel -= line_len-current_traveled
            current_path.pop_front()
        else:
            current_pos = current_start + dir * (current_traveled + distance_to_travel)
            distance_to_travel = 0
    
    laser.global_position = current_pos
    light_pass.global_position.x = current_pos.x
    
###
### Hooks
###
var is_active: bool = false
var on_finish_callback: Callable
func start_laser(path: Array[Vector2], callback: Callable) -> void:
    laser.global_position = path[0]
    light_pass.global_position.x = laser.global_position.x
    laser.visible = true
    light_pass.visible = true
    light_pass.modulate = Color.WHITE
    is_active = true
    current_path = path
    on_finish_callback = callback
    
const LIGHT_FADE_SPEED: float = 0.2
func _on_laser_finished() -> void:
    if not is_active:
        return
    is_active = false
    
    on_finish_callback.call()
    laser.visible = false
    current_path = []
    
    var tween: Tween = get_tree().create_tween().bind_node(light_pass)
    tween.tween_property(light_pass, "modulate", Color.TRANSPARENT, LIGHT_FADE_SPEED)
    