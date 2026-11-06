extends Node2D
class_name CarromGame

const WHITE := 0
const BLACK := 1
const QUEEN := 2
const MODE_CLASSIC := 0
const MODE_DISC_POOL := 1
const FRICTION := 2.65
const RESTITUTION := 0.91
const STOP_SPEED := 7.0

var pieces: Array[Dictionary] = []
var striker: Dictionary = {}
var board_catalog: Array = []
var striker_catalog: Array = []
var board_index := 0
var selected_striker_index := 0
var turn_time_remaining := 20.0
var local_two_player := false
var match_mode := MODE_CLASSIC
var matches_played := 0
var matches_won := 0
var practice_xp := 0
var potted_this_shot: Array[Dictionary] = []
var board_rect := Rect2()
var board_size := 640.0
var pocket_radius := 40.0
var piece_radius := 13.0
var striker_radius := 20.0
var striker_spawn := Vector2.ZERO
var player_turn := WHITE
var scores := [0, 0]
var aiming := false
var aim_start := Vector2.ZERO
var aim_current := Vector2.ZERO
var shot_active := false
var stop_timer := 0.0
var bot_delay := -1.0
var fouled_this_shot := false
var own_piece_potted_this_shot := false
var queen_potted_this_shot := false
var queen_captured := false
var game_over := false
var status_text := "Drag back from the striker, then release to shoot."
var reset_rect := Rect2()
var board_button_rect := Rect2()
var mode_button_rect := Rect2()
var game_mode_button_rect := Rect2()
var striker_button_rect := Rect2()

func _ready() -> void:
	_load_board_catalog()
	_load_striker_catalog()
	_load_profile()
	_refresh_geometry()
	get_viewport().size_changed.connect(_on_viewport_resized)
	reset_match()

func _on_viewport_resized() -> void:
	_refresh_geometry()
	reset_match()

