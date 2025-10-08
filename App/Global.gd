extends Node


var countdown_time: int = 0
var timer_running: bool = false

signal countdown_updated(time_left: int)
signal countdown_finished

@onready var countdown_timer: Timer = Timer.new()

func _ready():
	# Configure the timer
	countdown_timer.wait_time = 1.0   # 1 second
	countdown_timer.one_shot = false
	countdown_timer.autostart = false
	add_child(countdown_timer)

	# Connect the timeout signal
	countdown_timer.timeout.connect(_on_countdown_tick)

func start_countdown(seconds: int):
	countdown_time = seconds
	timer_running = true
	countdown_timer.start()
	emit_signal("countdown_updated", countdown_time)

func _on_countdown_tick():
	if not timer_running:
		return

	countdown_time -= 1
	if countdown_time <= 0:
		countdown_time = 0
		timer_running = false
		countdown_timer.stop()
		emit_signal("countdown_updated", countdown_time)
		emit_signal("countdown_finished")
	else:
		emit_signal("countdown_updated", countdown_time)


var app_name = "Gamification"




func show_error(message: String, popup: Node):
	popup.dialog_text = str(message)
	popup.popup_centered()
