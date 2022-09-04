extends KinematicBody2D

onready var main = get_tree().root.get_child(1)
onready var player = main.get_node("Player")
onready var actualPlayer = player.get_node("ActualPlayer")

var lastSpot = Vector2.ZERO
var velocity = Vector2.ZERO
var xVelocity = 0
var yVelocity = 0
var speed = 300
var rotationalSpeed = 1

func _physics_process(delta):
	if GlobalVars.paused:
		pass
	if self.position == lastSpot:
		velocity = Vector2.ZERO

	var space_state = get_world_2d().direct_space_state
	var raycastResult = space_state.intersect_ray(self.position, actualPlayer.position, [self])
	if !raycastResult.empty():
		if raycastResult["collider"].name == "actualPlayer":
			lastSpot = actualPlayer.position
			yVelocity = self.position.x - actualPlayer.position.x
			yVelocity = self.position.y - actualPlayer.position.y
			
			if xVelocity > 420 || xVelocity < -420 || yVelocity > 420 || yVelocity < -420:
				velocity = Vector2(-xVelocity, -yVelocity)
				velocity = velocity.normalized() * speed
			elif xVelocity < 400 && xVelocity > -400 && yVelocity < 400 && yVelocity > -400:
				velocity = Vector2(xVelocity, yVelocity)
				velocity = velocity.normalized() * speed
			else:
				velocity = Vector2(1, 0) * speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide(velocity)
