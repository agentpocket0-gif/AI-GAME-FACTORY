extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "Main scene must load")

	var game := packed.instantiate()
	root.add_child(game)
	await process_frame

	assert(game.has_method("reset_match"), "Game controller must expose reset_match")
	assert(game.get("pieces").size() == 19, "Classic rack must contain 18 discs and the queen")
	assert(game.get("board_catalog").size() == 50, "All 50 board palettes must load")

	var game_mode_rect: Rect2 = game.get("game_mode_button_rect")
	game.call("_handle_press", game_mode_rect.get_center())
	assert(game.get("match_mode") == 1, "Game mode button must select Disc Pool")
	assert(game.get("pieces").size() == 12, "Disc Pool must contain twelve discs and no queen")

	game.call("_handle_press", game_mode_rect.get_center())
	assert(game.get("match_mode") == 0, "Game mode button must return to Classic")
	assert(game.get("pieces").size() == 19, "Classic must restore eighteen discs and queen")

	var player_mode_rect: Rect2 = game.get("mode_button_rect")
	game.call("_handle_press", player_mode_rect.get_center())
	assert(game.get("local_two_player") == true, "Player mode button must enable local two-player")

	var board_rect: Rect2 = game.get("board_button_rect")
	game.call("_handle_press", board_rect.get_center())
	assert(game.get("board_index") == 1, "Board button must switch to next theme")

	game.call("reset_match")
	await process_frame
	assert(game.get("pieces").size() == 19, "Reset must restore the full Classic rack")
	assert(game.get("player_turn") == 0, "Reset must return the first turn to player one")

	var profile_path := "user://player_profile.json"
	assert(FileAccess.file_exists(profile_path) or game.has_method("_save_profile"), "Profile save handler must exist")
	game.call("_save_profile")

	print("SMOKE TEST PASSED: Classic, Disc Pool, local mode, 50 boards and profile save")
	quit(0)
