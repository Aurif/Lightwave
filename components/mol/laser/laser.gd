extends CharacterBody2D

@export var is_active: bool = false:
    set(value):
        if is_active == value:
            return
        is_active = value
        _handle_active_change()
const MOVE_SPEED: float = 50.0

func _ready() -> void:
    _handle_active_change()

func _physics_process(delta):
    if not is_active:
        return
    var direction: float = Input.get_action_strength("move_down") \
                         - Input.get_action_strength("move_up")
    velocity.x = 0
    velocity.y = MOVE_SPEED * direction

    move_and_slide()

    if is_on_wall():
        direction *= -1

###
### Firing handling
###
signal OnFired
func set_active() -> void:
    self.is_active = true

func _input(event: InputEvent) -> void:
    if not is_active:
        return
    
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SHIFT:
            print("FIRE IN THE HOLE!!!")
            is_active = false
            OnFired.emit.call_deferred()

###
### Active animation
###
var tween: Tween
func _handle_active_change():
    if not is_active and tween:
        tween.stop()
        tween = null
        self.modulate = Color.WHITE
        
    if is_active and not tween:
        if not is_inside_tree():
            return
        tween = get_tree().create_tween().bind_node(self)
        tween.set_loops()
        tween.tween_property(self,"modulate",Color(2, 2, 2),0.13)
        tween.tween_property(self,"modulate",Color.WHITE,0.9)
