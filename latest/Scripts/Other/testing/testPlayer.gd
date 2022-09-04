extends KinematicBody2D

var velocity = Vector2.ZERO
var speedLimit = 400
var currentHP = 100


func _process(_delta):
	# [Movement]
	velocity = Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
		
	velocity = velocity.normalized() * speedLimit

func _physics_process(_delta):
	print(currentHP)
	move_and_slide(velocity)
