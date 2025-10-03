extends TextureRect

var temp_path := "user://Temp/pfp.png"



func _on_files_dropped(files: PackedStringArray):
	for file_path in files:
		print("Dropped file:", file_path)
		if file_path.ends_with(".png") or file_path.ends_with(".jpg") or file_path.ends_with(".jpeg") or file_path.ends_with(".webp"):
			var image = Image.new()
			var err = image.load(file_path)
			if err == OK:
				var texture_on_fi_dr = ImageTexture.create_from_image(image)
				$TabContainer/Individual/LeftSide/PfpDropZone.texture = texture_on_fi_dr

				# Save to Temp
				if not DirAccess.dir_exists_absolute("user://Temp"):
					DirAccess.make_dir_absolute("user://Temp")
				image.save_png("user://Temp/pfp.png")
				print("Saved PFP to Temp")
			else:
				print("Failed to load image:", file_path)
