extends Control

@onready var user_list = $UserScroll/UserList
@onready var independentuser = "res://UserTypes/IndependantUser.tscn"
@onready var parentuser = "res://UserTypes/ParentUser.tscn"
@onready var childuser = "res://UserTypes/ChildUser.tscn"


@onready var popup = $CanvasLayer/ErrorPopup




func check_default_files():
	var missing = []

	var defaults_dir = "user://Defaults"
	var tasks_path = defaults_dir + "/Tasks.json"
	var rewards_path = defaults_dir + "/Rewards.json"

	if not DirAccess.dir_exists_absolute(defaults_dir):
		missing.append("Defaults folder")

	if not FileAccess.file_exists(tasks_path):
		missing.append("Tasks.json")

	if not FileAccess.file_exists(rewards_path):
		missing.append("Rewards.json")

	if not missing.is_empty():
		var message = (Global.app_name + " is missing some default files")
		popup.dialog_text = message
		popup.popup_centered()
		
		
func open_user_folder():
	var dir_path = ProjectSettings.globalize_path("user://")
	OS.shell_open(dir_path)


func create_default_files():
	var defaults_dir = "user://Defaults"
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("Defaults"):
		dir.make_dir("Defaults")

	# Create Tasks.json
	var tasks = [
		{"name": "Ask your parents to", "points": 0},
		{"name": "give you some tasks", "points": 0}
	]
	var task_file = FileAccess.open(defaults_dir + "/Tasks.json", FileAccess.WRITE)
	task_file.store_string(JSON.stringify(tasks, "\t"))
	task_file.close()

	# Create Rewards.json
	var rewards = [
		{"name": "Ask your parents to", "cost": 0, "type": "Normal"},
		{"name": "give you some rewards", "cost": 0, "type": "Normal"}
	]
	var reward_file = FileAccess.open(defaults_dir + "/Rewards.json", FileAccess.WRITE)
	reward_file.store_string(JSON.stringify(rewards, "\t"))
	reward_file.close()

	print("✅ Default files created")
	popup.hide()
	
	
	
@onready var countdown_label = $countdownlabel


func update_countdown(time_left: int):
	countdown_label.visible = time_left > 0
	# Format as mm:ss if you like
	var minutes = int(time_left / 60.0)
	var seconds = int(time_left % 60)
	countdown_label.text = "%02d:%02d" % [minutes, seconds]

func hide_countdown():
	countdown_label.visible = false


func _ready():
	check_default_files()
	var create_button = popup.add_button("Create Defaults", true, "create_defaults")
	popup.get_ok_button().text = "Open Folder"
	create_button.pressed.connect(create_default_files)

	popup.confirmed.connect(open_user_folder)
	populate_user_cards()
	Global.countdown_updated.connect(update_countdown)
	Global.countdown_finished.connect(hide_countdown)

	# If timer is already running when scene loads, show it
	if Global.timer_running:
		update_countdown(Global.countdown_time)
	else:
		countdown_label.visible = false




func populate_user_cards():
	var base_path = "user://users"
	var dir = DirAccess.open(base_path)
	var users = []

	if dir:
		dir.list_dir_begin()
		var folder_name = dir.get_next()
		while folder_name != "":
			if dir.current_is_dir() and not folder_name.begins_with("."):
				var user_path = base_path + "/" + folder_name
				var info_path = user_path + "/info.json"
				var pfp_path = user_path + "/pfp.png"

				if FileAccess.file_exists(info_path):
					var info_file = FileAccess.open(info_path, FileAccess.READ)
					var info_data = JSON.parse_string(info_file.get_as_text())
					info_file.close()

					if typeof(info_data) == TYPE_DICTIONARY:
						info_data["folder_name"] = folder_name
						info_data["pfp_path"] = pfp_path
						users.append(info_data)
			folder_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Could not open users directory")
		return

	# Sort users by age, then name
	users.sort_custom(func(a, b):
		var age_a = int(a.get("age", 0))
		var age_b = int(b.get("age", 0))
		if age_a == age_b:
			return str(a.get("name", "")).to_lower() < str(b.get("name", "")).to_lower()
		return age_a < age_b
	)

	# Create cards from sorted list
	for info_data in users:
		var card = preload("res://UserCard.tscn").instantiate()
		var folder_name = info_data["folder_name"]
		var user_name = info_data.get("name", folder_name)
		card.get_node("UserName").text = user_name

		card.get_node("UserName").connect(
			"pressed", Callable(self, "_on_user_selected").bind(folder_name)
		)
		card.get_node("ProfileImage/ImageButton").connect(
			"pressed", Callable(self, "_on_user_selected").bind(folder_name)
		)

		var pfp_path = info_data["pfp_path"]
		if FileAccess.file_exists(pfp_path):
			var image = Image.new()
			if image.load(pfp_path) == OK:
				var texture = ImageTexture.create_from_image(image)
				card.get_node("ProfileImage").texture = texture

		user_list.add_child(card)

	# Add "Add User" card last
	var add_card = preload("res://UserCard.tscn").instantiate()
	add_card.get_node("ProfileImage").texture = preload("res://Users/Photos/plus.png")
	add_card.get_node("UserName").text = "Add User"
	add_card.get_node("UserName").connect(
		"pressed", Callable(self, "_on_add_user_pressed")
	)
	user_list.add_child(add_card)

func _on_user_selected(folder_name: String):
	var info_path = "user://users/" + folder_name + "/info.json"
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var info = JSON.parse_string(json_text)
			file.close()

			if typeof(info) == TYPE_DICTIONARY:
				var username = info.get("name", "Unknown")
				var age = info.get("age", "Unknown")
				var role = info.get("role", "Unknown")
				print("Selected user:", username, " Age:", age, " Role:", role)
				if role == "Independant":
					get_tree().change_scene_to_file(independentuser)
				elif role == "Child":
					get_tree().change_scene_to_file(childuser)
				elif role == "Parent":
					get_tree().change_scene_to_file(parentuser)
				# You can now use this data however you want
				# For example: switch to dashboard, store user state, etc.
			else:
				print("Invalid JSON format in", info_path)
		else:
			print("Failed to open", info_path)
	else:
		print("info.json not found for user:", folder_name)
	UserState.current_user = folder_name
	print(UserState.current_user, " is selected")



func _on_add_user_pressed():
	get_tree().change_scene_to_file("res://UserCreation.tscn")
