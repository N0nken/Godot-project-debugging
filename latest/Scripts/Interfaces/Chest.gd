extends Node

# Exports
export(PackedScene) var chestInterface
export(PackedScene) var inventoryItem
export(PackedScene) var openBubble

# Nodes
var chestList
onready var main = get_tree().root.get_child(1)
onready var currentScene = main.get_child(0).get_child(0)
onready var player = main.get_node("Player")
onready var currentlyOpenedChest = main.get_node("UI/Currently Opened Chest")

# Bools
var playerClose = false
var playerWereClose = false
var createRandomizedInventory = false

# Strings and Lists
var storageFile
var inventory

# Ints and Floats
var rng = RandomNumberGenerator.new()
var currentFloor

func create_inventory(dir, curFlr):
	var possibleTiers = ["Tier1.txt", "Tier2.txt", "Tier3.txt", "Tier4.txt", "Tier5.txt"]
	var floorMultiplier
	var finalInventory = []
	if curFlr != 1:
		floorMultiplier = floor(curFlr-1/3)
		floorMultiplier += 1
	else:
		floorMultiplier = 1
		
	var amountOfItems
	var amountOfItemsHeader = rng.randi_range(1, 5)
	if amountOfItemsHeader <= 4:
		amountOfItems = rng.randi_range(1, 3)
	else:
		amountOfItems = rng.randi_range(4, 5)
	
	var itemTier
	var tier1Chance
	var tier2Chance
	var tier3Chance
	var tier4Chance
	var tier5Chance
	
	if floorMultiplier == 1:
		tier1Chance = 65
		tier2Chance = 30
		tier3Chance = 5
		tier4Chance = 0
		tier5Chance = 0
	elif 1 < floorMultiplier <= 2:
		tier1Chance = 27
		tier2Chance = 43
		tier3Chance = 30
		tier4Chance = 0
		tier5Chance = 0
	elif 2 < floorMultiplier <= 3:
		tier1Chance = 10
		tier2Chance = 27
		tier3Chance = 45
		tier4Chance = 18
		tier5Chance = 0
	elif 3 < floorMultiplier <= 4:
		tier1Chance = 0
		tier2Chance = 0
		tier3Chance = 55
		tier4Chance = 35
		tier5Chance = 10
	elif 4 < floorMultiplier <= 5:
		tier1Chance = 0
		tier2Chance = 0
		tier3Chance = 30
		tier4Chance = 45
		tier5Chance = 25
	elif 5 < floorMultiplier:
		tier1Chance = 0
		tier2Chance = 0
		tier3Chance = 23
		tier4Chance = 55
		tier5Chance = 22
	
	for index in amountOfItems:
		var tier = rng.randi_range(1, 100)
		if 0 < tier && tier <= tier1Chance:
			itemTier = 1
		elif tier1Chance < tier && tier <= tier1Chance + tier2Chance:
			itemTier = 2
		elif tier1Chance + tier2Chance < tier && tier <= tier1Chance + tier2Chance + tier3Chance:
			itemTier = 3
		elif tier1Chance + tier2Chance + tier3Chance < tier && tier <= tier1Chance + tier2Chance + tier3Chance + tier4Chance:
			itemTier = 4
		elif tier1Chance + tier2Chance + tier3Chance + tier4Chance < tier && tier <= tier1Chance + tier2Chance + tier3Chance + tier4Chance + tier5Chance:
			itemTier = 5
		
		var allItemsOfTier = load_inventory(dir + possibleTiers[itemTier-1])
		var item = allItemsOfTier[rng.randi_range(0, allItemsOfTier.size()-1)]
		if item != "":
			finalInventory.append(item)
	return finalInventory
		
		
func rewrite_file(path, content):
	var file = File.new()
	var dir = Directory.new()
	if file.file_exists(path):
		dir.remove(path)
		file.open(path, File.WRITE)
		file.store_string(content)
		file.close()
		

func load_inventory(path):
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
	
func _ready():
	rng.randomize()
	currentFloor = player.currentFloor
	if currentFloor == 0:
		currentFloor = 1
	if get_tree().get_current_scene().get_name() == "Home":
		self.name = "Home Chest"
		
	if self.name == "Home Chest":
		inventory = load_inventory("res://Data/Inventories/Home Chest Inventory.txt")
	else:
		inventory = create_inventory("res://Data/Possible Items/", currentFloor)

func _on_Area2D_body_exited(body):
	if body.name == "ActualPlayer":
		playerClose = false
		if main.get_node_or_null("UI/Currently Opened Chest/ChestInterface") != null:
			currentlyOpenedChest.get_child(0).queue_free()
			GlobalVars.chestOpened = false
		if get_node_or_null("open bubble") != null:
			get_node("open bubble").queue_free()

func _on_Area2D_body_entered(body):
	if body.name == "ActualPlayer":
		playerClose = true
		main.get_node("UI").add_child(openBubble.instance())
		
func _process(_delta):
	currentScene = main.get_child(0).get_child(0)
	if playerClose && Input.is_action_just_pressed("interact") && main.get_node_or_null("UI/Currently Opened Chest/ChestInterface") == null:
		main.get_node("UI/open bubble").queue_free()
		currentlyOpenedChest.add_child(chestInterface.instance())
		GlobalVars.chestOpened = true
		chestList = main.get_node("UI/Currently Opened Chest/ChestInterface/Control/Inventories/ScrollContainer/ChestList")
		
		for itemName in inventory:
			var item = inventoryItem.instance()
			item.text = str(itemName)
			chestList.add_child(item)
		
		if GlobalVars.playerInvOpened:
			for item in chestList.get_children():
				item.focus_neighbour_right = main.get_node("UI/Player Inventory/Control/Inventories/Stats").get_child(0).get_path()
			for item in main.get_node("UI/Player Inventory/Control/Inventories/Stats").get_children():
				item.focus_neighbour_left = main.get_node("UI/Currently Opened Chest/ChestInterface/Control/Inventories/ScrollContainer/ChestList").get_child(0).get_path()
		
		player.chestTop = chestList.get_child(0)
		chestList.get_child(0).grab_focus()
			
	elif Input.is_action_just_pressed("interact") && main.get_node_or_null("UI/Currently Opened Chest/ChestInterface") != null:
		currentlyOpenedChest.get_child(0).queue_free()
		GlobalVars.chestOpened = false
		add_child(openBubble.instance())
	
	if get_node_or_null("UI/open bubble") != null:
		get_node("UI/open bubble").global_position = player.get_node("ActualPlayer").position - Vector2(0, 50 * player.get_node("ActualPlayer").scale.y)
