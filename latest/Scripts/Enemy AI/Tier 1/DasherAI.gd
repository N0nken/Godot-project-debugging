extends KinematicBody2D

onready var main = get_tree().root.get_child(1)
onready var player = main.get_node("Player")
onready var actualPlayer = player.get_child(0)
onready var ray = get_node("RayCast2D")

export(int) var speed
var lastSpot = Vector2(0, 0)
var xVelocity = 0
var yVelocity = 0
var velocity = Vector2.ZERO
var damage = 15
var dealtDamage = false
var collider = null

func _physics_process(_delta):
	if GlobalVars.paused:
		return
	if lastSpot == self.position:
		velocity = Vector2.ZERO
		
	var space_state = get_world_2d().direct_space_state
	var raycastResult = space_state.intersect_ray(self.position, actualPlayer.position, [self])
	if !raycastResult.empty():
		if raycastResult["collider"].name == "ActualPlayer":
			lastSpot = actualPlayer.position
			xVelocity = self.position.x - actualPlayer.position.x
			yVelocity = self.position.y - actualPlayer.position.y
			velocity = -Vector2(xVelocity, yVelocity).normalized() * speed
	
	var _collisions = move_and_slide(velocity)
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.name == "ActualPlayer" && !dealtDamage:
			dealtDamage = true
			player.currentHP -= damage
			print("dealt damage")
			self.queue_free()
