extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_tests")

func _run_smoke_tests() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	assert(packed != null, "Main scene could not be loaded.")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	assert(game.current_screen == 0, "Game should start at the home screen.")

	for level in range(1, game.LEVEL_COUNT + 1):
		game._start_level(level)
		var guard := 0
		while game._active_piece_count() > 0 and game.overlay == "" and guard < 240:
			var bolt_id: int = game._find_accessible_bolt()
			assert(bolt_id >= 0, "Level %d has no accessible bolt." % level)
			game._remove_bolt(bolt_id)
			assert(game.overlay != "failed", "Solver filled the tray on level %d." % level)
			guard += 1
		assert(game.overlay == "won", "Level %d did not clear in the smoke solver." % level)
		assert(game._active_piece_count() == 0, "Level %d still has active planks." % level)

	print("Boltwood smoke tests passed: all 30 levels cleared.")
	quit(0)
