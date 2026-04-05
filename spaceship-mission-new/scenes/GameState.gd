extends Node
 
# Этот файл — глобальный синглтон, доступен из любой сцены как GameState.xxx
 
var current_room: int = 1
var intro_finished: bool = false
var ball_cleaned: bool = false
 
# Room4 — робот
var robot_powered: bool = false
var panel_solved: bool = false
var panel_game_won: bool = false
var ship_panel_opened: bool = false
var ship_fully_solved: bool = false
 
# Реактор — единственное что нужно сохранять между комнатами
var reactor_picked_up: bool = false   # реактор забрали из Room1 в инвентарь
var reactor_installed: bool = false   # реактор установлен в Room3
 
