extends Control

@onready var folder_name = UserState.current_user
@onready var info_path = "user://users/" + folder_name + "/info.json"
@onready var task_path = "user://users/" + folder_name + "/Tasks.json"
@onready var reward_path = "user://users/" + folder_name + "/Rewards.json"

@onready var task_button = preload("res://Tasks.tscn")
@onready var reward_button = preload("res://Rewards.tscn")

@onready var task_list = $Tasks_Rewards/Tasks/Tasks/Tasks
@onready var reward_list = $Tasks_Rewards/Rewards/Rewards/Rewards

@onready var default_task_path = "user://Defaults/Tasks.json"
@onready var default_reward_path = "user://Defaults/Rewards.json"

@onready var countdown_label = $HBoxContainer/CountdownLabel

func _ready():
	Global.countdown_updated.connect(update_countdown)
	Global.countdown_finished.connect(hide_countdown)

	# If timer is already running when scene loads
	if Global.timer_running:
		update_countdown(Global.countdown_time)
	else:
		countdown_label.visible = false
	refresh_points()
	load_tasks()
	load_rewards()

func update_countdown(time_left: int):
	countdown_label.visible = time_left > 0
	# Format as mm:ss if you like
	var minutes = int(time_left / 60.0)
	var seconds = int(time_left % 60)
	countdown_label.text = "%02d:%02d" % [minutes, seconds]
	
func hide_countdown():
	countdown_label.visible = false

# ✅ Load and sort tasks
func load_tasks():
	var task_data = []

	# Load user tasks if available
	if FileAccess.file_exists(task_path):
		var file = FileAccess.open(task_path, FileAccess.READ)
		task_data = JSON.parse_string(file.get_as_text())
		file.close()

	# If user tasks are missing or invalid, load defaults
	if typeof(task_data) != TYPE_ARRAY or task_data.is_empty():
		print("No valid user tasks found for", folder_name, "- loading defaults")
		var default_path = "user://Defaults/Tasks.json"
		if FileAccess.file_exists(default_path):
			var file = FileAccess.open(default_path, FileAccess.READ)
			task_data = JSON.parse_string(file.get_as_text())
			file.close()

	# Final validation
	if typeof(task_data) != TYPE_ARRAY:
		print("Invalid task format")
		return

	task_data.sort_custom(Callable(self, "compare_tasks"))

	for task in task_data:
		if typeof(task) == TYPE_DICTIONARY:
			populate_tasks(task)

# ✅ Load and sort rewards
func load_rewards():
	var reward_data = []

	# Load user rewards if available
	if FileAccess.file_exists(reward_path):
		var file = FileAccess.open(reward_path, FileAccess.READ)
		reward_data = JSON.parse_string(file.get_as_text())
		file.close()

	# If user rewards are missing or invalid, load defaults
	if typeof(reward_data) != TYPE_ARRAY or reward_data.is_empty():
		print("No valid user rewards found for", folder_name, "- loading defaults")
		var default_path = "user://Defaults/Rewards.json"
		if FileAccess.file_exists(default_path):
			var file = FileAccess.open(default_path, FileAccess.READ)
			reward_data = JSON.parse_string(file.get_as_text())
			file.close()

	# Final validation
	if typeof(reward_data) != TYPE_ARRAY:
		print("Invalid reward format")
		return

	reward_data.sort_custom(Callable(self, "compare_rewards"))

	for reward in reward_data:
		if typeof(reward) == TYPE_DICTIONARY:
			populate_rewards(reward)


# ✅ Sorting functions
func compare_tasks(a, b) -> bool:
	return int(a.get("points", 0)) < int(b.get("points", 0))  # ascending

func compare_rewards(a, b) -> bool:
	return int(a.get("cost", 0)) < int(b.get("cost", 0))  # ascending

# ✅ Populate task row
func populate_tasks(task: Dictionary):
	var row = task_button.instantiate()
	var taskname = task.get("name", "Unnamed Task")
	var points = task.get("points", 0)

	var button = row.get_node("TaskButton")
	button.text = "%s\nPoints: %s" % [taskname, str(points)]

	button.pressed.connect(func():
		on_task_pressed(taskname, points)
	)

	var delete_button = row.get_node("DeleteButton")
	delete_button.pressed.connect(func():
		delete_task_from_json(taskname)
		row.queue_free()
	)

	task_list.add_child(row)
	
