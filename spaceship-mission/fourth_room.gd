extends Node2D



func _ready() -> void:
	$MainMessage.visible = false
	$FourthBackground.visible = true
	$LeftArrow.visible = true
	$RightArrow.visible = true
	$Walls.visible = true
	$LinkMainScreen.visible = true
	
func show_message_screen() -> void:
	$FourthBackground.visible = false
	$LeftArrow.visible = false
	$RightArrow.visible = false
	$Walls.visible = false
	$LinkMainScreen.visible = false
	$MainMessage.visible = true
	$MainMessage.start_typing()
	
	
func _on_LinkMainScreen_pressed() -> void:
	show_message_screen()
	
func hide_message_screen() -> void:
	$MainMessage.visible = false
	$FourthBackground.visible = true
	$LeftArrow.visible = true
	$RightArrow.visible = true
	$Walls.visible = true
	$LinkMainScreen.visible = true 
	
	
