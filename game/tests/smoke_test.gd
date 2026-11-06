extends SceneTree

func _check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("SMOKE TEST FAILED: " + message)
	quit(1)
	return false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if not _check(packed != null, "Main scene must load"):
		return

	var game := packed.instantiate()
	root.add_child(game)
	await process_frame

	if not _check(game.has_method("reset_match"), "Game controller must expose reset_match"):
		return
	if not _check(game.get("pieces").size() == 19, "Classic rack must contain 18 discs and the queen"):
		return
	if not _check(game.get("board_catalog").size() == 50, "All 50 board palettes must load"):
		return
	if not _check(game.get("striker_catalog").size() == 24, "All 24 striker designs must load"):
		return

	var striker_rect: Rect2 = game.get("striker_button_rect")
	game.call("_handle_press", striker_rect.get_center())
	if not _check(game.get("selected_striker_index") == 1, "Striker selector must choose the next unlocked striker"):
		return
	var selected: Dictionary = game.call("_selected_striker")
	if not _check(float(selected.get("force", 0.0)) > 0.0, "Selected striker must expose Force"):
		return
	if not _check(float(selected.get("aim", 0.0)) > 0.0, "Selected striker must expose Aim"):
		return
	if not _check(float(selected.get("time", 0.0)) > 0.0, "Selected striker must expose Time"):
		return
	if not _check(is_equal_approx(float(game.get("turn_time_remaining")), float(selected["time"])), "Turn timer must use selected striker Time"):
		return

	var game_mode_rect: Rect2 = game.get("game_mode_button_rect")
	game.call("_handle_press", game_mode_rect.get_center())
	if not _check(game.get("match_mode") == 1, "Game mode button must select Disc Pool"):
		return
	if not _check(game.get("pieces").size() == 12, "Disc Pool must contain twelve discs and no queen"):
		return

	game.call("_handle_press", game_mode_rect.get_center())
	if not _check(game.get("match_mode") == 0, "Game mode button must return to Classic"):
		return
	if not _check(game.get("pieces").size() == 19, "Classic must restore eighteen discs and queen"):
		return

	var player_mode_rect: Rect2 = game.get("mode_button_rect")
	game.call("_handle_press", player_mode_rect.get_center())
	if not _check(game.get("local_two_player") == true, "Player mode button must enable local two-player"):
		return

	var board_rect: Rect2 = game.get("board_button_rect")
	game.call("_handle_press", board_rect.get_center())
	if not _check(game.get("board_index") == 1, "Board button must switch to next theme"):
		return

	# A normal drag-back gesture must start a shot.
	game.call("reset_match")
	var striker_position: Vector2 = game.get("striker")["position"]
	game.call("_handle_press", striker_position)
	if not _check(game.get("aiming") == true, "Touching the placed striker must start aiming"):
		return
	game.call("_handle_release", striker_position + Vector2(0, 90))
	if not _check(game.get("shot_active") == true, "Releasing a pull-back shot must start physics"):
		return

	# Collision response must transfer incoming speed to the struck disc.
	var moving_disc: Dictionary = {
		"position": Vector2.ZERO,
		"velocity": Vector2(100.0, 0.0),
		"radius": 10.0
	}
	var still_disc: Dictionary = {
		"position": Vector2(19.0, 0.0),
		"velocity": Vector2.ZERO,
		"radius": 10.0
	}
	game.call("_resolve_pair", moving_disc, still_disc)
	if not _check(float(still_disc["velocity"].x) > float(moving_disc["velocity"].x), "Disc collision must transfer velocity"):
		return

	# Turn time-out must pass the turn in local two-player mode.
	game.call("reset_match")
	game.set("local_two_player", true)
	game.set("turn_time_remaining", 0.01)
	game.call("_physics_process", 0.02)
	if not _check(game.get("player_turn") == 1, "Expired turn clock must pass the turn"):
		return

	# Potting an opponent disc is a foul and restores that disc before passing the turn.
	game.call("reset_match")
	var black_before: int = int(game.call("_count_owner", 1))
	var black_piece_index: int = -1
	var current_pieces: Array = game.get("pieces")
	for i in range(current_pieces.size()):
		if int(current_pieces[i]["owner"]) == 1:
			black_piece_index = i
			break
	if not _check(black_piece_index >= 0, "Black rack must contain a disc"):
		return
	current_pieces.remove_at(black_piece_index)
	game.set("pieces", current_pieces)
	var foul_records: Array[Dictionary] = [{"owner": 1, "kind": "disc"}]
	game.set("shot_active", true)
	game.set("fouled_this_shot", true)
	game.set("potted_this_shot", foul_records)
	game.call("_complete_turn")
	if not _check(int(game.call("_count_owner", 1)) == black_before, "Foul must restore the opponent disc"):
		return
	if not _check(game.get("player_turn") == 1, "Opponent-disc foul must pass the turn"):
		return

	# The offline opponent should aim for a valid black-disc-to-pocket shot.
	game.call("reset_match")
	var bot_aim: Vector2 = game.call("_choose_bot_aim_point")
	var active_board: Rect2 = game.get("board_rect")
	if not _check(active_board.grow(-1.0).has_point(bot_aim), "AI aim point must stay inside the board"):
		return

	# A foul with no coin pocketed must return one previously banked player coin.
	game.call("reset_match")
	var player_pieces: Array = game.get("pieces")
	var removed_white := false
	for i in range(player_pieces.size()):
		if int(player_pieces[i]["owner"]) == 0:
			player_pieces.remove_at(i)
			removed_white = true
			break
	if not _check(removed_white, "A white disc must be available for the foul-penalty test"):
		return
	game.set("pieces", player_pieces)
	var stored_scores: Array = game.get("scores")
	stored_scores[0] = 1
	game.set("scores", stored_scores)
	game.set("shot_active", true)
	game.set("fouled_this_shot", true)
	var no_fouled_coins: Array[Dictionary] = []
	game.set("potted_this_shot", no_fouled_coins)
	game.set("own_potted_this_shot", false)
	game.call("_complete_turn")
	if not _check(int(game.call("_count_owner", 0)) == 9, "Foul penalty must restore a previously pocketed own disc"):
		return
	stored_scores = game.get("scores")
	if not _check(int(stored_scores[0]) == 0, "Foul penalty must subtract one banked point"):
		return

	game.call("_save_profile")
	if not _check(FileAccess.file_exists("user://player_profile.json"), "Profile must be saved locally"):
		return

	print("SMOKE TEST PASSED: modes, boards, strikers, stats, turn timer, touch shot, collision, AI pocket aim, foul penalties and local save")
	quit(0)
