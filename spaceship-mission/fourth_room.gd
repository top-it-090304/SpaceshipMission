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
	
func _ready_robot() -> void:
	$RobotMessage.visible = false
	$FourthBackground.visible = true
	$LeftArrow.visible = true
	$RightArrow.visible = true
	$Walls.visible = true
	$LinkRobotMessage.visible = true
	
func show_robot_message_screen() -> void:
	$FourthBackground.visible = false
	$LeftArrow.visible = false
	$RightArrow.visible = false
	$Walls.visible = false
	$LinkRobotMessage.visible = false
	$RobotMessage.visible = true
	$RobotMessage.start_typing()
	
	
func _on_LinkRobotMessage_pressed() -> void:
	show_robot_message_screen()
	
func hide_robot_message_screen() -> void:
	$RobotMessage.visible = false
	$FourthBackground.visible = true
	$LeftArrow.visible = true
	$RightArrow.visible = true
	$Walls.visible = true
	$LinkRobotMessage.visible = true 
	
	
