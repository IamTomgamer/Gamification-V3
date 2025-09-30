extends Control
@onready var folder_name = UserState.current_user
@onready var info_path = "user://users/" + folder_name + "/info.json"

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
		var file = FileAccess.open("user://users/" + UserState.current_user + "/info.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(default_info, "\t"))
		file.close()
		print("Created missing info.json for", UserState.current_user)

func populate_tasks():
	pass

func populate_rewards():
	pass

func refresh_tasks():
	pass

func refresh_rewards():
	pass

func _ready():
	UserState.current_user = folder_name
	refresh_points()
