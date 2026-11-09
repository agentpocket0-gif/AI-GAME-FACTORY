extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_tests")

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _run_smoke_tests() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Main scene could not be loaded.")
		return

	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	if game.get_script() == null:
		_fail("Main game script did not compile or attach.")
		return
	if game.current_screen != 0:
		_fail("Game should start at the home screen.")
		return

	for level in range(1, game.LEVEL_COUNT + 1):
		game._start_level(level)
		var guard := 0
		while game._active_piece_count() > 0 and game.overlay == "" and guard < 240:
			var bolt_id: int = game._find_topmost_accessible_bolt()
			if bolt_id < 0:
				_fail("Level %d has no accessible bolt." % level)
				return
			game._remove_bolt(bolt_id)
			if game.overlay == "failed":
				_fail("Solver filled the tray on level %d." % level)
				return
			guard += 1
		if game.overlay != "won":
			_fail("Level %d did not clear in the smoke solver (guard=%d, active=%d)." % [level, guard, game._active_piece_count()])
			return
		if game._active_piece_count() != 0:
			_fail("Level %d still has active planks." % level)
			return

	print("Boltwood smoke tests passed: all 30 levels cleared.")
	quit(0)
