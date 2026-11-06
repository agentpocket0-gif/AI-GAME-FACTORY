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
	game.call("reset_match")
	await process_frame
	print("SMOKE TEST PASSED: scene loads and match reset succeeds")
	quit(0)
