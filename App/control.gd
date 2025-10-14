extends Control


func _ready():
	var button = Button.new()
	button.text = "Test"
	button.icon = load("res://Textures/Icons/RewardTypes/Timer.png")
	add_child(button)
