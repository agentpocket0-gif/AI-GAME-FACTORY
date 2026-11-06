extends Node2D
class_name CarromGame

const WHITE := 0
const BLACK := 1
const QUEEN := 2
const FRICTION := 2.65
const RESTITUTION := 0.91
const STOP_SPEED := 7.0

var pieces: Array[Dictionary] = []
var striker: Dictionary = {}
var board_catalog: Array = []
var board_index := 0
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

func _ready() -> void:
	_load_board_catalog()
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
	reset_rect = Rect2(Vector2(view.x * 0.5 - 125.0, view.y - 125.0), Vector2(250.0, 64.0))
	board_button_rect = Rect2(Vector2(view.x * 0.5 - 125.0, view.y - 205.0), Vector2(250.0, 60.0))

func reset_match() -> void:
	pieces.clear()
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
	var ring_radius := board_size * 0.112
	for i in range(18):
		var angle := TAU * float(i) / 18.0
		var owner := WHITE if i % 2 == 0 else BLACK
		var pos := center + Vector2(cos(angle), sin(angle)) * ring_radius
		pieces.append({
			"owner": owner,
			"position": pos,
			"velocity": Vector2.ZERO,
			"radius": piece_radius,
			"kind": "disc"
		})
	pieces.append({
		"owner": QUEEN,
		"position": center,
		"velocity": Vector2.ZERO,
		"radius": piece_radius * 1.04,
		"kind": "queen"
	})
	striker = {
		"position": striker_spawn,
		"velocity": Vector2.ZERO,
		"radius": striker_radius,
		"kind": "striker"
	}
	status_text = "Your turn. Pull the striker backwards to aim."
	queue_redraw()

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
	if reset_rect.has_point(point):
		reset_match()
		return
	if board_button_rect.has_point(point):
		if board_catalog.size() > 0:
			board_index = (board_index + 1) % board_catalog.size()
		queue_redraw()
		return
	if game_over or shot_active or player_turn != WHITE:
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
	var power := clampf(pull.length() * 5.4, 240.0, 1120.0)
	striker["velocity"] = pull.normalized() * power
	_begin_shot()
	queue_redraw()

func _begin_shot() -> void:
	shot_active = true
	stop_timer = 0.0
	fouled_this_shot = false
	own_piece_potted_this_shot = false
	queen_potted_this_shot = false
	status_text = "Shot in motion..."
	bot_delay = -1.0

func _physics_process(delta: float) -> void:
	if not shot_active:
		if player_turn == BLACK and not game_over:
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
			elif owner == player_turn:
				own_piece_potted_this_shot = true
				scores[player_turn] += 1
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
		var impulse := normal * closing_speed * RESTITUTION
		va -= impulse
		vb += impulse
	a["position"] = pa
	b["position"] = pb
	a["velocity"] = va
	b["velocity"] = vb

func _all_stopped() -> bool:
	if (striker["velocity"] as Vector2).length() >= STOP_SPEED:
		return false
	for piece in pieces:
		if (piece["velocity"] as Vector2).length() >= STOP_SPEED:
			return false
	return true

func _complete_turn() -> void:
	shot_active = false
	striker["velocity"] = Vector2.ZERO

	if queen_potted_this_shot:
		if own_piece_potted_this_shot:
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
		status_text = "Foul: striker pocketed. Turn passed."
		striker["position"] = _turn_spawn(player_turn)
		player_turn = BLACK if player_turn == WHITE else WHITE
	elif not own_piece_potted_this_shot:
		player_turn = BLACK if player_turn == WHITE else WHITE
		if status_text == "Shot in motion...":
			status_text = "No own disc pocketed. Turn passed."

	striker["position"] = _turn_spawn(player_turn)
	if pieces.is_empty():
		game_over = true
		status_text = "Match complete. Tap New Match to play again."
	elif player_turn == WHITE:
		status_text += " Your turn."
	else:
		status_text += " Opponent turn."

	if player_turn == BLACK and not game_over:
		bot_delay = 0.85
	queue_redraw()

func _turn_spawn(owner: int) -> Vector2:
	var y := board_rect.position.y + board_size * 0.19 if owner == BLACK else board_rect.position.y + board_size * 0.81
	return Vector2(board_rect.get_center().x, y)

