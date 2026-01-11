extends Node

@export var hp: int = 10 
@export var label: Label
@export var show_on_gameover: CanvasItem

func _ready() -> void:
    _update_label()

func reduce_hp(amount: int = 1) -> void:
    hp -= amount
    _update_label()
    if hp <= 0:
        _on_game_over()
    
func _update_label() -> void:
    label.text = "HP: %s" % str(max(0, hp))

func _on_game_over() -> void:
    if get_tree().paused == true:
        return
    
    var tween: Tween = get_tree().create_tween().bind_node(show_on_gameover)
    show_on_gameover.visible = true
    show_on_gameover.modulate = Color.TRANSPARENT
    tween.tween_property(show_on_gameover, 'modulate', Color.WHITE, 3)
    
    get_tree().paused = true
    
    
