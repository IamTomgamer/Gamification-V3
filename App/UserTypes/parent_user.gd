extends Control

@onready var folder_name = UserState.current_user
@onready var selected_child = UserState.current_child
@onready var info_path = "user://users/" + folder_name + "/info.json"
@onready var task_path = "user://users/" + selected_child + "/Tasks.json"
@onready var reward_path = "user://users/" + selected_child + "/Rewards.json"

@onready var task_button = preload("res://Tasks.tscn")
@onready var reward_button = preload("res://Rewards.tscn")

@onready var task_list = $Tasks_Rewards/TasksAndRewards/Tasks/Tasks/Tasks
@onready var reward_list = $Tasks_Rewards/TasksAndRewards/Rewards/Rewards/Rewards

@onready var task_name_input = $Tasks_Rewards/TasksAndRewards/Tasks/TaskName
@onready var task_points_input = $Tasks_Rewards/TasksAndRewards/Tasks/Points_AddTask/PointCount
@onready var add_task_button = $Tasks_Rewards/TasksAndRewards/Tasks/Points_AddTask/AddTask

@onready var reward_name_input = $Tasks_Rewards/TasksAndRewards/Rewards/RewardName
@onready var reward_cost_input = $Tasks_Rewards/TasksAndRewards/Rewards/Price_AddReward/Price
@onready var add_reward_button = $Tasks_Rewards/TasksAndRewards/Rewards/Price_AddReward/AddReward

@onready var left_button = $Tasks_Rewards/VBoxContainer2/VBoxContainer/HBoxContainer/MarginContainer/LeftButton
@onready var right_button = $Tasks_Rewards/VBoxContainer2/VBoxContainer/HBoxContainer/MarginContainer2/RightButton
@onready var child_photo = $Tasks_Rewards/VBoxContainer2/VBoxContainer/HBoxContainer/ChildPhoto

var child_users: Array = []
var current_child_index: int = 0

func activate_reward_deletion():
	pass

func _ready():
	load_child_users()  # this now handles setting the child and loading data
	left_button.pressed.connect(switch_child_left)
	right_button.pressed.connect(switch_child_right)
	add_task_button.pressed.connect(add_task_from_input)
	add_reward_button.pressed.connect(add_reward_from_input)
	refresh_points()
	activate_reward_deletion()


func load_child_users():
	var dir = DirAccess.open("user://users")
	if dir == null:
		print("Failed to open user directory")
		return

	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if dir.current_is_dir():
			var infopath = "user://users/" + filename + "/info.json"
			if FileAccess.file_exists(infopath):
				var file = FileAccess.open(infopath, FileAccess.READ)
				var info = JSON.parse_string(file.get_as_text())
				file.close()
				if typeof(info) == TYPE_DICTIONARY and info.get("role", "") == "Child":
					child_users.append(filename)
		filename = dir.get_next()
	dir.list_dir_end()

	if child_users.size() > 0:
		current_child_index = 0
		UserState.current_child = child_users[current_child_index]
		refresh_points()
		update_child_display()
	update_child_display()  # this sets the child and loads tasks/rewards

@onready var name_label = $Tasks_Rewards/VBoxContainer2/VBoxContainer/VBoxContainer/ChildName
@onready var age_label = $Tasks_Rewards/VBoxContainer2/VBoxContainer/VBoxContainer/Age