func _bot_take_shot() -> void:
	bot_delay = -1.0
	if pieces.is_empty():
		return
	var target: Dictionary = pieces[0]
	var best_distance := INF
	for piece in pieces:
		if piece["owner"] == BLACK:
			var distance: float = (piece["position"] as Vector2).distance_to(_turn_spawn(BLACK))
			if distance < best_distance:
				best_distance = distance
				target = piece
	var direction: Vector2 = (target["position"] as Vector2) - _turn_spawn(BLACK)
	if direction.length() < 1.0:
		direction = Vector2.DOWN
	striker["position"] = _turn_spawn(BLACK)
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
	if game_over:
		turn_label = "MATCH COMPLETE"
	draw_string(font, Vector2(30, 190), turn_label, HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0, 22, Color("#F1C978"))
	draw_string(font, Vector2(30, 230), "YOU  %d" % scores[WHITE], HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0, 26, Color("#F5F2E9"))
	draw_string(font, Vector2(30, 265), "OPPONENT  %d" % scores[BLACK], HORIZONTAL_ALIGNMENT_LEFT, view.x - 60.0, 20, Color("#B7C6D0"))

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
	draw_circle(pos + Vector2(2.0, 4.0), radius * 1.06, Color(0.01, 0.02, 0.03, 0.45))
	draw_circle(pos, radius, Color("#161E24"))
	draw_circle(pos, radius * 0.88, base)
	draw_arc(pos, radius * 0.68, 0.0, TAU, 48, shine, 2.0, true)
	draw_circle(pos - Vector2(radius * 0.25, radius * 0.27), radius * 0.19, Color(1, 1, 1, 0.55))

func _draw_striker() -> void:
	var pos: Vector2 = striker["position"]
	draw_circle(pos + Vector2(2.0, 5.0), striker_radius * 1.12, Color(0, 0, 0, 0.5))
	draw_circle(pos, striker_radius * 1.12, Color("#E5B85D"))
	draw_circle(pos, striker_radius * 0.91, Color("#263A4A"))
	draw_circle(pos, striker_radius * 0.63, Color("#E7E9E7"))
	draw_circle(pos - Vector2(striker_radius * 0.19, striker_radius * 0.22), striker_radius * 0.18, Color("#FFFFFF", 0.75))

func _draw_aim_guide() -> void:
	var pull := aim_start - aim_current
	if pull.length() < 4.0:
		return
	var direction := pull.normalized()
	var start: Vector2 = striker["position"]
	var end := start + direction * minf(board_size * 0.34, pull.length() * 2.2)
	draw_line(start, end, Color("#FFF0BD"), 3.0, true)
	for i in range(1, 8):
		var dot := start + direction * (end - start).length() * float(i) / 8.0
		draw_circle(dot, 3.2, Color("#FFF0BD"))

func _draw_controls(view: Vector2) -> void:
	draw_rect(board_button_rect, Color("#24485A"), true)
	draw_rect(board_button_rect, Color("#8FB9C7"), false, 2.0)
	var board_name := "CLASSIC BOARD"
	if board_catalog.size() > 0:
		board_name = String(board_catalog[board_index].get("name", board_name)).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(board_button_rect.position.x, board_button_rect.position.y + 38.0), "BOARD  •  " + board_name, HORIZONTAL_ALIGNMENT_CENTER, board_button_rect.size.x, 17, Color("#F4E8CD"))
	draw_rect(reset_rect, Color("#C18A3D"), true)
	draw_rect(reset_rect, Color("#F3D89A"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(reset_rect.position.x, reset_rect.position.y + 41.0), "NEW MATCH", HORIZONTAL_ALIGNMENT_CENTER, reset_rect.size.x, 21, Color("#101C26"))
	draw_string(ThemeDB.fallback_font, Vector2(20, view.y - 245.0), status_text, HORIZONTAL_ALIGNMENT_CENTER, view.x - 40.0, 16, Color("#DCE7E8"))

func _theme_color(key: String, fallback: String) -> Color:
	if board_catalog.is_empty():
		return Color.from_string(fallback, Color.WHITE)
	var theme: Dictionary = board_catalog[board_index]
	return Color.from_string(String(theme.get(key, fallback)), Color.from_string(fallback, Color.WHITE))