func _load_board_catalog() -> void:
	var file := FileAccess.open("res://data/board_catalog.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		board_catalog = parsed

func _refresh_geometry() -> void:
	var view := get_viewport_rect().size
	board_size = minf(view.x * 0.86, view.y * 0.49)
	board_size = maxf(390.0, board_size)
	var origin := Vector2((view.x - board_size) * 0.5, (view.y - board_size) * 0.52)
	board_rect = Rect2(origin, Vector2(board_size, board_size))
	pocket_radius = board_size * 0.064
	piece_radius = board_size * 0.018
	striker_radius = board_size * 0.028
	striker_spawn = Vector2(board_rect.get_center().x, board_rect.position.y + board_size * 0.81)
	reset_rect = Rect2(Vector2(view.x * 0.5 - 125.0, view.y - 100.0), Vector2(250.0, 58.0))
	board_button_rect = Rect2(Vector2(view.x * 0.25 - 112.0, view.y - 180.0), Vector2(224.0, 56.0))
	striker_button_rect = Rect2(Vector2(view.x * 0.75 - 112.0, view.y - 180.0), Vector2(224.0, 56.0))
	mode_button_rect = Rect2(Vector2(view.x * 0.25 - 112.0, view.y - 260.0), Vector2(224.0, 56.0))
	game_mode_button_rect = Rect2(Vector2(view.x * 0.75 - 112.0, view.y - 260.0), Vector2(224.0, 56.0))

func _load_striker_catalog() -> void:
	var file := FileAccess.open("res://data/striker_catalog.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		striker_catalog = parsed

func _selected_striker() -> Dictionary:
	if striker_catalog.is_empty():
		return {"name": "Classic", "force": 1.0, "aim": 1.0, "time": 20, "base": "#AAB6C4", "highlight": "#FFFFFF"}
	return striker_catalog[clampi(selected_striker_index, 0, striker_catalog.size() - 1)]

func _striker_is_unlocked(index: int) -> bool:
	if index < 0 or index >= striker_catalog.size():
		return false
	return practice_xp >= int(striker_catalog[index].get("unlock_xp", 0))

func _cycle_striker() -> void:
	if striker_catalog.is_empty():
		return
	for offset in range(1, striker_catalog.size() + 1):
		var next_index := (selected_striker_index + offset) % striker_catalog.size()
		if _striker_is_unlocked(next_index):
			selected_striker_index = next_index
			break
	_save_profile()
	turn_time_remaining = _turn_time_limit()
	status_text = "Striker: " + String(_selected_striker().get("name", "Classic"))
	queue_redraw()

func _turn_time_limit() -> float:
	return float(_selected_striker().get("time", 20))

func reset_match() -> void:
	pieces.clear()
	potted_this_shot.clear()
	scores = [0, 0]
	player_turn = WHITE
	aiming = false
	shot_active = false
	stop_timer = 0.0
	bot_delay = -1.0
	fouled_this_shot = false
	own_piece_potted_this_shot = false
	queen_potted_this_shot = false
	queen_captured = false
	game_over = false
	var center := board_rect.get_center()
	if match_mode == MODE_CLASSIC:
		# Compact two-ring rack: nine discs per side and one queen.
		for i in range(6):
			var inner_angle := TAU * float(i) / 6.0
			var inner_owner := WHITE if i % 2 == 0 else BLACK
			var inner_pos := center + Vector2(cos(inner_angle), sin(inner_angle)) * piece_radius * 2.12
			_add_disc(inner_owner, inner_pos)
		for i in range(12):
			var outer_angle := TAU * (float(i) + 0.5) / 12.0
			var outer_owner := WHITE if i % 2 == 0 else BLACK
			var outer_pos := center + Vector2(cos(outer_angle), sin(outer_angle)) * piece_radius * 4.28
			_add_disc(outer_owner, outer_pos)
		pieces.append({
			"owner": QUEEN,
			"position": center,
			"velocity": Vector2.ZERO,
			"radius": piece_radius * 1.04,
			"kind": "queen"
		})
	else:
		# Disc Pool: twelve discs, six per side, and no queen.
		for i in range(6):
			var angle_a := TAU * float(i) / 6.0
			var angle_b := angle_a + PI / 6.0
			_add_disc(WHITE, center + Vector2(cos(angle_a), sin(angle_a)) * piece_radius * 2.2)
			_add_disc(BLACK, center + Vector2(cos(angle_b), sin(angle_b)) * piece_radius * 4.4)
	striker = {
		"position": striker_spawn,
		"velocity": Vector2.ZERO,
		"radius": striker_radius,
		"kind": "striker"
	}
	striker["position"] = _turn_spawn(WHITE)
	turn_time_remaining = _turn_time_limit()
	status_text = "Your turn. Place the striker, pull back and release."
	queue_redraw()

func _add_disc(owner: int, position: Vector2) -> void:
	pieces.append({
		"owner": owner,
		"position": position,
		"velocity": Vector2.ZERO,
		"radius": piece_radius,
		"kind": "disc"
	})

func _load_profile() -> void:
	if not FileAccess.file_exists("user://player_profile.json"):
		return
	var file := FileAccess.open("user://player_profile.json", FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	board_index = clampi(int(parsed.get("board_index", 0)), 0, 49)
	matches_played = maxi(0, int(parsed.get("matches_played", 0)))
	matches_won = maxi(0, int(parsed.get("matches_won", 0)))
	practice_xp = maxi(0, int(parsed.get("practice_xp", 0)))
	selected_striker_index = clampi(int(parsed.get("selected_striker_index", 0)), 0, maxi(0, striker_catalog.size() - 1))
	match_mode = clampi(int(parsed.get("match_mode", MODE_CLASSIC)), MODE_CLASSIC, MODE_DISC_POOL)
	local_two_player = bool(parsed.get("local_two_player", false))

func _save_profile() -> void:
	var profile := {
		"board_index": board_index,
		"matches_played": matches_played,
		"matches_won": matches_won,
		"practice_xp": practice_xp,
		"selected_striker_index": selected_striker_index,
		"match_mode": match_mode,
		"local_two_player": local_two_player
	}
	var file := FileAccess.open("user://player_profile.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(profile))

func _record_match_result(winner: int) -> void:
	matches_played += 1
	if winner == WHITE:
		matches_won += 1
	practice_xp += 20 + scores[WHITE] * 2
	_save_profile()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_press(event.position)
		else:
			_handle_release(event.position)
	elif event is InputEventScreenDrag:
		if aiming:
			aim_current = event.position
			queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_handle_press(event.position)
		else:
			_handle_release(event.position)
	elif event is InputEventMouseMotion and aiming:
		aim_current = event.position
		queue_redraw()

func _handle_press(point: Vector2) -> void:
	if game_mode_button_rect.has_point(point):
		match_mode = MODE_DISC_POOL if match_mode == MODE_CLASSIC else MODE_CLASSIC
		reset_match()
		status_text = "Disc Pool selected." if match_mode == MODE_DISC_POOL else "Classic Carrom selected."
		_save_profile()
		queue_redraw()
		return
	if striker_button_rect.has_point(point):
		_cycle_striker()
		return
	if mode_button_rect.has_point(point):
		local_two_player = not local_two_player
		bot_delay = -1.0
		status_text = "Local pass-and-play selected." if local_two_player else "Offline AI opponent selected."
		_save_profile()
		queue_redraw()
		return
	if reset_rect.has_point(point):
		reset_match()
		return
	if board_button_rect.has_point(point):
		if board_catalog.size() > 0:
			board_index = (board_index + 1) % board_catalog.size()
		_save_profile()
		queue_redraw()
		return
	if game_over or shot_active or (not local_two_player and player_turn != WHITE):
		return
	var active_spawn := _turn_spawn(player_turn)
	var baseline_y := active_spawn.y
	if absf(point.y - baseline_y) <= striker_radius * 2.2 and point.x >= board_rect.position.x + board_size * 0.22 and point.x <= board_rect.end.x - board_size * 0.22 and point.distance_to(striker["position"]) > striker_radius * 1.15:
		if local_two_player or player_turn == WHITE:
			striker["position"] = Vector2(clampf(point.x, board_rect.position.x + board_size * 0.22, board_rect.end.x - board_size * 0.22), baseline_y)
			queue_redraw()
			return
	if point.distance_to(striker["position"]) <= striker_radius * 3.2:
		aiming = true
		aim_start = striker["position"]
		aim_current = point
		queue_redraw()

func _handle_release(point: Vector2) -> void:
	if not aiming:
		return
	aiming = false
	aim_current = point
	var pull := aim_start - aim_current
	if pull.length() < 12.0:
		status_text = "Pull farther back to take a shot."
		queue_redraw()
		return
	var force_multiplier := float(_selected_striker().get("force", 1.0))
	var power := clampf(pull.length() * 5.4 * force_multiplier, 240.0, 1120.0 * force_multiplier)
	striker["velocity"] = pull.normalized() * power
	_begin_shot()
	queue_redraw()

func _begin_shot() -> void:
	shot_active = true
	stop_timer = 0.0
	fouled_this_shot = false
	own_piece_potted_this_shot = false
	queen_potted_this_shot = false
	potted_this_shot.clear()
	status_text = "Shot in motion..."
	bot_delay = -1.0

func _physics_process(delta: float) -> void:
	if not shot_active:
		if not game_over and not (player_turn == BLACK and not local_two_player):
			turn_time_remaining -= delta
			if turn_time_remaining <= 0.0:
				player_turn = BLACK if player_turn == WHITE else WHITE
				striker["position"] = _turn_spawn(player_turn)
				turn_time_remaining = _turn_time_limit()
				status_text = "Time expired. Turn passed."
				if player_turn == BLACK and not local_two_player:
					bot_delay = 0.85
				queue_redraw()
		elif player_turn == BLACK and not game_over and not local_two_player:
			if bot_delay < 0.0:
				bot_delay = 0.85
			else:
				bot_delay -= delta
				if bot_delay <= 0.0:
					_bot_take_shot()
		return

	_step_pieces(delta)
	_resolve_all_collisions()
	if _all_stopped():
		stop_timer += delta
		if stop_timer >= 0.28:
			_complete_turn()
	else:
		stop_timer = 0.0
	queue_redraw()

func _step_pieces(delta: float) -> void:
	var left := board_rect.position.x + board_size * 0.075
	var right := board_rect.end.x - board_size * 0.075
	var top := board_rect.position.y + board_size * 0.075
	var bottom := board_rect.end.y - board_size * 0.075
	var retained: Array[Dictionary] = []

	for piece in pieces:
		var pos: Vector2 = piece["position"]
		var vel: Vector2 = piece["velocity"]
		var radius: float = piece["radius"]
		pos += vel * delta
		vel *= exp(-FRICTION * delta)
		if vel.length() < STOP_SPEED:
			vel = Vector2.ZERO

		if _is_in_pocket(pos):
			var owner: int = piece["owner"]
			if owner == QUEEN:
				queen_potted_this_shot = true
			else:
				potted_this_shot.append({"owner": owner, "kind": "disc"})
				if owner == player_turn:
					own_piece_potted_this_shot = true
					scores[player_turn] += 1
				else:
					fouled_this_shot = true
			continue

		if pos.x < left + radius:
			pos.x = left + radius
			vel.x = absf(vel.x) * RESTITUTION
		elif pos.x > right - radius:
			pos.x = right - radius
			vel.x = -absf(vel.x) * RESTITUTION
		if pos.y < top + radius:
			pos.y = top + radius
			vel.y = absf(vel.y) * RESTITUTION
		elif pos.y > bottom - radius:
			pos.y = bottom - radius
			vel.y = -absf(vel.y) * RESTITUTION

		piece["position"] = pos
		piece["velocity"] = vel
		retained.append(piece)

	pieces = retained

	var striker_pos: Vector2 = striker["position"] + striker["velocity"] * delta
	var striker_vel: Vector2 = striker["velocity"] * exp(-FRICTION * delta)
	if striker_vel.length() < STOP_SPEED:
		striker_vel = Vector2.ZERO
	if _is_in_pocket(striker_pos):
		fouled_this_shot = true
		striker_pos = striker_spawn
		striker_vel = Vector2.ZERO
	var striker_left := left + striker_radius
	var striker_right := right - striker_radius
	var striker_top := top + striker_radius
	var striker_bottom := bottom - striker_radius
	if striker_pos.x < striker_left:
		striker_pos.x = striker_left
		striker_vel.x = absf(striker_vel.x) * RESTITUTION
	elif striker_pos.x > striker_right:
		striker_pos.x = striker_right
		striker_vel.x = -absf(striker_vel.x) * RESTITUTION
	if striker_pos.y < striker_top:
		striker_pos.y = striker_top
		striker_vel.y = absf(striker_vel.y) * RESTITUTION
	elif striker_pos.y > striker_bottom:
		striker_pos.y = striker_bottom
		striker_vel.y = -absf(striker_vel.y) * RESTITUTION
	striker["position"] = striker_pos
	striker["velocity"] = striker_vel

func _is_in_pocket(pos: Vector2) -> bool:
	for pocket in _pocket_positions():
		if pos.distance_to(pocket) <= pocket_radius:
			return true
	return false

func _pocket_positions() -> Array[Vector2]:
	var inset := board_size * 0.032
	return [
		board_rect.position + Vector2(inset, inset),
		Vector2(board_rect.end.x - inset, board_rect.position.y + inset),
		Vector2(board_rect.position.x + inset, board_rect.end.y - inset),
		board_rect.end - Vector2(inset, inset)
	]

func _resolve_all_collisions() -> void:
	for i in range(pieces.size()):
		for j in range(i + 1, pieces.size()):
			_resolve_pair(pieces[i], pieces[j])
	for piece in pieces:
		_resolve_pair(striker, piece)

func _resolve_pair(a: Dictionary, b: Dictionary) -> void:
	var pa: Vector2 = a["position"]
	var pb: Vector2 = b["position"]
	var delta := pb - pa
	var distance := delta.length()
	var min_distance: float = float(a["radius"]) + float(b["radius"])
	if distance <= 0.001 or distance >= min_distance:
		return
	var normal := delta / distance
	var overlap := min_distance - distance
	pa -= normal * overlap * 0.5
	pb += normal * overlap * 0.5
	var va: Vector2 = a["velocity"]
	var vb: Vector2 = b["velocity"]
	var closing_speed := (va - vb).dot(normal)
	if closing_speed > 0.0:
		var impulse_magnitude := (1.0 + RESTITUTION) * closing_speed * 0.5
		var impulse := normal * impulse_magnitude
		va -= impulse
		vb += impulse
	a["position"] = pa
	b["position"] = pb
	a["velocity"] = va
	b["velocity"] = vb

func _all_stopped() -> bool:
	var striker_velocity: Vector2 = striker["velocity"]
	if striker_velocity.length() >= STOP_SPEED:
		return false
	for piece in pieces:
		var piece_velocity: Vector2 = piece["velocity"]
		if piece_velocity.length() >= STOP_SPEED:
			return false
	return true

func _complete_turn() -> void:
	shot_active = false
	striker["velocity"] = Vector2.ZERO

	if queen_potted_this_shot:
		if not fouled_this_shot and own_piece_potted_this_shot:
			queen_captured = true
			scores[player_turn] += 3
			status_text = "Queen covered! +3 points."
		else:
			pieces.append({
				"owner": QUEEN,
				"position": board_rect.get_center(),
				"velocity": Vector2.ZERO,
				"radius": piece_radius * 1.04,
				"kind": "queen"
			})
			status_text = "The queen needs cover. It returned to centre."

	if fouled_this_shot:
		status_text = "Foul: striker or opponent disc pocketed. Turn passed."
		var own_potted_count := 0
		for record in potted_this_shot:
			if int(record["owner"]) == player_turn:
				own_potted_count += 1
		scores[player_turn] = maxi(0, scores[player_turn] - own_potted_count)
		for returned in potted_this_shot:
			_add_disc(int(returned["owner"]), _find_restore_position())
		# A striker/opponent-disc foul also costs one previously banked coin
		# when this shot did not already return one of the player's own coins.
		if own_potted_count == 0 and scores[player_turn] > 0:
			scores[player_turn] -= 1
			_add_disc(player_turn, _find_restore_position())
		striker["position"] = _turn_spawn(player_turn)
		player_turn = BLACK if player_turn == WHITE else WHITE
	elif not own_piece_potted_this_shot:
		player_turn = BLACK if player_turn == WHITE else WHITE
		if status_text == "Shot in motion...":
			status_text = "No own disc pocketed. Turn passed."

	striker["position"] = _turn_spawn(player_turn)
	var white_left := _count_owner(WHITE)
	var black_left := _count_owner(BLACK)
	var queen_left := _count_owner(QUEEN)
	var white_won := white_left == 0 and (match_mode == MODE_DISC_POOL or queen_captured or queen_left == 0)
	var black_won := black_left == 0 and (match_mode == MODE_DISC_POOL or queen_captured or queen_left == 0)
	if white_left == 0 and black_left == 0 and (match_mode == MODE_DISC_POOL or queen_captured or queen_left == 0):
		game_over = true
		status_text = "Draw! Tap New Match to play again."
		_record_match_result(-1)
		queue_redraw()
		return
	if white_won or black_won:
		game_over = true
		var winner := WHITE if white_won else BLACK
		status_text = "Player 1 wins!" if winner == WHITE else "Player 2 wins!"
		if not local_two_player and winner == BLACK:
			status_text = "AI wins!"
		status_text += " Tap New Match to play again."
		_record_match_result(winner)
		queue_redraw()
		return
	elif player_turn == WHITE:
		status_text += " Player 1 turn." if local_two_player else " Your turn."
	else:
		status_text += " Player 2 turn." if local_two_player else " Opponent turn."

	turn_time_remaining = _turn_time_limit()
	if player_turn == BLACK and not game_over and not local_two_player:
		bot_delay = 0.85
	queue_redraw()

func _find_restore_position() -> Vector2:
	var center := board_rect.get_center()
	var min_x := board_rect.position.x + board_size * 0.13
	var max_x := board_rect.end.x - board_size * 0.13
	var min_y := board_rect.position.y + board_size * 0.13
	var max_y := board_rect.end.y - board_size * 0.13
	for ring in range(12):
		var search_radius := minf(piece_radius * (2.55 + float(ring) * 1.1), board_size * 0.42)
		for step in range(32):
			var angle := TAU * float(step) / 32.0 + float(ring % 2) * PI / 32.0
			var candidate := center + Vector2(cos(angle), sin(angle)) * search_radius
			if candidate.x < min_x or candidate.x > max_x or candidate.y < min_y or candidate.y > max_y:
				continue
			var blocked := false
			for piece in pieces:
				var other_position: Vector2 = piece["position"]
				var required_gap := piece_radius + float(piece["radius"]) + board_size * 0.004
				if candidate.distance_to(other_position) < required_gap:
					blocked = true
					break
			if not blocked:
				return candidate
	return center + Vector2(board_size * 0.18, 0.0)

func _count_owner(owner: int) -> int:
	var count := 0
	for piece in pieces:
		if piece["owner"] == owner:
			count += 1
	return count

func _turn_spawn(owner: int) -> Vector2:
	var y := board_rect.position.y + board_size * 0.19 if owner == BLACK else board_rect.position.y + board_size * 0.81
	return Vector2(board_rect.get_center().x, y)

func _choose_bot_aim_point() -> Vector2:
	var start := _turn_spawn(BLACK)
	var best_point := start + Vector2.DOWN * board_size * 0.28
	var best_cost := INF
	for piece in pieces:
		if int(piece["owner"]) != BLACK:
			continue
		var target_position: Vector2 = piece["position"]
		for pocket in _pocket_positions():
			var pocket_vector: Vector2 = pocket - target_position
			if pocket_vector.length() < 1.0:
				continue
			var pocket_direction := pocket_vector.normalized()
			var impact_point := target_position - pocket_direction * (piece_radius + striker_radius * 0.9)
			var shot_vector := impact_point - start
			if shot_vector.length() < 1.0:
				continue
			var alignment := shot_vector.normalized().dot(pocket_direction)
			var angle_penalty := (1.0 - alignment) * board_size * 0.42
			var cost := shot_vector.length() + pocket_vector.length() * 0.22 + angle_penalty
			if cost < best_cost:
				best_cost = cost
				best_point = impact_point
	return best_point

func _bot_take_shot() -> void:
	bot_delay = -1.0
	if _count_owner(BLACK) == 0:
		return
	var start := _turn_spawn(BLACK)
	var aim_point := _choose_bot_aim_point()
	var direction := aim_point - start
	if direction.length() < 1.0:
		direction = Vector2.DOWN
	striker["position"] = start
	striker["velocity"] = direction.normalized() * 780.0
	_begin_shot()

func _draw() -> void:
	var view := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view), Color("#091724"), true)
	draw_circle(Vector2(view.x * 0.5, view.y * 0.12), view.x * 0.42, Color("#102435"))
	_draw_hud(view)
	_draw_board()
	_draw_pieces()
	_draw_controls(view)
	if aiming:
		_draw_aim_guide()

func _draw_hud(view: Vector2) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 75), "BOARD MASTERS", HORIZONTAL_ALIGNMENT_CENTER, view.x, 34, Color("#F5E7C8"))
	draw_string(font, Vector2(0, 112), "CARROM ARENA", HORIZONTAL_ALIGNMENT_CENTER, view.x, 17, Color("#9EB8C8"))
	var turn_label := "YOUR TURN" if player_turn == WHITE else "AI OPPONENT"
	if local_two_player:
		turn_label = "PLAYER 1 TURN" if player_turn == WHITE else "PLAYER 2 TURN"
	if game_over:
		turn_label = "MATCH COMPLETE"
	draw_string(font, Vector2(30, 190), turn_label, HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0, 22, Color("#F1C978"))
	var first_label := "PLAYER 1" if local_two_player else "YOU"
	var second_label := "PLAYER 2" if local_two_player else "OPPONENT"
	draw_string(font, Vector2(30, 230), first_label + "  %d" % scores[WHITE], HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0, 26, Color("#F5F2E9"))
	draw_string(font, Vector2(30, 265), second_label + "  %d" % scores[BLACK], HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0, 20, Color("#B7C6D0"))
	draw_string(font, Vector2(30, 305), "MATCHES  %d    WINS  %d    XP  %d" % [matches_played, matches_won, practice_xp], HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0, 16, Color("#7FA8B9"))
	var timer_label := "TIME  %.0f" % maxf(0.0, turn_time_remaining)
	var striker_data := _selected_striker()
	draw_string(font, Vector2(30, 337), "%s  F%.2f  A%.2f  T%.0f" % [String(striker_data.get("name", "Classic")), float(striker_data.get("force", 1.0)), float(striker_data.get("aim", 1.0)), float(striker_data.get("time", 20))], HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0, 15, Color("#D4B9A0"))
	draw_string(font, Vector2(view.x - 140.0, 190), timer_label, HORIZONTAL_ALIGNMENT_RIGHT, 110.0, 18, Color("#F1C978"))

