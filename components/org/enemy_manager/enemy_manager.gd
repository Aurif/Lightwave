extends Node

@export var enemy_prefab: PackedScene
@export var enemy_variants_prefab: Array[PackedScene]
@export var max_size: Vector2i
@export var tick_on_start: bool = true
@export var wave_label: Label
@export var light_overlay: CanvasItem
@export var show_on_victory: CanvasItem

var current_wave: int = 0
var enemy_map: Dictionary[Vector2i, MolEnemy] = {}
const WAVES_PER_TICK: int = 4
const MAX_WAVE: int = 12

signal AfterTick


func _ready() -> void:
    if tick_on_start:
        tick_enemies.call_deferred(true)

func tick_enemies(instant: bool = false) -> void:
    movement_anim_delays.clear()
    _move_enemies()

    current_wave += 1
    if current_wave > MAX_WAVE:
        wave_label.text = "Kill them all"
        if movement_anim_delays.is_empty():
            _on_victory()
            return
    else:
        wave_label.text = "Wave: %d/%d" % [current_wave, MAX_WAVE]

    if current_wave <= MAX_WAVE:
        for i in range(WAVES_PER_TICK-1, -1, -1):
            _spawn_enemy_wave(i, instant)
        
    if instant or movement_anim_delays.is_empty():
        AfterTick.emit()
        return
    var delay_tween: Tween = get_tree().create_tween().bind_node(self)
    delay_tween.tween_interval(movement_anim_delays.values().max()+MOVEMENT_SPEED)
    delay_tween.tween_callback(AfterTick.emit)
    
    if current_wave == MAX_WAVE + 1:
        var light_tween: Tween = get_tree().create_tween().bind_node(self)
        light_tween.tween_property(light_overlay, 'modulate', Color(1, 1, 1, 0.4), 3)
    
###
### Movement
###
signal OnDamageTaken
func _move_enemies() -> void:
    var new_map: Dictionary[Vector2i, MolEnemy] = {}
    var max_reachable: Dictionary[int, int] = {}
    
    var current_positions: Array[Vector2i] = enemy_map.keys()
    current_positions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
        if a.y != b.y:
            return a.y < b.y        # lowest y first
        return a.x > b.x            # highest x first
    )
    
    for pos in current_positions:
        var new_x: int = min(max_reachable.get(pos.y, max_size.x+2)-1, pos.x+enemy_map[pos].speed)
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
const BASE_VARIANT_CHANCE: float = 0.6
func _spawn_enemy_wave(layer: int = 0, instant: bool = false) -> void:
    var valid_spawn_points: Array[Vector2i] = []
    for y in range(max_size.y):
        if enemy_map.has(Vector2i(layer, y)):
            continue
        valid_spawn_points.append(Vector2i(layer, y))
        
    valid_spawn_points.shuffle()
    if len(valid_spawn_points) > 0:
        var max_to_spawn: int = floor(3+((current_wave-1.0)/(MAX_WAVE-1.0))*(max_size.y*0.6-3))
        var to_spawn: int = randi_range(1, min(max_to_spawn, len(valid_spawn_points)))
        var spawn_index: int = 0
        
        for v in range(len(enemy_variants_prefab)):
            var to_spawn_variant: int = floor(to_spawn*BASE_VARIANT_CHANCE*(current_wave-1.0)/(MAX_WAVE-1.0))
            to_spawn -= to_spawn_variant
            for _i in range(to_spawn_variant):
                _spawn_enemy(valid_spawn_points[spawn_index], instant, v)
                spawn_index += 1
        
        for _i in range(to_spawn):
            _spawn_enemy(valid_spawn_points[spawn_index], instant)
            spawn_index += 1
        
func _spawn_enemy(pos: Vector2i, instant: bool = false, variant: int = -1) -> void:
    var node: MolEnemy
    if variant == -1:
        node = enemy_prefab.instantiate()
    else:
        node = enemy_variants_prefab[variant].instantiate()
    add_child(node)
    _move_enemy(node, pos, Vector2(WAVES_PER_TICK*10, 0), instant)
    enemy_map[pos] = node
    node.tree_exiting.connect(_clear_pos.bind(node))

###
### Destroying
###
func _clear_pos(target: Node2D) -> void:
    for key in enemy_map:
        if enemy_map[key] == target:
            enemy_map.erase(key)
            break
            
    if enemy_map.is_empty() and current_wave > MAX_WAVE:
        _on_victory()

###
### Victory
###
var victory_trigger: bool = false
func _on_victory() -> void:
    if victory_trigger:
        return
    victory_trigger = true
    
    var tween: Tween = get_tree().create_tween().bind_node(show_on_victory)
    show_on_victory.visible = true
    show_on_victory.modulate = Color.TRANSPARENT
    tween.tween_property(show_on_victory, 'modulate', Color.WHITE, 3)
    
