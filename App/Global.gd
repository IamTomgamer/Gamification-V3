extends Node

func start_timer(minutes: float):
	var seconds = int(minutes * 60)
	var timer = get_tree().create_timer(seconds)
	timer.timeout.connect(func():
		print("⏰ Timer finished: %s minutes elapsed" % str(minutes))
		# You can trigger a popup, sound, or reward here
	)
	print("⏳ Timer started for %s minutes (%s seconds)" % [str(minutes), str(seconds)])


func show_error(message: String, popup: Node):
	popup.dialog_text = str(message)
	popup.popup_centered()
