extends Node2D

# [Enemies]
# Tier1
export(PackedScene) var dasher
export(PackedScene) var pistoleer
export(PackedScene) var splitter
export(PackedScene) var australian
export(PackedScene) var knight
export(PackedScene) var shotgunner

# Tier2
export(PackedScene) var arfootman
export(PackedScene) var baseballer
export(PackedScene) var bomber
export(PackedScene) var cavalry
export(PackedScene) var grenadier
export(PackedScene) var ricochetter
export(PackedScene) var suicideBomber

# Tier3
export(PackedScene) var healer
export(PackedScene) var rioter
export(PackedScene) var sniper
export(PackedScene) var tank
export(PackedScene) var vampire
export(PackedScene) var witch
export(PackedScene) var wizard

# Bosses
export(PackedScene) var boss1
export(PackedScene) var boss2
export(PackedScene) var boss3
export(PackedScene) var boss4
export(PackedScene) var boss5

# Enemy Lists
var tier1Enemies = [dasher, pistoleer, splitter, australian, knight, shotgunner]
var tier2Enemies = [arfootman, baseballer, bomber, cavalry, grenadier, ricochetter, suicideBomber]
var tier3Enemies = [healer, rioter, sniper, tank, vampire, witch, wizard]
var allEnemies = [tier1Enemies, tier2Enemies, tier3Enemies]

var bosses = [boss1, boss2, boss3, boss4, boss5]

# Other Prefabs
export(PackedScene) var chest
export(PackedScene) var mimic

onready var player = get_tree().root.get_child(1).get_node("Player/ActualPlayer")
onready var main = get_tree().root.get_child(1)
var Room = preload("res://Scenes/Areas/Dungeon Gen/Dungeon Room.tscn")
var MinimapRoom = preload("res://Scenes/Areas/Dungeon Gen/Room For Minimap.tscn")
onready var Map = $TileMap
onready var playerStartPosition = get_tree().root.get_child(1).get_node("Current Scene/Dungeon/Basic Scene Properties/Player Positions/Player Start Position")

var tile_size = 16
var num_rooms = 10
var min_size = 10
var max_size = 30
var map_size
var map_position
var corridorIndex = 01

var hspread = 600
var vspread = 600

var path
var rng = RandomNumberGenerator.new()
signal map_complete

func _ready(): #------------------------------------------------------------------------------------
	randomize()
	rng.randomize()
	main.get_node("UI/screens/loadingscreen").show()
	#temp
	tier1Enemies = [dasher]
	generate_dungeon()
	
#Makes the outlines:
func make_rooms(): #--------------------------------------------------------------------------------
	for _i in range(num_rooms):
		var pos = Vector2(rand_range(-hspread, hspread), rand_range(-vspread, vspread))
		var r = Room.instance()
		var w = min_size + randi() % (max_size - min_size) + 1
		var h = min_size + randi() % (max_size - min_size) + 1
		r.make_room(pos, Vector2(w, h) * tile_size)
		$Rooms.add_child(r)
	#Adding boss room
	if GlobalVars.currentFloor % 3 == 0:
		var r = Room.instance()
		r.isBossRoom = true
		var bossRoomLocationX = rng.randi_range(-1000, 1000)
		var bossRoomLocationY = rng.randi_range(-1000, 1000)
		r.make_room(Vector2(bossRoomLocationX, bossRoomLocationY), Vector2(50, 50) * tile_size)
		$Rooms.add_child(r)
	yield(get_tree().create_timer(0.5), "timeout")
	var room_positions = clean_up_rooms()
	var room_list = []
	for room in room_positions:
		room_list.append(room)
	yield(get_tree(), "idle_frame")
	path = find_mst(room_positions)

func clean_up_rooms(): #----------------------------------------------------------------------------
	var positions = []
	for i in $Rooms.get_children():
		if i.get_child(0).shape.extents.x * i.get_child(0).shape.extents.y < 10*10*tile_size*tile_size:
			i.queue_free()
		else:
			i.mode = RigidBody2D.MODE_STATIC
			positions.append(Vector3(i.position.x, i.position.y, 0))
	return positions

func find_mst(nodes): #-----------------------------------------------------------------------------
	path = AStar.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	while nodes:
		var min_dist = INF
		var min_p = null
		var p  = null
		
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			for p2 in nodes:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	
	return path

func clear_rigidbodies(): #-------------------------------------------------------------------------------
	var area2dRooms = get_node("rooms for minimap")
	var majorRooms = 0
	for roomIndex in range(0, get_node("Rooms").get_child_count()):
		majorRooms += 1
		var newRoom = MinimapRoom.instance()
		if get_node("Rooms").get_child(roomIndex).isBossRoom:
			newRoom.isBossRoom = true
		var s = RectangleShape2D.new()
		s.extents = get_node("Rooms").get_child(roomIndex).get_child(0).shape.extents
		newRoom.get_child(0).shape = s
		newRoom.position = get_node("Rooms").get_child(roomIndex).position
		if majorRooms == 1:
			newRoom.spawn = true
		area2dRooms.add_child(newRoom)
	for rb in get_node("Rooms").get_children():
		rb.get_child(0).disabled = true
		rb.queue_free()

