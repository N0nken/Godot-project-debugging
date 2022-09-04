extends Area2D

export(PackedScene) var textBubble

onready var main = get_tree().root.get_child(1)
onready var currentScene = main.get_node("Current Scene").get_child(0)
onready var actualPlayer = main.get_node("Player/ActualPlayer")

var playerClose = false

func _on_Area2D_body_entered(body):
	if body.name == "ActualPlayer":
		playerClose = true
		var enterBubble = textBubble.instance()
		add_child(enterBubble)

func _process(_delta):
	if playerClose: 
		currentScene = main.get_node("Current Scene").get_child(0)
		actualPlayer = main.get_node("Player/ActualPlayer")
		get_node("Enter Bubble").get_child(0).position = actualPlayer.position - Vector2(0, 50 * actualPlayer.scale.y)
		if Input.is_action_just_pressed("interact"):
			if get_parent().name == "Enter Home":
				main.enterScene = "home"
			elif get_parent().name == "Leave Home":
				main.enterScene = "hub"
			elif get_parent().name == "Enter Dungeon":
				main.enterScene = "dungeon"

func _on_Area2D_body_exited(body):
	if body.name == "ActualPlayer":
		playerClose = false
		get_node("Enter Bubble").queue_free()
