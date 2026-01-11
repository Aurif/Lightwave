extends Node

@export var enemy_prefab: PackedScene
@export var max_size: Vector2i
@export var tick_on_start: bool = true

var enemy_map: Dictionary[Vector2i, Node2D] = {}
const MOVE_DISTANCE: int = 2

signal AfterTick

func _ready() -> void:
    if tick_on_start:
        tick_enemies.call_deferred()

func tick_enemies() -> void:
    _move_enemies()
    _spawn_enemy_wave()

    AfterTick.emit()
    
###
### Movement
###
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
        var new_x: int = min(max_reachable.get(pos.y, max_size.x+1)-1, pos.x+MOVE_DISTANCE)
        max_reachable[pos.y] = new_x
        new_map[Vector2i(new_x, pos.y)] = enemy_map[pos]
        _move_enemy(enemy_map[pos], Vector2i(new_x, pos.y))
        
    enemy_map = new_map
        
func _move_enemy(node: Node2D, new_pos: Vector2i) -> void:
    node.position = new_pos * Vector2i(-10, 10) + Vector2i(-5, 5)
    
###
### Spawning
###
func _spawn_enemy_wave(layer: int = 0) -> void:
    var valid_spawn_points: Array[Vector2i] = []
    for y in range(max_size.y+1):
        if enemy_map.has(Vector2i(layer, y)):
            continue
        valid_spawn_points.append(Vector2i(layer, y))
        
    valid_spawn_points.shuffle()
    for i in range(randi_range(1, min(3, len(valid_spawn_points)))):
        _spawn_enemy(valid_spawn_points[i])
        
func _spawn_enemy(pos: Vector2i) -> void:
    var node: Node2D = enemy_prefab.instantiate()
    add_child(node)
    node.position = pos * Vector2i(-10, 10) + Vector2i(-5, 5)
    enemy_map[pos] = node