#Places/Removes tiles
func make_corridors(): #----------------------------------------------------------------------------------
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		var r = Rect2(room.position - room.size, room.get_node("CollisionShape2D").shape.extents*2)
		full_rect = full_rect.merge(r)
	var topleft = Map.world_to_map(full_rect.position - Vector2(100, 100))
	var bottomright = Map.world_to_map(full_rect.end + Vector2(100, 100))
	for x in range(topleft.x - tile_size, bottomright.x + tile_size):
		for y in range(topleft.y - tile_size, bottomright.y + tile_size):
			Map.set_cell(x, y, 0)
	map_size = full_rect.size
	map_position = full_rect.position
	
	var corridors = []
	for room in $Rooms.get_children():
		var s = (room.size/tile_size).floor()
		var _pos = Map.world_to_map(room.position)
		var ul = (room.position/tile_size).floor() - s
		for x in range(2, s.x * 2 - 1):
			for y in range(2, s.y * 2 - 1):
				Map.set_cell(ul.x + x, ul.y + y, -1)
		var p = path.get_closest_point(Vector3(room.position.x, room.position.y, 0))
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = Map.world_to_map(Vector2(path.get_point_position(p).x, path.get_point_position(p).y))
				var end = Map.world_to_map(Vector2(path.get_point_position(conn).x, path.get_point_position(conn).y))
				carve_path(start, end)
		corridors.append(p)

func carve_path(pos1, pos2): #----------------------------------------------------------------------
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0: x_diff = pow(-1.0, randi() % 2)
	if y_diff == 0: y_diff = pow(-1.0, randi() % 2)
	
	var x_y = pos1
	var y_x = pos2
	
	if (randi() % 2) > 0:
		x_y = pos2
		y_x = pos1
	
	for x in range(pos1.x, pos2.x, x_diff):
		Map.set_cell(x, x_y.y, -1)
		Map.set_cell(x, x_y.y + y_diff, -1)
	for y in range(pos1.y, pos2.y, y_diff):
		Map.set_cell(y_x.x, y, -1)
		Map.set_cell(y_x.x + x_diff, y, -1)

func spawn_enemies(bossRoom): #-----------------------------------------------------------------------------
	var spawnedEnemies = get_node("Enemies/Normal Enemies")
	for room in get_node("Rooms").get_children():
		if room == bossRoom:
			continue
		#var enemyTier = allEnemies[rng.randi_range(0, allEnemies.size()-1)]
		var enemyTier = tier1Enemies
		#var enemy = enemyTier[rng.randi_range(0, tier1Enemies.size()-1)]
		var enemy = enemyTier[0]
		enemy = enemy.instance()
		
		var enemyWidth = enemy.get_child(0).shape.extents
		
		var roomTopLeft = room.position - room.get_child(0).shape.extents
		var roomBottomRight = room.position + room.get_child(0).shape.extents
		enemy.position.x = rng.randi_range(roomTopLeft.x, roomBottomRight.x - enemyWidth.x)
		enemy.position.y = rng.randi_range(roomTopLeft.y, roomBottomRight.y - enemyWidth.y)
		
		spawnedEnemies.add_child(enemy)
		
func find_boss_room(): #----------------------------------------------------------------------------
	var size = 0
	var bossRoom
	for room in get_node("Rooms").get_children():
		var newsize = room.get_child(0).shape.extents.x * room.get_child(0).shape.extents.y * 4
		if newsize > size:
			size = newsize
	
	for room in get_node("Rooms").get_children():
		if room.get_child(0).shape.extents.x * room.get_child(0).shape.extents.y * 4 == size:
			bossRoom = room
			break
	
	#var bossLocation = bossRoom.position + Vector2(bossRoom.get_child(0).shape.extents.x, bossRoom.get_child(0).shape.extents.y)
	#get_node("Enemies/Boss").add_child(bosses[rng.randi_range(0, bosses.size()-1)])
	#get_node("Enemies/Boss/").position = bossLocation
	return bossRoom
	
func spawn_chests(bossRoom):
	for room in get_node("Rooms").get_children():
		if room == bossRoom:
			continue
			
		var newChest = null
		
		var mimicChance = rng.randi_range(0, 100)
		if mimicChance <= 10:
			newChest = chest.instance()
		else:
			newChest = chest.instance()
		
		var chestWidth = newChest.get_child(2).get_child(0).shape.extents
		var roomTopLeft = room.position - room.get_child(0).shape.extents
		var roomBottomRight = room.position + room.get_child(0).shape.extents
		newChest.position.x = rng.randi_range(roomTopLeft.x, roomBottomRight.x - chestWidth.x)
		newChest.position.y = rng.randi_range(roomTopLeft.y, roomBottomRight.y - chestWidth.y)
		newChest.scale = Vector2(0.2, 0.2)
		
		get_node("chests").add_child(newChest)
	
func generate_dungeon(): #--------------------------------------------------------------------------
	make_rooms()
	yield(get_tree().create_timer(1), "timeout")
	make_corridors()
	var bossRoom = find_boss_room()
	spawn_chests(bossRoom)
	spawn_enemies(bossRoom)
	clear_rigidbodies()
	emit_signal("map_complete")
	Map.update_bitmask_region()
	for room in get_node("rooms for minimap").get_children():
		if room.spawn == true:
			player.position = room.position
	yield(get_tree().create_timer(0.1), "timeout")
	main.get_node("UI/screens/loadingscreen").hide()
