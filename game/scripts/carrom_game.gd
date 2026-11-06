extends Node2D
class_name CarromGame

const WHITE := 0
const BLACK := 1
const QUEEN := 2
const MODE_CLASSIC := 0
const MODE_DISC_POOL := 1
const MODE_CHALLENGE := 2
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
var visual_effects: Array[Dictionary] = []
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
var is_paused := false
var pause_panel_rect := Rect2()
var resume_button_rect := Rect2()
var pause_new_match_button_rect := Rect2()

func _ready() -> void:
	_load_board_catalog()
	_load_striker_catalog()
	_load_profile()
	_refresh_geometry()
	get_viewport().size_changed.connect(_on_viewport_resized)
	reset_match()

func _process(delta: float) -> void:
	if is_paused or visual_effects.is_empty():
		return
	for i in range(visual_effects.size() - 1, -1, -1):
		var effect: Dictionary = visual_effects[i]
		effect["age"] = float(effect.get("age", 0.0)) + delta
		if String(effect.get("kind", "")) == "spark":
			var position: Vector2 = effect["position"]
			var velocity: Vector2 = effect["velocity"]
			position += velocity * delta
			velocity *= exp(-5.5 * delta)
			effect["position"] = position
			effect["velocity"] = velocity
		if float(effect["age"]) >= float(effect["duration"]):
			visual_effects.remove_at(i)
		else:
			visual_effects[i] = effect
	queue_redraw()

func _spawn_pocket_effect(position: Vector2, tint: Color) -> void:
	visual_effects.append({
		"kind": "ring",
		"position": position,
		"age": 0.0,
		"duration": 0.42,
		"color": tint
	})

func _spawn_impact_effect(position: Vector2, strength: float) -> void:
	var safe_strength := clampf(strength, 0.2, 1.35)
	for i in range(6):
		var angle := randf_range(0.0, TAU)
		var speed := randf_range(65.0, 155.0) * safe_strength
		visual_effects.append({
			"kind": "spark",
			"position": position,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"age": 0.0,
			"duration": randf_range(0.20, 0.34),
			"radius": randf_range(1.6, 3.2) * safe_strength,
			"color": Color("#F5D08A")
		})

func _draw_visual_effects() -> void:
	for effect in visual_effects:
		var age := float(effect.get("age", 0.0))
		var duration := maxf(0.001, float(effect.get("duration", 0.3)))
		var progress := clampf(age / duration, 0.0, 1.0)
		var fade := 1.0 - progress
		var position: Vector2 = effect["position"]
		var tint: Color = effect["color"]
		tint.a = fade
		if String(effect.get("kind", "")) == "ring":
			var ring_radius := pocket_radius * (0.58 + progress * 1.25)
			draw_arc(position, ring_radius, 0.0, TAU, 36, tint, maxf(1.5, piece_radius * 0.11), true)
		else:
			var velocity: Vector2 = effect["velocity"]
			var tail := position - velocity.normalized() * minf(13.0, velocity.length() * 0.035)
			draw_line(tail, position, tint, maxf(1.0, float(effect.get("radius", 2.0)) * fade), true)
			draw_circle(position, maxf(0.5, float(effect.get("radius", 2.0)) * fade), tint)

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

func _ui_scale(view: Vector2) -> float:
	return clampf(minf(view.x / 900.0, view.y / 1600.0), 0.5, 1.35)

