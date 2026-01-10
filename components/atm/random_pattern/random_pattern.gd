extends Node

@export var alt_id_range: Vector2i
@export var pos_min: Vector2i = Vector2i(0, 0)
@export var pos_max: Vector2i
@export var adjecency_matrix: Array[Vector2i] = [
    Vector2i(-1, 0),
    Vector2i(1, 0),
    Vector2i(0, 1),
    Vector2i(0, -1),
]
@export var forbidden_pairs: Array[Vector2i]

func _ready() -> void:
    var tilemap: TileMapLayer = get_parent()
    
    for y in range(pos_min.y, pos_max.y+1):
        for x in range(pos_min.x, pos_max.x+1):
            var pos: Vector2i = Vector2i(x, y)
            if tilemap.get_cell_atlas_coords(pos) != Vector2i(-1, -1):
                continue
            
            var valid_options: Array[int] = []
            for i in range(alt_id_range.x, alt_id_range.y+1):
                valid_options.append(i)
                
            for adj_pos in adjecency_matrix:
                var adj_alt_id: int = tilemap.get_cell_alternative_tile(pos+adj_pos)
                valid_options.erase(adj_alt_id)
                
                for pair in forbidden_pairs:
                    if pair.x == adj_alt_id:
                         valid_options.erase(pair.y)
                    if pair.y == adj_alt_id:
                         valid_options.erase(pair.x)
                
            tilemap.set_cell(pos, 0, Vector2i(0, 0), valid_options.pick_random())