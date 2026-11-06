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

	# The playable board and all touch controls must remain inside the viewport.
	var visible_board: Rect2 = game.get("board_rect")
	var visible_mode_button: Rect2 = game.get("game_mode_button_rect")
	var visible_player_button: Rect2 = game.get("mode_button_rect")
	var visible_board_button: Rect2 = game.get("board_button_rect")
	var visible_striker_button: Rect2 = game.get("striker_button_rect")
	var visible_reset_button: Rect2 = game.get("reset_rect")
	var visible_size: Vector2 = game.get_viewport_rect().size
	if not _check(visible_mode_button.position.y >= visible_board.end.y, "Mode selector must sit below the board"):
		return
	if not _check(visible_player_button.position.y >= visible_board.end.y, "Player selector must sit below the board"):
		return
	if not _check(visible_board_button.position.y >= visible_mode_button.end.y, "Board selector must sit below the mode row"):
		return
	if not _check(visible_striker_button.position.y >= visible_mode_button.end.y, "Striker selector must sit below the mode row"):
		return
	if not _check(visible_reset_button.position.y >= visible_board_button.end.y, "New Match must sit below the selector row"):
		return
	if not _check(visible_reset_button.end.y <= visible_size.y, "New Match button must remain on-screen"):
		return
	if not _check(visible_board.position.x >= 0.0 and visible_board.end.x <= visible_size.x, "Board must remain inside horizontal screen bounds"):
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

	# Precision Challenge is a solo mode with twelve gold targets and no opponent.
	game.call("_handle_press", game_mode_rect.get_center())
	if not _check(game.get("match_mode") == 2, "Game mode button must select Precision Challenge"):
		return
	if not _check(game.get("pieces").size() == 12 and int(game.call("_count_owner", 0)) == 12 and int(game.call("_count_owner", 1)) == 0, "Precision Challenge must create twelve solo targets"):
		return
	var challenge_player_rect: Rect2 = game.get("mode_button_rect")
	game.call("_handle_press", challenge_player_rect.get_center())
	if not _check(game.get("local_two_player") == false, "Precision Challenge must stay solo"):
		return
	game.set("turn_time_remaining", 0.01)
	game.call("_physics_process", 0.02)
	if not _check(game.get("player_turn") == 0 and float(game.get("turn_time_remaining")) > 0.0, "Challenge clock must reset without starting an AI turn"):
		return
	var no_targets_left: Array[Dictionary] = []
	game.set("pieces", no_targets_left)
	game.set("shot_active", true)
	game.set("own_piece_potted_this_shot", true)
	game.set("fouled_this_shot", false)
	game.set("queen_potted_this_shot", false)
	game.call("_complete_turn")
	if not _check(game.get("game_over") == true and String(game.get("status_text")).contains("cleared"), "Clearing all targets must complete the challenge"):
		return
	game.call("_handle_press", game_mode_rect.get_center())
	if not _check(game.get("match_mode") == 0 and game.get("pieces").size() == 19, "Mode cycle must return from challenge to Classic Carrom"):
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

	# Potting a valid own disc without a foul keeps the same player's turn.
	game.call("reset_match")
	var own_turn_pieces: Array = game.get("pieces")
	var own_turn_index := -1
	for i in range(own_turn_pieces.size()):
		if int(own_turn_pieces[i]["owner"]) == 0:
			own_turn_index = i
			break
	if not _check(own_turn_index >= 0, "A white disc must exist for the turn-retention test"):
		return
	own_turn_pieces.remove_at(own_turn_index)
	game.set("pieces", own_turn_pieces)
	var own_turn_records: Array[Dictionary] = [{"owner": 0, "kind": "disc"}]
	game.set("potted_this_shot", own_turn_records)
	game.set("own_piece_potted_this_shot", true)
	game.set("fouled_this_shot", false)
	game.set("shot_active", true)
	var own_turn_scores: Array = game.get("scores")
	own_turn_scores[0] = 1
	game.set("scores", own_turn_scores)
	game.call("_complete_turn")
	if not _check(game.get("player_turn") == 0, "A clean own-disc pot must retain the player's turn"):
		return

	# An uncovered queen must return to the centre and must not count as captured.
	game.call("reset_match")
	var queen_return_pieces: Array = game.get("pieces")
	var queen_return_index := -1
	for i in range(queen_return_pieces.size()):
		if int(queen_return_pieces[i]["owner"]) == 2:
			queen_return_index = i
			break
	if not _check(queen_return_index >= 0, "Classic mode must include a queen for the cover test"):
		return
	queen_return_pieces.remove_at(queen_return_index)
	game.set("pieces", queen_return_pieces)
	game.set("queen_potted_this_shot", true)
	game.set("own_piece_potted_this_shot", false)
	game.set("fouled_this_shot", false)
	game.set("shot_active", true)
	var no_cover_records: Array[Dictionary] = []
	game.set("potted_this_shot", no_cover_records)
	game.call("_complete_turn")
	if not _check(int(game.call("_count_owner", 2)) == 1, "An uncovered queen must return to the board"):
		return
	if not _check(game.get("queen_captured") == false, "An uncovered queen must not be marked captured"):
		return

	# A queen covered by the player's own disc is captured and awards three points.
	game.call("reset_match")
	var queen_cover_pieces: Array = game.get("pieces")
	var queen_cover_index := -1
	var cover_disc_index := -1
	for i in range(queen_cover_pieces.size()):
		if int(queen_cover_pieces[i]["owner"]) == 2:
			queen_cover_index = i
		elif int(queen_cover_pieces[i]["owner"]) == 0:
			cover_disc_index = i
	if not _check(queen_cover_index >= 0 and cover_disc_index >= 0, "Queen and white cover disc must exist"):
		return
	var remove_first := maxi(queen_cover_index, cover_disc_index)
	var remove_second := mini(queen_cover_index, cover_disc_index)
	queen_cover_pieces.remove_at(remove_first)
	queen_cover_pieces.remove_at(remove_second)
	game.set("pieces", queen_cover_pieces)
	game.set("queen_potted_this_shot", true)
	game.set("own_piece_potted_this_shot", true)
	game.set("fouled_this_shot", false)
	game.set("shot_active", true)
	var cover_records: Array[Dictionary] = [{"owner": 0, "kind": "disc"}]
	game.set("potted_this_shot", cover_records)
	var cover_scores: Array = game.get("scores")
	cover_scores[0] = 1
	game.set("scores", cover_scores)
	game.call("_complete_turn")
	if not _check(game.get("queen_captured") == true, "A covered queen must be marked captured"):
		return
	cover_scores = game.get("scores")
	if not _check(int(cover_scores[0]) == 4, "A covered queen must award exactly three bonus points"):
		return

	# AI difficulty selector must cycle and persist across local profile saves.
	game.call("reset_match")
	game.set("ai_difficulty", 1)
	var pause_menu_rect: Rect2 = game.get("reset_rect")
	game.call("_handle_press", pause_menu_rect.get_center())
	var difficulty_rect: Rect2 = game.get("difficulty_button_rect")
	game.call("_handle_press", difficulty_rect.get_center())
	if not _check(game.get("ai_difficulty") == 2 and String(game.call("_ai_difficulty_name")) == "Hard", "AI difficulty selector must cycle from Normal to Hard"):
		return
	game.call("_handle_press", difficulty_rect.get_center())
	if not _check(game.get("ai_difficulty") == 0, "AI difficulty selector must wrap from Hard to Easy"):
		return
	game.call("_handle_press", difficulty_rect.get_center())
	if not _check(game.get("ai_difficulty") == 1, "AI difficulty selector must return to Normal"):
		return
	var profile_file := FileAccess.open("user://player_profile.json", FileAccess.READ)
	if not _check(profile_file != null, "Difficulty selection must keep a readable local profile"):
		return
	var saved_profile = JSON.parse_string(profile_file.get_as_text())
	profile_file.close()
	if not _check(int(saved_profile.get("ai_difficulty", -1)) == 1, "AI difficulty must be stored in the player profile"):
		return
	game.call("_handle_press", pause_menu_rect.get_center())

	# Pause menu must freeze gameplay, resume safely and allow a deliberate new match.
	game.call("reset_match")
	var menu_button: Rect2 = game.get("reset_rect")
	game.call("_handle_press", menu_button.get_center())
	if not _check(game.get("is_paused") == true, "Pause/Menu control must open the pause overlay"):
		return
	var frozen_timer := float(game.get("turn_time_remaining"))
	game.call("_physics_process", 1.0)
	if not _check(is_equal_approx(float(game.get("turn_time_remaining")), frozen_timer), "Paused match must freeze the turn timer"):
		return
	var resume_button: Rect2 = game.get("resume_button_rect")
	game.call("_handle_press", resume_button.get_center())
	if not _check(game.get("is_paused") == false, "Resume control must close the pause overlay"):
		return
	game.call("_handle_press", menu_button.get_center())
	var new_match_button: Rect2 = game.get("pause_new_match_button_rect")
	game.call("_handle_press", new_match_button.get_center())
	if not _check(game.get("is_paused") == false and game.get("pieces").size() == 19, "New Match from pause menu must reset the board"):
		return

	# Pocket rings and hit sparks must be created, animated and removed safely.
	game.call("_spawn_pocket_effect", Vector2(120.0, 120.0), Color("#F1C978"))
	var effects_after_pocket: Array = game.get("visual_effects")
	if not _check(effects_after_pocket.size() == 1, "Pocketing a piece must create a visual ring effect"):
		return
	game.call("_process", 0.12)
	effects_after_pocket = game.get("visual_effects")
	if not _check(float(effects_after_pocket[0]["age"]) > 0.1, "Visual effects must animate with elapsed time"):
		return
	game.call("_spawn_impact_effect", Vector2(140.0, 140.0), 0.8)
	if not _check(game.get("visual_effects").size() == 7, "A strong collision must create a short spark burst"):
		return
	game.call("_process", 0.6)
	if not _check(game.get("visual_effects").is_empty(), "Expired visual effects must be cleaned up"):
		return

	game.call("_save_profile")
	if not _check(FileAccess.file_exists("user://player_profile.json"), "Profile must be saved locally"):
		return

	print("SMOKE TEST PASSED: modes, boards, strikers, stats, turn timer, touch shot, collision, AI aim, foul penalties, queen cover rules and local save, pause/resume flow, AI difficulty levels, Precision Challenge, animated collision sparks and pocket rings")
	quit(0)