func _refresh_geometry() -> void:
	var view := get_viewport_rect().size
	var ui_scale := _ui_scale(view)
	board_size = maxf(240.0, minf(view.x * 0.86, view.y * 0.49))
	var origin := Vector2((view.x - board_size) * 0.5, (view.y - board_size) * 0.52)
	board_rect = Rect2(origin, Vector2(board_size, board_size))
	pocket_radius = board_size * 0.064
	piece_radius = board_size * 0.018
	striker_radius = board_size * 0.028
	striker_spawn = Vector2(board_rect.get_center().x, board_rect.position.y + board_size * 0.81)

	# Anchor the controls to the board instead of using fixed screen offsets.
	var button_size := Vector2(minf(224.0 * ui_scale, view.x * 0.46), 56.0 * ui_scale)
	var first_row_y := board_rect.end.y + board_size * 0.18
	var second_row_y := board_rect.end.y + board_size * 0.28
	var left_x := view.x * 0.25 - button_size.x * 0.5
	var right_x := view.x * 0.75 - button_size.x * 0.5
	mode_button_rect = Rect2(Vector2(left_x, first_row_y), button_size)
	game_mode_button_rect = Rect2(Vector2(right_x, first_row_y), button_size)
	board_button_rect = Rect2(Vector2(left_x, second_row_y), button_size)
	striker_button_rect = Rect2(Vector2(right_x, second_row_y), button_size)
	var reset_size := Vector2(minf(250.0 * ui_scale, view.x * 0.62), 58.0 * ui_scale)
	reset_rect = Rect2(Vector2(view.x * 0.5 - reset_size.x * 0.5, board_rect.end.y + board_size * 0.38), reset_size)
	var panel_size := Vector2(minf(view.x * 0.88, 500.0 * ui_scale + 90.0), minf(view.y * 0.52, 300.0 * ui_scale + 24.0))
	pause_panel_rect = Rect2(view * 0.5 - panel_size * 0.5, panel_size)
	var action_size := Vector2(panel_size.x * 0.78, maxf(42.0, 48.0 * ui_scale))
	var resume_y := pause_panel_rect.position.y + panel_size.y * 0.43
	resume_button_rect = Rect2(Vector2(view.x * 0.5 - action_size.x * 0.5, resume_y), action_size)
	pause_new_match_button_rect = Rect2(Vector2(view.x * 0.5 - action_size.x * 0.5, resume_y + action_size.y + maxf(8.0, 14.0 * ui_scale)), action_size)

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
	is_paused = false
	pieces.clear()
	visual_effects.clear()
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
	elif match_mode == MODE_DISC_POOL:
		# Disc Pool: twelve discs, six per side, and no queen.
		for i in range(6):
			var angle_a := TAU * float(i) / 6.0
			var angle_b := angle_a + PI / 6.0
			_add_disc(WHITE, center + Vector2(cos(angle_a), sin(angle_a)) * piece_radius * 2.2)
			_add_disc(BLACK, center + Vector2(cos(angle_b), sin(angle_b)) * piece_radius * 4.4)
	else:
		# Precision Challenge: twelve gold targets, cleared by one player.
		for i in range(12):
			var angle := TAU * float(i) / 12.0
			var ring_radius := piece_radius * (2.7 if i % 2 == 0 else 4.5)
			pieces.append({
				"owner": WHITE,
				"position": center + Vector2(cos(angle), sin(angle)) * ring_radius,
				"velocity": Vector2.ZERO,
				"radius": piece_radius * 1.08,
				"kind": "target"
			})
	striker = {
		"position": striker_spawn,
		"velocity": Vector2.ZERO,
		"radius": striker_radius,
		"kind": "striker"
	}
	striker["position"] = _turn_spawn(WHITE)
	turn_time_remaining = _turn_time_limit()
	status_text = "Clear all 12 gold targets." if match_mode == MODE_CHALLENGE else "Your turn. Place the striker, pull back and release."
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
	match_mode = clampi(int(parsed.get("match_mode", MODE_CLASSIC)), MODE_CLASSIC, MODE_CHALLENGE)
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
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACK:
			is_paused = not is_paused
			status_text = "Match paused." if is_paused else "Match resumed."
			queue_redraw()

