extends SceneTree

func _fail(message: String) -> void:
    push_error("PRISM GROVE TEST FAILED: " + message)
    quit(1)

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        _fail("Main scene failed to load")
        return
    var game = packed.instantiate()
    root.add_child(game)
    await process_frame

    if game.board.size() != 8 or game.tray.size() != 3:
        _fail("Initial 8x8 board or three-piece tray is invalid")
        return
    if game.SHAPES.size() != 20 or game.PALETTES.size() != 4:
        _fail("Shape catalog or palette catalog is incomplete")
        return

    game.start_new_game(false)
    if not game.can_place([Vector2i(0,0), Vector2i(1,0)], 0, 0):
        _fail("An empty board should accept a valid shape")
        return
    game.board[0][0] = 1
    if game.can_place([Vector2i(0,0), Vector2i(1,0)], 0, 0):
        _fail("An occupied cell must reject placement")
        return
    if game.can_place([Vector2i(0,0)], 8, 0):
        _fail("Out-of-bounds placement must be rejected")
        return

    # A completed row and column are both cleared, including their shared cell once.
    game.start_new_game(false)
    for x in range(8):
        game.board[0][x] = 1
    for y in range(8):
        game.board[y][2] = 2
    if game.clear_full_lines() != 2:
        _fail("Simultaneous row and column clear must count as two lines")
        return
    for x in range(8):
        if int(game.board[0][x]) != -1:
            _fail("Completed row was not cleared")
            return
    for y in range(8):
        if int(game.board[y][2]) != -1:
            _fail("Completed column was not cleared")
            return

    # A valid placement scores, consumes its shape, and can be undone once.
    game.start_new_game(false)
    game.tray = [[Vector2i(0,0)], null, null]
    if not game.place_piece(0, 0, 0):
        _fail("A legal single-cell placement should succeed")
        return
    if int(game.board[0][0]) < 0 or game.score != 10:
        _fail("Placement should update the board and award shape points")
        return
    if not game.undo_last_move():
        _fail("The first undo should be available")
        return
    if int(game.board[0][0]) != -1 or game.score != 0 or not game.undo_used:
        _fail("Undo should restore board and score, and be consumed")
        return
    if game.undo_last_move():
        _fail("A round must not allow a second undo")
        return

    # Line clear scoring and daily deterministic seed.
    game.start_new_game(false)
    for x in range(1,8):
        game.board[0][x] = 3
    game.tray = [[Vector2i(0,0)], null, null]
    if not game.place_piece(0,0,0) or game.total_lines != 1 or game.score != 110:
        _fail("Completing a row should clear it and award line-clear points")
        return
    game.start_new_game(true)
    var first_daily_tray: Array = game.tray.duplicate(true)
    var first_daily_seed: int = game.daily_seed
    game.start_new_game(true)
    if game.daily_seed != first_daily_seed or game.tray != first_daily_tray:
        _fail("Daily challenge should be deterministic for the local date")
        return

    # Full board with remaining pieces is a game-over state.
    game.start_new_game(false)
    for y in range(8):
        for x in range(8):
            game.board[y][x] = 0
    if not game.is_game_over():
        _fail("A full board must be recognized as game over")
        return

    print("Prism Grove smoke tests passed: board, bounds, row/column clears, scoring, undo, daily seed, game-over.")
    quit(0)
