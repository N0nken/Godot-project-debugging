extends Node

# [CAMERA]

onready var camera = get_node("Camera2D")

var inRoom

# [MOVEMENT]

# Run
export(int) var baseSpeed
export(float) var speedLimit

# Dash
export(float) var dashDuration
export(float) var dashCooldown
export(float) var dashSpeed

# Controls
var velocity = Vector2.ZERO
var dashFrame = 0
var framesAfterDash = 0

# [INVENTORY]

export(PackedScene) var playerInventoryInterface
export(PackedScene) var inventoryItem
export(PackedScene) var itemHandling

var inventory
var chestTop

var equippedInventory = ""
var backpackInventory = ""

# [STATS]

export(PackedScene) var playerStat

var lvl #Player Level
var hp #Health
var spd #Speed
var man #Mana
var ac #Ammo Capacity
var def #Defense
var cc #Critical Chance
var cd #Critical Damage
var kb #Knockback
var atkspd #Attack Speed
var atk #Attack/Damage Multiplier

var maxHP
var maxMan
var maxAc
var currentHP
var currentMan
var currentFloor = 1

var allStats = [lvl, hp, spd, man, ac, def, cc, cd, atkspd]
var allStatNames = ["LVL", "HP", "SPD", "MAN", "AC", "DEF", "CC", "CD", "KB", "ATKSPD", "ATK"]
var currentStats = [currentHP, currentMan]
var currentStatNames = ["HP", "MAN"]
var tempStats = null

# [MISCELLANEOUS]

var ready = false
var sceneName = "Hub"

var main
var currentScene
var playerStartPosition
var actualPlayer

var rng = RandomNumberGenerator.new()

var framesAfterLastFootstep = 0

func load_file(path):
	var file = File.new()
	if file.file_exists(path):
		var inventoryList = []
		file.open(path, File.READ)
		while not file.eof_reached():
			var line = file.get_line()
			inventoryList.append(line)
		file.close()	
		return inventoryList
	return null
	
func rewrite_file(path, content):
	var file = File.new()
	var dir = Directory.new()
	if file.file_exists(path):
		dir.remove(path)
		file.open(path, File.WRITE)
		file.store_string(content)
		file.close()
	
func _ready():
	# [MISCELLANEOUS]
	main = get_tree().root.get_child(1)
	currentScene = main.get_child(0).get_child(0)
	playerStartPosition = currentScene.get_node("Basic Scene Properties/Player Positions/Player Start Position")
	actualPlayer = get_node("ActualPlayer")
	sceneName = currentScene.name
	actualPlayer.scale = Vector2(3, 3)
	rng.randomize()
	
	# [MOVEMENT]
	actualPlayer.position = playerStartPosition.position
	
	get_node("ActualPlayer/AnimatedSprite").play()
	
	# [STATS]
	tempStats = load_file("res://Data/Stats/Player Stats.txt")
	maxHP = 100 * int(tempStats[1])
	maxMan = 100 * int(tempStats[3])
	
	currentHP = maxHP
	currentMan = maxMan