func _draw_board() -> void:
	var felt := _theme_color("felt", "#197A63")
	var frame := _theme_color("frame", "#50311E")
	var accent := _theme_color("accent", "#E9C888")
	draw_rect(Rect2(board_rect.position + Vector2(0, 12), board_rect.size), Color("#03080D"), true)
	draw_rect(board_rect, frame, true)
	draw_rect(board_rect.grow(-board_size * 0.035), accent, true)
	draw_rect(board_rect.grow(-board_size * 0.055), felt, true)
	var inner := board_rect.grow(-board_size * 0.115)
	draw_rect(inner, Color(0.02, 0.05, 0.04, 0.13), false, 3.0)
	var center := board_rect.get_center()
	draw_circle(center, board_size * 0.115, Color(0.02, 0.04, 0.04, 0.10))
	draw_arc(center, board_size * 0.115, 0.0, TAU, 96, accent, 3.0, true)
	var line_left := board_rect.position.x + board_size * 0.18
	var line_right := board_rect.end.x - board_size * 0.18
	var bottom_y := board_rect.position.y + board_size * 0.81
	var top_y := board_rect.position.y + board_size * 0.19
	for y in [bottom_y, top_y]:
		draw_line(Vector2(line_left, y - board_size * 0.035), Vector2(line_right, y - board_size * 0.035), accent, 3.0, true)
		draw_line(Vector2(line_left, y + board_size * 0.035), Vector2(line_right, y + board_size * 0.035), accent, 3.0, true)
		draw_arc(Vector2(center.x, y), board_size * 0.07, 0.0, TAU, 64, accent, 2.0, true)
	for pocket in _pocket_positions():
		draw_circle(pocket, pocket_radius * 1.20, Color("#D4B57A"))
		draw_circle(pocket, pocket_radius, Color("#081016"))
		draw_circle(pocket, pocket_radius * 0.66, Color("#020609"))
	draw_string(ThemeDB.fallback_font, Vector2(board_rect.position.x, board_rect.end.y + 35.0), "DRAG BACK TO AIM  •  RELEASE TO SHOOT", HORIZONTAL_ALIGNMENT_CENTER, board_size, 16, Color("#BBD1D9"))

