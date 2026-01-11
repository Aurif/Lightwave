extends Node

@export var enemy_prefab: PackedScene
@export var max_size: Vector2i
@export var tick_on_start: bool = true

var enemy_map: Dictionary[Vector2i, Node2D] = {}
const MOVE_DISTANCE: int = 4

signal AfterTick


# TODO: Ramping wave difficulty
# TODO: More enemy types
# TODO: Some upgrades for kills
# TODO: Way to win / final sequence
# TODO: Ability to restart game after losing
func _ready() -> void:
    if tick_on_start:
        tick_enemies.call_deferred(true)

func tick_enemies(instant: bool = false) -> void:
    movement_anim_delays.clear()
    _move_enemies()
    for i in range(MOVE_DISTANCE-1, -1, -1):
        _spawn_enemy_wave(i, instant)

    if instant:
        AfterTick.emit()
        return
    var delay_tween: Tween = get_tree().create_tween().bind_node(self)
    delay_tween.tween_interval(movement_anim_delays.values().max()+MOVEMENT_SPEED)
    delay_tween.tween_callback(AfterTick.emit)
    
###
### Movement
###
signal OnDamageTaken
func _move_enemies() -> void:
    var new_map: Dictionary[Vector2i, Node2D] = {}
    var max_reachable: Dictionary[int, int] = {}
    
    var current_positions: Array[Vector2i] = enemy_map.keys()
    current_positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        if a.y != b.y:
            return a.y < b.y        # lowest y first
        return a.x > b.x            # highest x first
    )
    
    for pos in current_positions:
        var new_x: int = min(max_reachable.get(pos.y, max_size.x+2)-1, pos.x+MOVE_DISTANCE)
        if new_x == max_size.x+1:
            var tween: Tween = _move_enemy(enemy_map[pos], Vector2i(max_size.x+8, pos.y))
            tween.tween_callback(enemy_map[pos].queue_free)
            tween.tween_callback(OnDamageTaken.emit)
        else:
            max_reachable[pos.y] = new_x
            new_map[Vector2i(new_x, pos.y)] = enemy_map[pos]
            if new_x != pos.x:
                _move_enemy(enemy_map[pos], Vector2i(new_x, pos.y))
        
    enemy_map = new_map
        
const RANDOM_ROW_DELAY: float = 0.2
const MOVEMENT_SPEED: float = 0.2
const MOVEMENT_OVERLAP_MIN: float = 0.03
const MOVEMENT_OVERLAP_MAX: float = 0.1
var movement_anim_delays: Dictionary[int, float] = {}
func _move_enemy(node: Node2D, new_pos: Vector2i, start_pos_delta: Vector2 = Vector2.ZERO, instant: bool = false) -> Tween:
    var new_pos_px: Vector2 = new_pos * Vector2i(-10, 10) + Vector2i(-5, 5)
    if instant:
        node.position = new_pos_px
        return null
    if start_pos_delta != Vector2.ZERO:
        node.position = new_pos_px + start_pos_delta

    var tween: Tween = get_tree().create_tween().bind_node(node).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
    
    if not movement_anim_delays.has(new_pos.y):
        movement_anim_delays[new_pos.y] = randf()*RANDOM_ROW_DELAY
    tween.tween_interval(movement_anim_delays[new_pos.y])
    movement_anim_delays[new_pos.y] += randf_range(MOVEMENT_OVERLAP_MIN, MOVEMENT_OVERLAP_MAX)
    
    tween.tween_property(node, "position", new_pos_px, MOVEMENT_SPEED)
    return tween
    
###
### Spawning
###
func _spawn_enemy_wave(layer: int = 0, instant: bool = false) -> void:
    var valid_spawn_points: Array[Vector2i] = []
    for y in range(max_size.y+1):
        if enemy_map.has(Vector2i(layer, y)):
            continue
        valid_spawn_points.append(Vector2i(layer, y))
        
    valid_spawn_points.shuffle()
    if len(valid_spawn_points) > 0:
        for i in range(randi_range(1, min(3, len(valid_spawn_points)))):
            _spawn_enemy(valid_spawn_points[i], instant)
        
func _spawn_enemy(pos: Vector2i, instant: bool = false) -> void:
    var node: Node2D = enemy_prefab.instantiate()
    add_child(node)
    _move_enemy(node, pos, Vector2(MOVE_DISTANCE*10, 0), instant)
    enemy_map[pos] = node
    node.tree_exiting.connect(_clear_pos.bind(node))

###
### Destroying
###
func _clear_pos(target: Node2D) -> void:
    for key in enemy_map:
        if enemy_map[key] == target:
            enemy_map.erase(key)
            return 