func _handle_press(point: Vector2) -> void:
	if is_paused:
		if resume_button_rect.has_point(point):
			is_paused = false
			status_text = "Match resumed."
			queue_redraw()
		elif pause_new_match_button_rect.has_point(point):
			reset_match()
		return
	if reset_rect.has_point(point):
		is_paused = true
		status_text = "Match paused."
		queue_redraw()
		return
	if game_mode_button_rect.has_point(point):
		match_mode = (match_mode + 1) % 3
		if match_mode == MODE_CHALLENGE:
			local_two_player = false
		reset_match()
		status_text = _game_mode_name() + " selected."
		_save_profile()
		queue_redraw()
		return
	if striker_button_rect.has_point(point):
		_cycle_striker()
		return
	if mode_button_rect.has_point(point):
		if match_mode == MODE_CHALLENGE:
			status_text = "Precision Challenge is a solo mode."
			queue_redraw()
			return
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
	if is_paused:
		return
	if not shot_active:
		if not game_over and not (player_turn == BLACK and not local_two_player):
			turn_time_remaining -= delta
			if turn_time_remaining <= 0.0:
				if match_mode == MODE_CHALLENGE:
					turn_time_remaining = _turn_time_limit()
					status_text = "Clock reset. Keep practicing."
					queue_redraw()
					return
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
			var pocket_tint := Color("#E84D54") if owner == QUEEN else (Color("#F5E9CB") if owner == WHITE else Color("#8195A5"))
			_spawn_pocket_effect(pos, pocket_tint)
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
		_spawn_pocket_effect(striker_pos, Color("#F1C978"))
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
		if closing_speed > 150.0:
			_spawn_impact_effect((pa + pb) * 0.5, closing_speed / 900.0)
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

	if match_mode == MODE_CHALLENGE:
		player_turn = WHITE
		striker["position"] = _turn_spawn(WHITE)
		var targets_left := _count_owner(WHITE)
		if targets_left == 0:
			game_over = true
			status_text = "Precision Challenge cleared! All targets pocketed."
			_record_match_result(WHITE)
		else:
			turn_time_remaining = _turn_time_limit()
			status_text = "Targets left: %d. Take another shot." % targets_left
		queue_redraw()
		return

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
	_draw_visual_effects()
	_draw_controls(view)
	if is_paused:
		_draw_pause_menu(view)
	if aiming:
		_draw_aim_guide()

