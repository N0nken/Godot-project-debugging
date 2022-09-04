extends Area2D

var playerEntered = false
var isBossRoom = false
var spawn = false

func _on_Area2D_body_entered(body):
	if body.name == "ActualPlayer":
		playerEntered = true
		get_child(0).set_deferred("disabled", true)
