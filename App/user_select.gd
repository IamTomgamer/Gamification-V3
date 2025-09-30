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
						card.get_node("UserName").text = info_data.get("name", folder_name)
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

func _on_add_user_pressed():
	get_tree().change_scene_to_file("res://UserCreation.tscn")