# ✅ Populate reward row
func populate_rewards(reward: Dictionary):
	var row = reward_button.instantiate()
	var rewardname = reward.get("name", "Unnamed Reward")
	var cost = reward.get("cost", 0)
	var type = reward.get("type", "Normal")  # Default to Normal if missing

	var button = row.get_node("RewardButton")
	button.text = "%s\nCost: %s\nType: %s" % [rewardname, str(cost), type]

	var user_points = get_user_points()
	button.disabled = cost > user_points

	match type:
		"Time":
			button.pressed.connect(func():
				on_reward_pressed(rewardname, cost)
			)
		"Experience":
			button.pressed.connect(func():
				on_reward_pressed(rewardname, cost)  # same as Normal
			)
		_:
			button.pressed.connect(func():
				on_reward_pressed(rewardname, cost)
			)

	var delete_button = row.get_node("DeleteButton")
	delete_button.pressed.connect(func():
		delete_reward_from_json(rewardname)
		row.queue_free()
	)

	reward_list.add_child(row)

# ✅ Refresh reward buttons based on current points
func refresh_rewards():
	var user_points = get_user_points()

	for row in reward_list.get_children():
		var button = row.get_node_or_null("RewardButton")
		if button:
			var label_text = button.text
			var parts = label_text.split("\nCost: ")
			if parts.size() == 2:
				var cost = int(parts[1])
				button.disabled = cost > user_points

# ✅ Refresh task list
func refresh_tasks():
	for child in task_list.get_children():
		child.queue_free()
	load_tasks()

# ✅ Refresh reward list
func refresh_rewards_list():
	for child in reward_list.get_children():
		child.queue_free()
	load_rewards()

# ✅ Get current user points
func get_user_points() -> int:
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(info) == TYPE_DICTIONARY:
			return int(info.get("points", 0))
	return 0

# ✅ Refresh points label
func refresh_points():
	var points = get_user_points()
	$HBoxContainer/PointCount.text = "points: " + str(points)

# ✅ Add points
func add_user_points(pointcount: int):
	var info = {}
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		info = JSON.parse_string(file.get_as_text())
		file.close()

	if typeof(info) != TYPE_DICTIONARY:
		info = {}

	var current = int(info.get("points", 0))
	info["points"] = current + pointcount

	var save_file = FileAccess.open(info_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(info, "\t"))
	save_file.close()

	print("Added", pointcount, "points to", folder_name)

# ✅ Subtract points
func take_user_points(pointcount: int):
	var info = {}
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		info = JSON.parse_string(file.get_as_text())
		file.close()

	if typeof(info) != TYPE_DICTIONARY:
		info = {}

	var current = int(info.get("points", 0))
	info["points"] = max(current - pointcount, 0)

	var save_file = FileAccess.open(info_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(info, "\t"))
	save_file.close()

	print("Took", pointcount, "points from", folder_name)

# ✅ Delete task (continued)
func delete_task_from_json(taskname: String):
	if not FileAccess.file_exists(task_path):
		return

	var file = FileAccess.open(task_path, FileAccess.READ)
	var task_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(task_data) != TYPE_ARRAY:
		return

	var updated_tasks = []
	for task in task_data:
		if typeof(task) == TYPE_DICTIONARY and task.get("name", "") != taskname:
			updated_tasks.append(task)

	var save_file = FileAccess.open(task_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(updated_tasks, "\t"))
	save_file.close()

	print("Deleted task:", taskname)
	refresh_tasks()

# ✅ Delete reward
func delete_reward_from_json(rewardname: String):
	if not FileAccess.file_exists(reward_path):
		return

	var file = FileAccess.open(reward_path, FileAccess.READ)
	var reward_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(reward_data) != TYPE_ARRAY:
		return

	var updated_rewards = []
	for reward in reward_data:
		if typeof(reward) == TYPE_DICTIONARY and reward.get("name", "") != rewardname:
			updated_rewards.append(reward)

	var save_file = FileAccess.open(reward_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(updated_rewards, "\t"))
	save_file.close()

	print("Deleted reward:", rewardname)
	refresh_rewards_list()

# ✅ Task button pressed
func on_task_pressed(taskname: String, points: int):
	print("Task pressed:", taskname, "worth", points, "points")
	add_user_points(points)
	refresh_points()
	refresh_rewards()

# ✅ Reward button pressed
func on_reward_pressed(rewardname: String, cost: int):
	print("Reward pressed:", rewardname, "costs", cost, "points")
	take_user_points(cost)
	refresh_points()
	refresh_rewards()

	# Look up the reward in the JSON to check its type
	if FileAccess.file_exists(reward_path):
		var file = FileAccess.open(reward_path, FileAccess.READ)
		var reward_data = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(reward_data) == TYPE_ARRAY:
			for reward in reward_data:
				if typeof(reward) == TYPE_DICTIONARY and reward.get("name", "") == rewardname:
					if reward.get("type", "") == "Timer":
						# duration is stored in minutes, default 10 minutes
						var minutes = int(reward.get("duration", 10))
						var duration_seconds = minutes * 60
						print("Starting global timer for", minutes, "minutes (", duration_seconds, "seconds )")
						Global.start_countdown(duration_seconds)
					break



# ✅ Home button
func _on_home_pressed():
	get_tree().change_scene_to_file("res://User Select.tscn")