func _draw_pieces() -> void:
	for piece in pieces:
		var owner: int = piece["owner"]
		var pos: Vector2 = piece["position"]
		var radius: float = piece["radius"]
		if owner == QUEEN:
			_draw_token(pos, radius, Color("#E84D54"), Color("#FFE0B2"))
		elif owner == WHITE:
			_draw_token(pos, radius, Color("#F5E9CB"), Color("#FFFFFF"))
		else:
			_draw_token(pos, radius, Color("#263442"), Color("#8195A5"))
	_draw_striker()

func _draw_token(pos: Vector2, radius: float, base: Color, shine: Color) -> void:
	# Layered rim, inset face and a soft specular highlight give each coin depth.
	draw_circle(pos + Vector2(2.0, 4.0), radius * 1.08, Color(0.01, 0.02, 0.03, 0.48))
	draw_circle(pos, radius * 1.04, Color("#0B1219"))
	draw_circle(pos, radius * 0.96, Color("#C7A66A"))
	draw_circle(pos, radius * 0.88, Color("#161E24"))
	draw_circle(pos, radius * 0.80, base)
	draw_arc(pos, radius * 0.69, 0.0, TAU, 56, shine, maxf(1.5, radius * 0.09), true)
	draw_arc(pos, PI * 1.08, PI * 1.56, 28, 0, Color(1, 1, 1, 0.32), maxf(1.0, radius * 0.07), true)
	draw_circle(pos - Vector2(radius * 0.25, radius * 0.28), radius * 0.18, Color(1, 1, 1, 0.68))
	draw_circle(pos - Vector2(radius * 0.17, radius * 0.19), radius * 0.07, Color(1, 1, 1, 0.32))

