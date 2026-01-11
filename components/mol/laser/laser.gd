extends CharacterBody2D

@export var is_active: bool = false:
    set(value):
        if is_active == value:
            return
        is_active = value
        _handle_active_change()
@export var modulate_target: CanvasItem
const MOVE_SPEED: float = 50.0

func _ready() -> void:
    _handle_active_change()

func _physics_process(_delta) -> void:
    if not is_active:
        return
    var direction: float = Input.get_action_strength("move_down") \
                         - Input.get_action_strength("move_up")
    velocity.x = 0
    velocity.y = MOVE_SPEED * direction

    move_and_slide()

    if is_on_wall():
        direction *= -1
        
    _update_laser_path()

###
### Firing handling
###
signal FireLaser(path: Array[Vector2], callback: Callable)
signal OnFired
func set_active() -> void:
    self.is_active = true

var sweep_last_exec: int = -1
func _input(event: InputEvent) -> void:
    if not is_active:
        return
    
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SHIFT:
            _fire_laser()
            
    if event is InputEventKey and event.pressed \
     and InputMap.event_is_action(event, "switch_angle") \
     and (not event.echo or Time.get_ticks_msec() > sweep_last_exec + SWEEP_COOLDOWN):
        sweep_last_exec = Time.get_ticks_msec()
        switch_angle()

func _fire_laser() -> void:
    %LaserLine.default_color = Color('#d6ecff')
    is_active = false
    FireLaser.emit(_get_laser_path(), _after_fired)

func _get_laser_path() -> Array[Vector2]:
    var result: Array[Vector2] = []
    for point in %LaserLine.points:
        result.append(%LaserLine.to_global(point))
    return result

func _after_fired() -> void:
    %LaserLine.visible = false
    %LaserLine.default_color = Color('#d1b3ff73')
    OnFired.emit.call_deferred()

###
### Aim handling
###
const SWEEP_COOLDOWN: int = 150
const VALID_ANGLES: Array[int] = [-45, -30, -15, 0, 15, 30, 45]
var current_angle: int = 3

func switch_angle() -> void:
    current_angle = (current_angle + 1) % len(VALID_ANGLES)
    %LaserLine.rotation_degrees = VALID_ANGLES[current_angle]

###
### Path prediction
###
func _update_laser_path():
    %RayCast.clear_exceptions()
    %RayCast.position = %LaserLine.position
    %RayCast.rotation_degrees = %LaserLine.rotation_degrees
    var laser_path: Array[Vector2i] = [Vector2i.ZERO]
    
    for i in range(100):
        %RayCast.force_raycast_update()
        laser_path.append(Vector2i(%LaserLine.to_local(%RayCast.get_collision_point())))
        %RayCast.global_position = %RayCast.get_collision_point()
        
        var incident: Vector2 = %RayCast.target_position.rotated($RayCast.global_rotation).normalized()
        var normal: Vector2 = %RayCast.get_collision_normal()
        var reflected: Vector2 = incident - 2 * incident.dot(normal) * normal
        %RayCast.rotation = reflected.angle()
        
        if %RayCast.get_collider().name == 'WorldBorder':
            break
        %RayCast.clear_exceptions()
        %RayCast.add_exception(%RayCast.get_collider())
        
    %LaserLine.points = laser_path

###
### Active animation
###
var tween: Tween
func _handle_active_change():
    if not is_active and tween:
        tween.kill()
        tween = null
        modulate_target.modulate = Color.WHITE
        
    if is_active and not tween:
        if not is_inside_tree():
            return
        tween = get_tree().create_tween().bind_node(self)
        tween.set_loops()
        tween.tween_property(modulate_target,"modulate",Color(2, 2, 2),0.13)
        tween.tween_property(modulate_target,"modulate",Color.WHITE,0.9)
        
    if is_active:
        %LaserLine.visible = true