func _draw_hud(view: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var scale := _ui_scale(view)
	draw_string(font, Vector2(0, 75.0 * scale), "BOARD MASTERS", HORIZONTAL_ALIGNMENT_CENTER, view.x, maxi(16, roundi(34.0 * scale)), Color("#F5E7C8"))
	draw_string(font, Vector2(0, 112.0 * scale), "CARROM ARENA", HORIZONTAL_ALIGNMENT_CENTER, view.x, maxi(11, roundi(17.0 * scale)), Color("#9EB8C8"))
	var turn_label := "YOUR TURN" if player_turn == WHITE else "AI OPPONENT"
	if match_mode == MODE_CHALLENGE:
		turn_label = "PRECISION CHALLENGE"
	elif local_two_player:
		turn_label = "PLAYER 1 TURN" if player_turn == WHITE else "PLAYER 2 TURN"
	if game_over:
		turn_label = "CHALLENGE COMPLETE" if match_mode == MODE_CHALLENGE else "MATCH COMPLETE"
	draw_string(font, Vector2(30.0 * scale, 190.0 * scale), turn_label, HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0 * scale, maxi(12, roundi(22.0 * scale)), Color("#F1C978"))
	var first_label := "PLAYER 1" if local_two_player else "YOU"
	var second_label := "PLAYER 2" if local_two_player else "OPPONENT"
	var first_value: int = scores[WHITE]
	var second_value: int = scores[BLACK]
	if match_mode == MODE_CHALLENGE:
		first_label = "TARGETS LEFT"
		second_label = "POCKETED"
		first_value = _count_owner(WHITE)
		second_value = scores[WHITE]
	draw_string(font, Vector2(30.0 * scale, 230.0 * scale), first_label + "  %d" % first_value, HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0 * scale, maxi(13, roundi(26.0 * scale)), Color("#F5F2E9"))
	draw_string(font, Vector2(30.0 * scale, 265.0 * scale), second_label + "  %d" % second_value, HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0 * scale, maxi(11, roundi(20.0 * scale)), Color("#B7C6D0"))
	draw_string(font, Vector2(30.0 * scale, 305.0 * scale), "MATCHES  %d    WINS  %d    XP  %d" % [matches_played, matches_won, practice_xp], HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0 * scale, maxi(10, roundi(16.0 * scale)), Color("#7FA8B9"))
	var timer_label := "TIME  %.0f" % maxf(0.0, turn_time_remaining)
	var striker_data := _selected_striker()
	draw_string(font, Vector2(30.0 * scale, 352.0 * scale), "%s  F%.2f  A%.2f  T%.0f" % [String(striker_data.get("name", "Classic")), float(striker_data.get("force", 1.0)), float(striker_data.get("aim", 1.0)), float(striker_data.get("time", 20))], HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0 * scale, maxi(9, roundi(15.0 * scale)), Color("#D4B9A0"))
	draw_string(font, Vector2(view.x - 140.0 * scale, 190.0 * scale), timer_label, HORIZONTAL_ALIGNMENT_RIGHT, 110.0 * scale, maxi(10, roundi(18.0 * scale)), Color("#F1C978"))

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
	draw_string(ThemeDB.fallback_font, Vector2(board_rect.position.x, board_rect.end.y + board_size * 0.045), "DRAG BACK TO AIM  •  RELEASE TO SHOOT", HORIZONTAL_ALIGNMENT_CENTER, board_size, maxi(10, roundi(board_size * 0.021)), Color("#BBD1D9"))

func _draw_pieces() -> void:
	for piece in pieces:
		var owner: int = piece["owner"]
		var pos: Vector2 = piece["position"]
		var radius: float = piece["radius"]
		if String(piece.get("kind", "")) == "target":
			_draw_token(pos, radius, Color("#C99534"), Color("#FFE6A0"))
		elif owner == QUEEN:
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
	draw_arc(pos, radius * 0.58, PI * 1.05, PI * 1.55, 28, Color(1, 1, 1, 0.32), maxf(1.0, radius * 0.07), true)
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
	var scale := _ui_scale(view)
	var outline := maxf(1.0, 2.0 * scale)
	var mode_font := maxi(10, roundi(16.0 * scale))
	var detail_font := maxi(9, roundi(14.0 * scale))

	draw_rect(game_mode_button_rect, Color("#6A3E64"), true)
	draw_rect(game_mode_button_rect, Color("#DAB6D4"), false, outline)
	var game_mode_label := "TARGET RUN" if match_mode == MODE_CHALLENGE else _game_mode_name().to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(game_mode_button_rect.position.x, game_mode_button_rect.position.y + game_mode_button_rect.size.y * 0.66), game_mode_label, HORIZONTAL_ALIGNMENT_CENTER, game_mode_button_rect.size.x, mode_font, Color("#F7E8F1"))

	draw_rect(mode_button_rect, Color("#2C5360"), true)
	draw_rect(mode_button_rect, Color("#A8D1D7"), false, outline)
	var mode_label := "SOLO CHALLENGE" if match_mode == MODE_CHALLENGE else ("LOCAL 2 PLAYERS" if local_two_player else "VS OFFLINE AI")
	draw_string(ThemeDB.fallback_font, Vector2(mode_button_rect.position.x, mode_button_rect.position.y + mode_button_rect.size.y * 0.66), mode_label, HORIZONTAL_ALIGNMENT_CENTER, mode_button_rect.size.x, mode_font, Color("#F4E8CD"))

	draw_rect(board_button_rect, Color("#24485A"), true)
	draw_rect(board_button_rect, Color("#8FB9C7"), false, outline)
	var board_name := "CLASSIC BOARD"
	if board_catalog.size() > 0:
		board_name = String(board_catalog[board_index].get("name", board_name)).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(board_button_rect.position.x, board_button_rect.position.y + board_button_rect.size.y * 0.66), "BOARD " + board_name, HORIZONTAL_ALIGNMENT_CENTER, board_button_rect.size.x, detail_font, Color("#F4E8CD"))

	draw_rect(striker_button_rect, Color("#6A4A30"), true)
	draw_rect(striker_button_rect, Color("#E7C18B"), false, outline)
	var striker_name := String(_selected_striker().get("name", "Classic")).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(striker_button_rect.position.x, striker_button_rect.position.y + striker_button_rect.size.y * 0.66), "STRIKER " + striker_name, HORIZONTAL_ALIGNMENT_CENTER, striker_button_rect.size.x, detail_font, Color("#FFF0D8"))

	draw_rect(reset_rect, Color("#C18A3D"), true)
	draw_rect(reset_rect, Color("#F3D89A"), false, outline)
	draw_string(ThemeDB.fallback_font, Vector2(reset_rect.position.x, reset_rect.position.y + reset_rect.size.y * 0.66), "PAUSE / MENU", HORIZONTAL_ALIGNMENT_CENTER, reset_rect.size.x, maxi(12, roundi(19.0 * scale)), Color("#101C26"))

	var status_y := board_rect.position.y - 52.0 * scale
	var hint_y := board_rect.position.y - 24.0 * scale
	draw_string(ThemeDB.fallback_font, Vector2(20.0 * scale, status_y), status_text, HORIZONTAL_ALIGNMENT_CENTER, view.x - 40.0 * scale, maxi(10, roundi(15.0 * scale)), Color("#DCE7E8"))
	draw_string(ThemeDB.fallback_font, Vector2(20.0 * scale, hint_y), "MOVE STRIKER ON BASELINE  •  DRAG BACK TO SHOOT", HORIZONTAL_ALIGNMENT_CENTER, view.x - 40.0 * scale, maxi(9, roundi(13.0 * scale)), Color("#8CAEBB"))