func _draw_striker() -> void:
	var pos: Vector2 = striker["position"]
	draw_circle(pos + Vector2(2.0, 5.0), striker_radius * 1.12, Color(0, 0, 0, 0.5))
	var striker_data := _selected_striker()
	var base_color := Color.from_string(String(striker_data.get("base", "#AAB6C4")), Color("#AAB6C4"))
	var highlight_color := Color.from_string(String(striker_data.get("highlight", "#FFFFFF")), Color.WHITE)
	draw_circle(pos, striker_radius * 1.12, highlight_color)
	draw_circle(pos, striker_radius * 0.91, Color("#263A4A"))
	draw_circle(pos, striker_radius * 0.63, base_color)
	draw_circle(pos - Vector2(striker_radius * 0.19, striker_radius * 0.22), striker_radius * 0.18, Color(1.0, 1.0, 1.0, 0.75))

func _draw_aim_guide() -> void:
	var pull := aim_start - aim_current
	if pull.length() < 4.0:
		return
	var direction := pull.normalized()
	var start: Vector2 = striker["position"]
	var aim_multiplier := float(_selected_striker().get("aim", 1.0))
	var end := start + direction * minf(board_size * 0.34 * aim_multiplier, pull.length() * 2.2 * aim_multiplier)
	draw_line(start, end, Color("#FFF0BD"), 3.0, true)
	for i in range(1, 8):
		var dot := start + direction * (end - start).length() * float(i) / 8.0
		draw_circle(dot, 3.2, Color("#FFF0BD"))

