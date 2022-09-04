extends Node

export(PackedScene) var dungeonGen

onready var main = get_tree().root.get_child(1)
onready var player = main.get_node("Player")
onready var floorMultiplier = floor(player.currentFloor/3) + 1

func _ready():
	add_child(dungeonGen.instance())

