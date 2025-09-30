extends Control

@onready var user_list = $UserScroll/UserList

var users = []

func populate_user_cards():
	for user in users:
		var card = preload("res://UserCard.tscn").instantiate()
		card.get_node("ProfileImage").texture = load(user["image"])
		card.get_node("UserName").text = user["name"]
		user_list.add_child(card)

	var add_card = preload("res://UserCard.tscn").instantiate()
	add_card.get_node("ProfileImage").texture = load("res://Users/Photos/plus.png")
	add_card.get_node("UserName").text = "Add User"
	add_card.get_node("UserName").connect("pressed", Callable(self, "_on_add_user_pressed"))
	user_list.add_child(add_card)

func ensure_users_file_exists():
	var path = "user://users.json"
	if not FileAccess.file_exists(path):
		var default_users = [
			{
				"name": "Tom",
				"image": "res://Users/Photos/Tom.jpeg"
			}
		]
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(default_users, "\t")) # Pretty format with tabs
			file.close()
			print("Created new users.json at", path)
		else:
			print("Failed to create users.json")
	else:
		print("users.json already exists")

func _ready():
	ensure_users_file_exists()
	var file = FileAccess.open("user://Users/users.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var data = JSON.parse_string(json_text)
		if typeof(data) == TYPE_ARRAY:
			users = data
		else:
			print("Failed to parse JSON as array")
	else:
		print("Couldn't open users.json")
		
	for user in users:
		var card = preload("res://UserCard.tscn").instantiate()
		card.get_node("ProfileImage").texture = user.image
		card.get_node("UserName").text = user.name
		user_list.add_child(card)

	# Add User card
	var add_card = preload("res://UserCard.tscn").instantiate()
	add_card.get_node("ProfileImage").texture = preload("res://Users/Photos/plus.png")
	add_card.get_node("UserName").text = "Add User"
	add_card.get_node("UserName").connect("pressed", Callable(self, "_on_add_user_pressed"))
	user_list.add_child(add_card)

func _on_add_user_pressed():
	print("Add User button clicked!")
	# You can open a popup, show a form, or switch scenes here
