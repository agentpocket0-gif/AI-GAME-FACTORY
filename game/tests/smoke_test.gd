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
	assert(game.get("pieces").size() == 19, "A new board must contain 18 discs and the queen")
	assert(game.get("board_catalog").size() == 50, "All 50 board palettes must load")

	var mode_rect: Rect2 = game.get("mode_button_rect")
	game.call("_handle_press", mode_rect.get_center())
	assert(game.get("local_two_player") == true, "Mode button must enable local two-player mode")

	var board_rect: Rect2 = game.get("board_button_rect")
	game.call("_handle_press", board_rect.get_center())
	assert(game.get("board_index") == 1, "Board button must switch to the next theme")

	game.call("reset_match")
	await process_frame
	assert(game.get("pieces").size() == 19, "Reset must restore the complete rack")
	assert(game.get("player_turn") == 0, "Reset must return the first turn to player one")

	print("SMOKE TEST PASSED: scene, rack, 50 boards, local mode and reset")
	quit(0)
