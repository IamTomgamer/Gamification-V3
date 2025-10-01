extends Control

@onready var pfp_dialog = $RightSide/PfpDialog
@onready var upload_button = $RightSide/UploadButton
@onready var pfp_zone = $RightSide/PfpDropZone

@onready var name_field = $LeftSide/Name
@onready var age_field = $LeftSide/Age
@onready var create_button = $"RightSide/Save User"

@onready var ownrewardsq = $LeftSide/HBoxContainer/OptionButton



func files_dropped(files: PackedStringArray):
	print("Files dropped:", files)
	print("Saving to: user://Temp/pfp.png")
	for file_path in files:
		if file_path.ends_with(".png") or file_path.ends_with(".jpg") or file_path.ends_with(".jpeg") or file_path.ends_with(".webp"):
			var image = Image.new()
			var err = image.load(file_path)
			if err == OK:
				var texture = ImageTexture.create_from_image(image)
				pfp_zone.texture = texture

				if not DirAccess.dir_exists_absolute("user://Temp"):
					DirAccess.make_dir_absolute("user://Temp")

				var save_err = image.save_png("user://Temp/pfp.png")
				if save_err == OK:
					print("Saved PFP to Temp")
				else:
					print("Failed to save image to Temp:", save_err)
			else:
				print("Failed to load image:", file_path)


func _on_upload_button_pressed():
	pfp_dialog.popup_centered()

func _on_pfp_selected(path: String):
	var image = Image.new()
	var err = image.load(path)
	if err == OK:
		var texture = ImageTexture.create_from_image(image)
		pfp_zone.texture = texture

		if not DirAccess.dir_exists_absolute("user://Temp"):
			DirAccess.make_dir_absolute("user://Temp")

		var save_err = image.save_png("user://Temp/pfp.png")
		if save_err == OK:
			print("Saved PFP to Temp")
		else:
			print("Failed to save image to Temp:", save_err)
	else:
		print("Failed to load image:", path)

func _ready():

	pfp_dialog.file_selected.connect(_on_pfp_selected)
	print("UserCreation ready. Waiting for file drop...")


# Show error popup


# Called if folder already exists
func _on_user_folder_exists(user_name: String, _path: String):
	Global.show_error("User '" + user_name + "' already exists.", $"../../CanvasLayer/ErrorPopup")

# Called after folder is created
func _on_user_folder_created(user_name: String, user_path: String):
	print("User '" + user_name + "' created successfully at:", user_path)
	_move_pfp_to_user_folder(user_path)
	get_tree().change_scene_to_file("res://User Select.tscn")



func update_user_points(folder_name: String, new_points: int):
	var info_path = "user://users/" + folder_name + "/info.json"
	if FileAccess.file_exists(info_path):
		var file = FileAccess.open(info_path, FileAccess.READ)
		var info = JSON.parse_string(file.get_as_text())
		file.close()

		if typeof(info) == TYPE_DICTIONARY:
			info["points"] = new_points
			var save_file = FileAccess.open(info_path, FileAccess.WRITE)
			save_file.store_string(JSON.stringify(info, "\t"))
			save_file.close()
			print("Updated points for", folder_name, "to", new_points)
		else:
			print("Invalid info.json format")
	else:
		print("info.json not found for", folder_name)

# Create user data files
func _create_user_files(user_name: String, age: String, user_path: String):
	var info = {
		"name": user_name,
		"age": age,
		"role": "Child",
		"points": 0}
	var info_file = FileAccess.open(user_path + "/info.json", FileAccess.WRITE)
	if info_file:
		info_file.store_string(JSON.stringify(info, "\t"))
		info_file.close()
	else:
		print("Failed to create info.json")

	
	var rewards_file = FileAccess.open(user_path + "/Rewards.json", FileAccess.WRITE)
	if rewards_file:
		rewards_file.store_string(JSON.stringify([], "\t"))
		rewards_file.close()
	else:
		print("Failed to create Rewards.json")

# Move PFP from Temp to user folder
func _move_pfp_to_user_folder(user_path: String):
	print("Checking for temp PFP:", FileAccess.file_exists("user://Temp/pfp.png"))
	var temp_path = "user://Temp/pfp.png"
	var final_path = user_path + "/pfp.png"

	if not DirAccess.dir_exists_absolute("user://Temp"):
		DirAccess.make_dir_absolute("user://Temp")

	if FileAccess.file_exists(temp_path):
		var err = DirAccess.rename_absolute(temp_path, final_path)
		if err == OK:
			print("Moved PFP to:", final_path)
		else:
			print("Failed to move PFP:", err)
	else:
		print("No temp PFP found to move.")

# Save user logic
func _on_save_user_pressed():
	var user_name = name_field.text.strip_edges()
	var user_age = age_field.text.strip_edges()
	var ownrewardsynchoice = ownrewardsq.get_item_text(ownrewardsq.selected)


	if user_name == "":
		Global.show_error("Name is empty. Cannot create folder.", $"../../CanvasLayer/ErrorPopup")
		return

	var base_path = "user://users"
	var user_path = base_path + "/" + user_name


	if not DirAccess.dir_exists_absolute(base_path):
		var base_err = DirAccess.make_dir_absolute(base_path)
		if base_err != OK:
			Global.show_error("Could not create base folder.", $"../../CanvasLayer/ErrorPopup")
			return

	if DirAccess.dir_exists_absolute(user_path):
		_on_user_folder_exists(user_name, user_path)
	else:
		var err = DirAccess.make_dir_absolute(user_path)
		if err == OK:
			_create_user_files(user_name, user_age, user_path)
			_on_user_folder_created(user_name, user_path)
		else:
			Global.show_error("Could not create user folder.", $"../../CanvasLayer/ErrorPopup")
	if ownrewardsq.get_item_text(ownrewardsq.selected) == "Yes":
		print("You chose Yes")
	else:
		print("You chose No")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://User Select.tscn")
