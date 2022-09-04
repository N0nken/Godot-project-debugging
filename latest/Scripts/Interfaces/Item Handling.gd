extends Control

func _on_Drop_pressed():
	GlobalVars.itemDropped = true

func _on_Move_pressed():
	GlobalVars.itemMoved = true

func _on_Cancel_button_down():
	GlobalVars.canceledAction = true
