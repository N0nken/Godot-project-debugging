extends Button

func _on_Button_focus_entered():
	GlobalVars.currentButtonInFocus = self
	
func _on_Button_button_down():
	GlobalVars.buttonPressed = true

func _on_Button_button_up():
	GlobalVars.buttonPressed = false

func _on_Button_focus_exited():
	GlobalVars.buttonPressed = false