func _game_mode_name() -> String:
	match match_mode:
		MODE_DISC_POOL:
			return "Disc Pool"
		MODE_CHALLENGE:
			return "Precision Challenge"
		_:
			return "Classic Carrom"

func _draw_pause_menu(view: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.01, 0.02, 0.035, 0.76), true)
	draw_rect(pause_panel_rect, Color("#132638"), true)
	draw_rect(pause_panel_rect, Color("#D9B878"), false, 2.5)
	var font := ThemeDB.fallback_font
	var title_y := pause_panel_rect.position.y + pause_panel_rect.size.y * 0.29
	draw_string(font, Vector2(0.0, title_y), "MATCH PAUSED", HORIZONTAL_ALIGNMENT_CENTER, view.x, maxi(18, roundi(30.0 * _ui_scale(view))), Color("#F7E8C8"))
	draw_rect(resume_button_rect, Color("#2D806B"), true)
	draw_rect(resume_button_rect, Color("#A6E0C5"), false, 2.0)
	draw_string(font, Vector2(resume_button_rect.position.x, resume_button_rect.position.y + resume_button_rect.size.y * 0.68), "RESUME MATCH", HORIZONTAL_ALIGNMENT_CENTER, resume_button_rect.size.x, maxi(13, roundi(18.0 * _ui_scale(view))), Color.WHITE)
	draw_rect(pause_new_match_button_rect, Color("#8A5937"), true)
	draw_rect(pause_new_match_button_rect, Color("#E9C58E"), false, 2.0)
	draw_string(font, Vector2(pause_new_match_button_rect.position.x, pause_new_match_button_rect.position.y + pause_new_match_button_rect.size.y * 0.68), "NEW MATCH", HORIZONTAL_ALIGNMENT_CENTER, pause_new_match_button_rect.size.x, maxi(13, roundi(18.0 * _ui_scale(view))), Color("#FFF2D7"))

func _theme_color(key: String, fallback: String) -> Color:
	if board_catalog.is_empty():
		return Color.from_string(fallback, Color.WHITE)
	var theme: Dictionary = board_catalog[board_index]
	return Color.from_string(String(theme.get(key, fallback)), Color.from_string(fallback, Color.WHITE))
