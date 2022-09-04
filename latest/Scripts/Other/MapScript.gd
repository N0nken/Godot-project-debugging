extends TileMap

onready var main = get_tree().root.get_child(1)
onready var Map = self
onready var grandparent = get_parent().get_parent()
onready var parent = get_parent()
onready var player = main.get_node("Player")
onready var actualPlayer = player.get_node("ActualPlayer")

var tile_size = 16
var framesSinceLastUpdate = 0

func _ready():
	hide()

func _process(_delta):
	if Input.is_action_just_pressed("open_map") && !GlobalVars.mapOpened:
		main.get_node("map").current = true
		GlobalVars.paused = true
		GlobalVars.mapOpened = true
		for room in parent.get_node("rooms for minimap").get_children():
			if room.playerEntered:
				room.playerEntered = false
				var rect = Rect2()
				rect.size = room.get_child(0).shape.extents
				rect.position = room.position
				var roomTopLeft = Map.world_to_map(rect.position - rect.size)
				var roomBottomRight = Map.world_to_map(rect.end)
				update_map_for_new_room(roomTopLeft, roomBottomRight)
		Map.update_bitmask_region()
		show()
	elif Input.is_action_just_pressed("open_map") && GlobalVars.mapOpened:
		hide()
		main.get_node("Player/Camera2D").current = true
		GlobalVars.paused = false
		GlobalVars.mapOpened = false
		
func _physics_process(_delta):
	var uncoverPos = Map.world_to_map(actualPlayer.position)
	for x in range(uncoverPos.x - 4, uncoverPos.x + 4):
		for y in range(uncoverPos.y - 4, uncoverPos.y + 4):
			Map.set_cell(x, y, -1)
	

func fill_map():
	var full_rect = Rect2()
	full_rect.size = parent.map_size
	full_rect.position = parent.map_position
	var topleft = Map.world_to_map(full_rect.position - Vector2(100, 100))
	var bottomright = Map.world_to_map(full_rect.end + Vector2(100, 100))
	for x in range(topleft.x - tile_size, bottomright.x + tile_size):
		for y in range(topleft.y - tile_size, bottomright.y + tile_size):
			Map.set_cell(x, y, 0)

func update_map_for_new_room(topLeft, bottomRight):
	for x in range(topLeft.x, bottomRight.x):
		for y in range(topLeft.y, bottomRight.y):
			Map.set_cell(x, y, -1)

func _on_Dungeon_Generation_map_complete():
	fill_map()