func _process(_delta):
	if GlobalVars.paused:
		return

	# [CAMERA]
	if main.get_child(0).get_child(0).name == "Hub" || main.get_child(0).get_child(0).name == "Home":
		inRoom = true
	else:
		inRoom = false
	if inRoom:
		camera.position = Vector2(960, 540)
	else:
		camera.position = actualPlayer.position
	
	# [MOVEMENT]
	velocity = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	
	if velocity.length() > 0 && Input.is_action_just_pressed("sprint") == false:
		get_node("ActualPlayer/AnimatedSprite").animation = "walk"
		speedLimit = baseSpeed
		velocity += velocity.normalized() * speedLimit
	elif velocity.length() > 0 && Input.is_action_just_pressed("sprint") && framesAfterDash == dashCooldown:
		dashFrame = 0
		framesAfterDash = 0
	else:
		get_node("ActualPlayer/AnimatedSprite").animation = "idle"
	
	# [INVENTORY & STATS]
	if Input.is_action_just_pressed("open_inventory") && main.get_node_or_null("UI/Player Inventory") == null:
		GlobalVars.playerInvOpened = true
		main.get_node("UI").add_child(playerInventoryInterface.instance())
		var inventoryInterface = main.get_node("UI/Player Inventory")
		inventory = load_file("res://Data/Inventories/Player Inventory.txt")
		if inventory != null:
			equippedInventory = inventory[0]
			backpackInventory = inventory[1]
			
			var equippedInventoryList = equippedInventory.split(",", true, 0)
			var backpackInventoryList = backpackInventory.split(",", true, 0)
			
			var primaryWeapon = equippedInventoryList[0]
			var secondaryWeapon = equippedInventoryList[1]
			
			var helmet = equippedInventoryList[2]
			var chestplate = equippedInventoryList[3]
			var pants = equippedInventoryList[4]
			var boots = equippedInventoryList[5]
			
			var artifact1 = equippedInventoryList[6]
			var artifact2 = equippedInventoryList[7]
			var artifact3 = equippedInventoryList[8]
			var artifact4 = equippedInventoryList[9]
			var artifact5 = equippedInventoryList[10]
			
			var weapons =  [primaryWeapon, secondaryWeapon]
			var armour = [helmet, chestplate, pants, boots]
			var artifacts = [artifact1, artifact2, artifact3, artifact4, artifact5]
			equippedInventoryList = [weapons, armour, artifacts]
			
			for cat in equippedInventoryList:
				for itemName in cat:
					var item = inventoryItem.instance()
					item.text = itemName
					if cat == equippedInventoryList[0]:
						inventoryInterface.get_node("Control/Inventories/Weapons").add_child(item)
					elif cat == equippedInventoryList[1]:
						inventoryInterface.get_node("Control/Inventories/Armour").add_child(item)
					elif cat == equippedInventoryList[2]:
						inventoryInterface.get_node("Control/Inventories/Artifacts").add_child(item)
			
			for itemName in backpackInventoryList:
				var item = inventoryItem.instance()
				item.text = itemName
				inventoryInterface.get_node("Control/Inventories/ScrollContainer/Backpack").add_child(item)
			
			if backpackInventoryList.size() < 10:
				inventoryInterface.get_node("Control/Appearance/Labels/Backpack Capacity").text = "0" + str(backpackInventoryList.size()) + "/30"
			else:
				inventoryInterface.get_node("Control/Appearance/Labels/Backpack Capacity").text = str(backpackInventoryList.size()) + "/30"
			
			
			allStats = load_file("res://Data/Stats/Player Stats.txt")
			lvl = allStats[0]
			hp = allStats[1]
			spd = allStats[2]
			man = allStats[3]
			ac = allStats[4]
			def = allStats[5]
			cc = allStats[6]
			cd = allStats[7]
			kb = allStats[8]
			atkspd = allStats[9]
			atk = allStats[10]
			allStats = [lvl, hp, spd, man, ac, def, cc, cd, kb, atkspd, atk]
			
			var stats = main.get_node("UI/Player Inventory/Control/Inventories/Stats")
			for n in allStats.size():
				var stat = inventoryItem.instance()
				stat.text = allStatNames[n] + " : " + str(allStats[n])
				stats.add_child(stat)
			
			# Focus Handling
			inventoryInterface.get_node("Control/Inventories/Weapons").get_child(0).grab_focus()
			var topWeapon = inventoryInterface.get_node("Control/Inventories/Weapons").get_child(0)
			var botWeapon = inventoryInterface.get_node("Control/Inventories/Weapons").get_child(1)
			
			var topArmour = inventoryInterface.get_node("Control/Inventories/Armour").get_child(0)
			var botArmour = inventoryInterface.get_node("Control/Inventories/Armour").get_child(3)
			
			var topArtifact = inventoryInterface.get_node("Control/Inventories/Artifacts").get_child(0)
			var botArtifact = inventoryInterface.get_node("Control/Inventories/Artifacts").get_child(4)
			
			var topBackpack = inventoryInterface.get_node("Control/Inventories/ScrollContainer/Backpack").get_child(0)
			var botBackpack = inventoryInterface.get_node("Control/Inventories/ScrollContainer/Backpack").get_child(inventoryInterface.get_node("Control/Inventories/ScrollContainer/Backpack").get_child_count()-1)
			
			topWeapon.focus_neighbour_top = botBackpack.get_path()
			botWeapon.focus_neighbour_bottom = topArmour.get_path()
			
			topArmour.focus_neighbour_top = botWeapon.get_path()
			botArmour.focus_neighbour_bottom = topArtifact.get_path()
			
			topArtifact.focus_neighbour_top = botArmour.get_path()
			botArtifact.focus_neighbour_bottom = topBackpack.get_path()
			
			topBackpack.focus_neighbour_top = botArtifact.get_path()
			botBackpack.focus_neighbour_bottom = topWeapon.get_path()
			
			for cat in inventoryInterface.get_node("Control/Inventories").get_children():
				if cat == inventoryInterface.get_node("Control/Inventories/Stats"):
					for item in cat.get_children():
						if GlobalVars.chestOpened:
							item.focus_neighbour_left = main.get_node("UI/Currently Opened Chest/ChestInterface/Control/Inventories/ScrollContainer/ChestList").get_child(0).get_path()
						item.focus_neighbour_right = inventoryInterface.get_node("Control/Inventories/Weapons").get_child(0).get_path()
				elif cat == inventoryInterface.get_node("Control/Inventories/ScrollContainer"):
					for item in cat.get_node("Backpack").get_children():
						item.focus_neighbour_left = inventoryInterface.get_node("Control/Inventories/Stats").get_child(0).get_path()
				elif cat == inventoryInterface.get_node("Control/Inventories/Weapons") || cat == inventoryInterface.get_node("Control/Inventories/Armour") || cat == inventoryInterface.get_node("Control/Inventories/Artifacts"):
					for item in cat.get_children():
						item.focus_neighbour_left = inventoryInterface.get_node("Control/Inventories/Stats").get_child(0).get_path()
			
			if GlobalVars.chestOpened:
				for item in main.get_node("UI/Currently Opened Chest/ChestInterface/Control/Inventories/ScrollContainer/ChestList").get_children():
					item.focus_neighbour_right = inventoryInterface.get_node("Control/Inventories/Stats").get_child(0).get_path()
				
			
	elif Input.is_action_just_pressed("open_inventory") && main.get_node_or_null("UI/Player Inventory") != null:
		rewrite_file("res://Data/Inventories/Player Inventory.txt", equippedInventory + "\n" + backpackInventory)
		main.get_node("UI/Player Inventory").queue_free()
		GlobalVars.playerInvOpened = false
		
	# [ITEM MOVEMENT]
	if GlobalVars.playerInvOpened:
		if GlobalVars.buttonPressed:
			main.get_node("UI/Pop-ups").add_child(itemHandling.instance())
			main.get_node("UI/Pop-ups/Item Handling/ColorRect/ColorRect2/VBoxContainer/Drop").grab_focus()
	
	# [MISCELLANEOUS]
	if framesAfterLastFootstep >= 30:
		framesAfterLastFootstep = 0
		play_footstep()
	
	framesAfterLastFootstep += 1
	
