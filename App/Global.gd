extends Node

func show_error(message: String, popup: Node):
	popup.dialog_text = str(message)
	popup.popup_centered()
