extends Control

@onready var folder_name = UserState.current_user
@onready var info_path = "user://users/" + folder_name + "/info.json"
@onready var task_button = preload("res://Tasks.tscn")
@onready var task_list = $Tasks_Rewards/Tasks/Tasks/Tasks
@onready var reward_list = $Tasks_Rewards/Rewards/Rewards/Rewards
@onready var task_path = "user://users/" + folder_name + "/tasks.json"
@onready var reward_path = "user://users/" + folder_name + "/rewards.json"
@onready var reward_button = preload("res://Rewards.tscn")
func _on_home_pressed():
	get_tree().change_scene_to_file("res://User Select.tscn")

func add_user_points(pointcount: int):
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(info) == TYPE_DICTIONARY:
			var current = int(info.get("points", 0))
			info["points"] = current + pointcount
			var save_file = FileAccess.open(info_path, FileAccess.WRITE)
			save_file.store_string(JSON.stringify(info, "\t"))
			save_file.close()
			print("Added", pointcount, "points to", folder_name)

func take_user_points(pointcount: int):
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(info) == TYPE_DICTIONARY:
			var current = int(info.get("points", 0))
			info["points"] = max(current - pointcount, 0)
			var save_file = FileAccess.open(info_path, FileAccess.WRITE)
			save_file.store_string(JSON.stringify(info, "\t"))
			save_file.close()
			print("Took", pointcount, "points from", folder_name)

func refresh_points():
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(info) == TYPE_DICTIONARY:
			var points = int(info.get("points", 0))
			$HBoxContainer/PointCount.text = "points: " + str(points)
	else:
		var default_info = {
			"name": UserState.current_user,
			"age": 0,
			"points": 0,
			"role": "Independent"
		}
		var file = FileAccess.open(info_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(default_info, "\t"))
		file.close()
		print("Created missing info.json for", UserState.current_user)

func populate_tasks(task: Dictionary):
	var row = task_button.instantiate()
	var taskname = task.get("name", "Unnamed Task")
	var points = task.get("points", 0)

	var button = row.get_node("TaskButton")
	button.text = "%s\nPoints: %s" % [taskname, str(points)]

	# Connect button press to a custom function
	button.pressed.connect(func():
		on_task_pressed(taskname, points)
	)

	# Connect delete button
	var delete_button = row.get_node("DeleteButton")
	delete_button.pressed.connect(func():
		delete_task_from_json(taskname)
		row.queue_free()
	)
	task_list.add_child(row)

func delete_task_from_json(taskname: String):
	if not FileAccess.file_exists(task_path):
		print("No tasks.json found")
		return

	var file = FileAccess.open(task_path, FileAccess.READ)
	var task_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(task_data) != TYPE_ARRAY:
		print("Invalid tasks.json format")
		return

	var updated_tasks = []
	for task in task_data:
		if typeof(task) == TYPE_DICTIONARY and task.get("name", "") != taskname:
			updated_tasks.append(task)

	var save_file = FileAccess.open(task_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(updated_tasks, "\t"))
	save_file.close()

	print("Deleted task:", taskname)

func load_tasks():
	if not FileAccess.file_exists(task_path):
		print("No tasks.json found for", UserState.current_user)
		return

	var file = FileAccess.open(task_path, FileAccess.READ)
	var task_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(task_data) != TYPE_ARRAY:
		print("Invalid tasks.json format")
		return

	for task in task_data:
		if typeof(task) == TYPE_DICTIONARY:
			populate_tasks(task)

func load_rewards():
	if not FileAccess.file_exists(reward_path):
		print("No rewards.json found for", UserState.current_user)
		return

	var file = FileAccess.open(reward_path, FileAccess.READ)
	var reward_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(reward_data) != TYPE_ARRAY:
		print("Invalid tasks.json format")
		return

	for reward in reward_data:
		if typeof(reward) == TYPE_DICTIONARY:
			populate_rewards(reward)

func delete_reward_from_json(rewardname: String):
	if not FileAccess.file_exists(reward_path):
		print("No rewards.json found")
		return

	var file = FileAccess.open(reward_path, FileAccess.READ)
	var reward_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(reward_data) != TYPE_ARRAY:
		print("Invalid tasks.json format")
		return

	var updated_rewards = []
	for reward in reward_data:
		if typeof(reward) == TYPE_DICTIONARY and reward.get("name", "") != rewardname:
			updated_rewards.append(reward)

	var save_file = FileAccess.open(task_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(updated_rewards, "\t"))
	save_file.close()

	print("Deleted task:", rewardname)


func on_task_pressed(taskname: String, points: int):
	print("Task pressed: ", taskname, ", worth ", points, " points")
	add_user_points(points)
	refresh_points()
	refresh_rewards()

func on_reward_pressed(rewardname: String, points: int):
	print("Reward pressed: ", rewardname, ", worth ", points, " points")
	take_user_points(points)
	refresh_points()
	refresh_rewards()

func populate_rewards(reward: Dictionary):
	var row = reward_button.instantiate()
	var rewardname = reward.get("name", "Unnamed Reward")
	var cost = reward.get("cost", 0)

	var button = row.get_node("RewardButton")
	button.text = "%s\nPoints: %s" % [rewardname, str(cost)]

	# Get current user points
	var user_points = 0
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(info) == TYPE_DICTIONARY:
			user_points = int(info.get("points", 0))

	# Disable button if user can't afford it
	if cost > user_points:
		button.disabled = true
	# Connect button press to a custom function
	button.pressed.connect(func():
		on_reward_pressed(rewardname, cost)
	)

	# Connect delete button
	var delete_button = row.get_node("DeleteButton")
	delete_button.pressed.connect(func():
		delete_reward_from_json(rewardname)
		row.queue_free()
	)
	reward_list.add_child(row)


func refresh_tasks():
	pass

func refresh_rewards():
	var user_points = 0
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(info) == TYPE_DICTIONARY:
			user_points = int(info.get("points", 0))

	# Loop through all reward rows
	for row in reward_list.get_children():
		var button = row.get_node_or_null("RewardButton")
		if button:
			var label_text = button.text
			var parts = label_text.split("\nPoints: ")
			if parts.size() == 2:
				var cost = int(parts[1])
				button.disabled = cost > user_points


func _ready():
	refresh_points()
	load_tasks()
	load_rewards()