func _physics_process(_delta):
	if GlobalVars.paused:
		return
	# [MOVEMENT]
	if framesAfterDash < dashCooldown:
		framesAfterDash += 1
	if dashFrame < dashDuration:
		velocity = Vector2(velocity.x, velocity.y).normalized() * dashSpeed	
		dashFrame += 1
	
	actualPlayer.move_and_slide(velocity)
	
	# [INVENTORY]
	
	# [MISCELLANEOUS]
	if currentHP < 0:
		main.get_node("UI/screens/Game Over").show()

func drop_item():
	pass
	
func move_to_chest():
	pass
	
func play_footstep():
	var files = ["res://Audio/Footsteps/Footstep0", "res://Audio/Footsteps/Footstep1", "res://Audio/Footsteps/Footstep2",
	"res://Audio/Footsteps/Footstep3", "res://Audio/Footsteps/Footstep4", "res://Audio/Footsteps/Footstep5", "res://Audio/Footsteps/Footstep6",
	"res://Audio/Footsteps/Footstep7", "res://Audio/Footsteps/Footstep8", "res://Audio/Footsteps/Footstep9", "res://Audio/Footsteps/Footstep10"]
	var path = files[rng.randi_range(0, files.size()-1)]
	var file = File.new()
	if file.file_exists(path):
		file.open(path, file.READ)
		var buffer = file.get_buffer(file.get_len())
		var stream = AudioStreamMP3.new()
		stream.data = buffer
		var audio = get_node("ActualPlayer/AudioStreamPlayer2D")
		audio.stream = stream
		audio.play()
