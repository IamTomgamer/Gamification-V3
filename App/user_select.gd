extends Control

@onready var user_list = $UserScroll/UserList

func _ready():
	populate_user_cards()

func populate_user_cards():
	var base_path = "user://users"
	var dir = DirAccess.open(base_path)
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
						var card = preload("res://UserCard.tscn").instantiate()
						var user_name = info_data.get("name", folder_name)
						card.get_node("UserName").text = user_name
						card.get_node("UserName").connect("pressed", Callable(self, "_on_user_selected").bind(folder_name))

						card.get_node("ProfileImage/ImageButton").connect("pressed", Callable(self, "_on_user_selected").bind(folder_name))


						if FileAccess.file_exists(pfp_path):
							var image = Image.new()
							if image.load(pfp_path) == OK:
								var texture = ImageTexture.create_from_image(image)
								card.get_node("ProfileImage").texture = texture

						user_list.add_child(card)
			folder_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Could not open users directory")

	# Add User card
	var add_card = preload("res://UserCard.tscn").instantiate()
	add_card.get_node("ProfileImage").texture = preload("res://Users/Photos/plus.png")
	add_card.get_node("UserName").text = "Add User"
	add_card.get_node("UserName").connect("pressed", Callable(self, "_on_add_user_pressed"))
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
				var name = info.get("name", "Unknown")
				var age = info.get("age", "Unknown")
				var role = info.get("role", "Unknown")
				print("Selected user:", name, " Age:", age, " Role:", role)
				if role == "Independant":
					get_tree().change_scene_to_file("res://IndependantUser.tscn")
				elif role == "Child":
					get_tree().change_scene_to_file("res://ChildUser.tscn")
				elif role == "Parent":
					get_tree().change_scene_to_file("res://ParentUser.tscn")
				# You can now use this data however you want
				# For example: switch to dashboard, store user state, etc.
			else:
				print("Invalid JSON format in", info_path)
		else:
			print("Failed to open", info_path)
	else:
		print("info.json not found for user:", folder_name)



func _on_add_user_pressed():
	get_tree().change_scene_to_file("res://UserCreation.tscn")
