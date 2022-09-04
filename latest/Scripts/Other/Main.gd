extends Node

# [Scene Handling]

export(PackedScene) var hub
export(PackedScene) var home
export(PackedScene) var dungeon

onready var currentScene = get_child(0)
onready var player = get_node_or_null("Player")
onready var actualPlayer = player.get_node("ActualPlayer")
onready var loadingScreen = get_node("UI/screens/loadingscreen")

var playerStartPosition
var enterScene = ""
var changedScene = false
var changedTo = ""

func ready():
	if player != null:
		actualPlayer = player.get_child(0)
	
func _process(_delta):
	if changedScene:
		changedScene = false
		if changedTo == "hub":
			actualPlayer.scale = Vector2(3, 3)
			player.currentHP = player.maxHP
			player.currentMan = player.maxMan
			yield(get_tree().create_timer(0.1), "timeout")
			actualPlayer.position = Vector2(460, 575)
			loadingScreen.hide()
		elif changedTo == "home":
			actualPlayer.scale = Vector2(5, 5)
			yield(get_tree().create_timer(0.1), "timeout")
			actualPlayer.position = currentScene.get_child(0).get_node("Basic Scene Properties/Player Positions/Player Start Position").position
			loadingScreen.hide()
		elif changedTo == "dungeon":
			actualPlayer.scale = Vector2(0.5, 0.5)
			get_node("PlayerCam").zoom = Vector2(0.5, 0.5)
			player.get_node("Camera2D").current = true
		changedTo = ""
	
	if enterScene != "":
		currentScene.get_child(0).queue_free()
		if enterScene == "hub":
			loadingScreen.show()
			currentScene.add_child(hub.instance())
			enterScene = ""
			changedTo = "hub"
			changedScene = true
		
		elif enterScene == "home":
			loadingScreen.show()
			currentScene.add_child(home.instance())
			enterScene = ""
			changedTo = "home"
			changedScene = true
		
		elif enterScene == "dungeon":
			currentScene.add_child(dungeon.instance())
			enterScene = ""
			changedTo = "dungeon"
			changedScene = true


func _on_Main_tree_entered():
	var file = File.new()
	if file.file_exists("res://Other/coconut.jpg") != true:
		get_tree().quit()