func _draw_controls(view: Vector2) -> void:
	draw_rect(game_mode_button_rect, Color("#6A3E64"), true)
	draw_rect(game_mode_button_rect, Color("#DAB6D4"), false, 2.0)
	var game_mode_label := "DISC POOL" if match_mode == MODE_DISC_POOL else "CLASSIC CARROM"
	draw_string(ThemeDB.fallback_font, Vector2(game_mode_button_rect.position.x, game_mode_button_rect.position.y + 36.0), game_mode_label, HORIZONTAL_ALIGNMENT_CENTER, game_mode_button_rect.size.x, 16, Color("#F7E8F1"))

	draw_rect(mode_button_rect, Color("#2C5360"), true)
	draw_rect(mode_button_rect, Color("#A8D1D7"), false, 2.0)
	var mode_label := "LOCAL 2 PLAYERS" if local_two_player else "VS OFFLINE AI"
	draw_string(ThemeDB.fallback_font, Vector2(mode_button_rect.position.x, mode_button_rect.position.y + 36.0), mode_label, HORIZONTAL_ALIGNMENT_CENTER, mode_button_rect.size.x, 16, Color("#F4E8CD"))

	draw_rect(board_button_rect, Color("#24485A"), true)
	draw_rect(board_button_rect, Color("#8FB9C7"), false, 2.0)
	var board_name := "CLASSIC BOARD"
	if board_catalog.size() > 0:
		board_name = String(board_catalog[board_index].get("name", board_name)).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(board_button_rect.position.x, board_button_rect.position.y + 35.0), "BOARD " + board_name, HORIZONTAL_ALIGNMENT_CENTER, board_button_rect.size.x, 14, Color("#F4E8CD"))

	draw_rect(striker_button_rect, Color("#6A4A30"), true)
	draw_rect(striker_button_rect, Color("#E7C18B"), false, 2.0)
	var striker_name := String(_selected_striker().get("name", "Classic")).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(striker_button_rect.position.x, striker_button_rect.position.y + 35.0), "STRIKER " + striker_name, HORIZONTAL_ALIGNMENT_CENTER, striker_button_rect.size.x, 14, Color("#FFF0D8"))

	draw_rect(reset_rect, Color("#C18A3D"), true)
	draw_rect(reset_rect, Color("#F3D89A"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(reset_rect.position.x, reset_rect.position.y + 38.0), "NEW MATCH", HORIZONTAL_ALIGNMENT_CENTER, reset_rect.size.x, 19, Color("#101C26"))
	draw_string(ThemeDB.fallback_font, Vector2(20, 375.0), status_text, HORIZONTAL_ALIGNMENT_CENTER, view.x - 40.0, 15, Color("#DCE7E8"))
	draw_string(ThemeDB.fallback_font, Vector2(20, 403.0), "MOVE STRIKER ON BASELINE  •  DRAG BACK TO SHOOT", HORIZONTAL_ALIGNMENT_CENTER, view.x - 40.0, 13, Color("#8CAEBB"))

func _theme_color(key: String, fallback: String) -> Color:
	if board_catalog.is_empty():
		return Color.from_string(fallback, Color.WHITE)
	var theme: Dictionary = board_catalog[board_index]
	return Color.from_string(String(theme.get(key, fallback)), Color.from_string(fallback, Color.WHITE))