func update_child_display():
	if child_users.size() == 0:
		child_photo.texture = null
		return

	var child_name = child_users[current_child_index]
	UserState.current_child = child_name
	refresh_points()

	var photo_path = "user://users/" + child_name + "/pfp.png"
	if FileAccess.file_exists(photo_path):
		var image = Image.new()
		var err = image.load(photo_path)
		if err == OK:
			var texture = ImageTexture.create_from_image(image)
			child_photo.texture = texture
		else:
			print("Failed to load image for", child_name)
	else:
		child_photo.texture = null

	selected_child = child_name
	task_path = "user://users/" + selected_child + "/Tasks.json"
	reward_path = "user://users/" + selected_child + "/Rewards.json"
	# Update name and age labels
	var info__path = "user://users/" + UserState.current_child + "/info.json"
	if FileAccess.file_exists(info__path):
		var file = FileAccess.open(info__path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(info) == TYPE_DICTIONARY:
			name_label.text = str(info.get("name", "Unknown"))
			age_label.text = str(info.get("age", "N/A")) + " y/o"
	else:
		name_label.text = "Name: Unknown"
		age_label.text = "Age: N/A"

	refresh_tasks()
	refresh_rewards_list()

func switch_child_left():
	if child_users.size() == 0:
		return
	current_child_index = (current_child_index - 1 + child_users.size()) % child_users.size()
	update_child_display()

func switch_child_right():
	if child_users.size() == 0:
		return
	current_child_index = (current_child_index + 1) % child_users.size()
	update_child_display()

func add_task_from_input():
	var taskname = task_name_input.text.strip_edges()
	var points_text = task_points_input.text.strip_edges()

	if taskname == "" or points_text == "":
		print("Task name or points missing")
		return

	var points = int(points_text)
	var new_task = {
		"name": taskname,
		"points": points
	}

	var tasks = []
	if FileAccess.file_exists(task_path):
		var file = FileAccess.open(task_path, FileAccess.READ)
		tasks = JSON.parse_string(file.get_as_text())
		file.close()

	if typeof(tasks) != TYPE_ARRAY:
		tasks = []

	tasks.append(new_task)

	var save_file = FileAccess.open(task_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(tasks, "\t"))
	save_file.close()

	print("Added new task:", taskname, "with", points, "points")

	task_name_input.text = ""
	task_points_input.text = ""
	refresh_tasks()

func add_reward_from_input():
	var rewardname = reward_name_input.text.strip_edges()
	var cost_text = reward_cost_input.text.strip_edges()

	if rewardname == "" or cost_text == "":
		print("Reward name or cost missing")
		return

	var cost = int(cost_text)
	var new_reward = {
		"name": rewardname,
		"cost": cost
	}

	var rewards = []
	if FileAccess.file_exists(reward_path):
		var file = FileAccess.open(reward_path, FileAccess.READ)
		rewards = JSON.parse_string(file.get_as_text())
		file.close()

	if typeof(rewards) != TYPE_ARRAY:
		rewards = []

	rewards.append(new_reward)

	var save_file = FileAccess.open(reward_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(rewards, "\t"))
	save_file.close()

	print("Added new reward:", rewardname, "costing", cost, "points")

	reward_name_input.text = ""
	reward_cost_input.text = ""
	refresh_rewards_list()

func load_tasks():
	if not FileAccess.file_exists(task_path):
		print("No tasks.json found for ", selected_child)
		return

	var file = FileAccess.open(task_path, FileAccess.READ)
	var task_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(task_data) != TYPE_ARRAY:
		print("Invalid tasks.json format")
		return

	task_data.sort_custom(Callable(self, "compare_tasks"))

	for task in task_data:
		if typeof(task) == TYPE_DICTIONARY:
			populate_tasks(task)

func load_rewards():
	if not FileAccess.file_exists(reward_path):
		print("No rewards.json found for ", selected_child)
		return

	var file = FileAccess.open(reward_path, FileAccess.READ)
	var reward_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(reward_data) != TYPE_ARRAY:
		print("Invalid rewards.json format")
		return

	reward_data.sort_custom(Callable(self, "compare_rewards"))

	for reward in reward_data:
		if typeof(reward) == TYPE_DICTIONARY:
			populate_rewards(reward)

func compare_tasks(a, b) -> bool:
	return int(a.get("points", 0)) < int(b.get("points", 0))

func compare_rewards(a, b) -> bool:
	return int(a.get("cost", 0)) < int(b.get("cost", 0))

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

func populate_rewards(reward: Dictionary):
	var row = reward_button.instantiate()
	var rewardname = reward.get("name", "Unnamed Reward")
	var cost = reward.get("cost", 0)
	var info_path = "user://users/" + UserState.current_user + "/info.json"
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(info) == TYPE_DICTIONARY and info.get("role", "") == "Parent":
			var target_node = row.get_node("ParentOnlyNode")
			if target_node:
				target_node.visible = true
			else:
				pass


	var button = row.get_node("RewardButton")
	button.text = "%s\nPoints: %s" % [rewardname, str(cost)]

	var user_points = get_user_points()
	button.disabled = cost > user_points

	button.pressed.connect(func():
		on_reward_pressed(rewardname, cost)
	)

	var delete_button = row.get_node("DeleteButton")
	delete_button.pressed.connect(func():
		delete_reward_from_json(rewardname)
		row.queue_free()
	)

	reward_list.add_child(row)

func refresh_rewards():
	var user_points = get_user_points()

	for row in reward_list.get_children():
		var button = row.get_node_or_null("RewardButton")
		if button:
			var label_text = button.text
			var parts = label_text.split("\nPoints: ")
			if parts.size() == 2:
				var cost = int(parts[1])
				button.disabled = cost > user_points

func refresh_tasks():
	for child in task_list.get_children():
		child.queue_free()
	load_tasks()

func refresh_rewards_list():
	for child in reward_list.get_children():
		child.queue_free()
	load_rewards()

func get_child_info_path() -> String:
	return "user://users/" + UserState.current_child + "/info.json"

func get_user_points() -> int:
	var path = get_child_info_path()
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()
		if typeof(info) == TYPE_DICTIONARY:
			return int(info.get("points", 0))
	return 0



func refresh_points():
	var points = get_user_points()
	$Tasks_Rewards/VBoxContainer2/VBoxContainer/VBoxContainer/PointCount.text = "points: " + str(points)

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

func on_task_pressed(taskname: String, points: int):
	print("Task pressed:", taskname, "worth", points, "points")
	add_user_points(points)
	refresh_points()
	refresh_rewards()

func on_reward_pressed(rewardname: String, cost: int):
	print("Reward pressed:", rewardname, "costs", cost, "points")
	take_user_points(cost)
	refresh_points()
	refresh_rewards()

func _on_home_pressed():
	get_tree().change_scene_to_file("res://User Select.tscn")
