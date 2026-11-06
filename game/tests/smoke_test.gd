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
	assert(game.get("striker_catalog").size() == 24, "All 24 striker designs must load")

	var striker_rect: Rect2 = game.get("striker_button_rect")
	game.call("_handle_press", striker_rect.get_center())
	assert(game.get("selected_striker_index") == 1, "Striker selector must choose the next unlocked striker")
	var selected: Dictionary = game.call("_selected_striker")
	assert(float(selected.get("force", 0.0)) > 0.0, "Selected striker must expose Force")
	assert(float(selected.get("aim", 0.0)) > 0.0, "Selected striker must expose Aim")
	assert(float(selected.get("time", 0.0)) > 0.0, "Selected striker must expose Time")
	assert(is_equal_approx(float(game.get("turn_time_remaining")), float(selected["time"])), "Turn timer must use selected striker Time")

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

	# A normal drag-back gesture must start a shot after selecting the striker.
	game.call("reset_match")
	var striker_position: Vector2 = game.get("striker")["position"]
	game.call("_handle_press", striker_position)
	assert(game.get("aiming") == true, "Touching the placed striker must start aiming")
	game.call("_handle_release", striker_position + Vector2(0, 90))
	assert(game.get("shot_active") == true, "Releasing a pull-back shot must start physics")

	# Collision response must transfer most of the incoming speed to the struck disc.
	var moving_disc := {
		"position": Vector2.ZERO,
		"velocity": Vector2(100.0, 0.0),
		"radius": 10.0
	}
	var still_disc := {
		"position": Vector2(19.0, 0.0),
		"velocity": Vector2.ZERO,
		"radius": 10.0
	}
	game.call("_resolve_pair", moving_disc, still_disc)
	assert(float(still_disc["velocity"].x) > float(moving_disc["velocity"].x), "Disc collision must transfer velocity")

	# Turn time-out must pass the turn in local two-player mode.
	game.call("reset_match")
	game.set("local_two_player", true)
	game.set("turn_time_remaining", 0.01)
	game.call("_physics_process", 0.02)
	assert(game.get("player_turn") == 1, "Expired turn clock must pass the turn")

	# Potting an opponent disc is a foul and restores that disc before passing the turn.
	game.call("reset_match")
	var black_before := game.call("_count_owner", 1)
	var black_piece_index := -1
	var pieces: Array = game.get("pieces")
	for i in range(pieces.size()):
		if int(pieces[i]["owner"]) == 1:
			black_piece_index = i
			break
	assert(black_piece_index >= 0, "Black rack must contain a disc")
	pieces.remove_at(black_piece_index)
	game.set("pieces", pieces)
	game.set("shot_active", true)
	game.set("fouled_this_shot", true)
	game.set("potted_this_shot", [{"owner": 1, "kind": "disc"}])
	game.call("_complete_turn")
	assert(game.call("_count_owner", 1) == black_before, "Foul must restore the opponent disc")
	assert(game.get("player_turn") == 1, "Opponent-disc foul must pass the turn")

	# Profile settings must be writable to the device's user data folder.
	game.call("_save_profile")
	assert(FileAccess.file_exists("user://player_profile.json"), "Profile must be saved locally")

	print("SMOKE TEST PASSED: modes, board themes, strikers, stats, turn timer, touch shot, collision and local save")
	quit(0)
