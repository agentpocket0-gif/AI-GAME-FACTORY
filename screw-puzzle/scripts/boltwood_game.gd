extends Node2D

enum Screen { HOME, LEVELS, PLAY, SETTINGS, HELP }

const DESIGN_W := 900.0
const DESIGN_H := 1600.0
const LEVEL_COUNT := 30
const BASE_TRAY_CAPACITY := 5
const SAVE_PATH := "user://boltwood_profile.cfg"

const WOOD_PALETTES := [
	Color("#b8753f"), Color("#c58a4d"), Color("#a96537"),
	Color("#d09a58"), Color("#98603a"), Color("#bd8148")
]
const METAL := Color("#b9c7c9")
const GOLD := Color("#efbd68")
const INK := Color("#102b32")
const MUTED := Color("#9db4b5")

var current_screen: int = Screen.HOME
var overlay: String = ""
var level_index: int = 1
var highest_level: int = 1
var coins: int = 0
var free_hints: int = 3
var haptics_enabled: bool = true

var pieces: Array = []
var bolts: Array = []
var tray: Array = []
var undo_history: Array = []
var tray_capacity: int = BASE_TRAY_CAPACITY
var move_count: int = 0
var hint_bolt_id: int = -1
var hint_timer: float = 0.0
var status_message: String = ""
var status_timer: float = 0.0
var anim_time: float = 0.0
var level_rewarded: bool = false

func _ready() -> void:
	_load_profile()
	_start_level(highest_level, false)
	current_screen = Screen.HOME
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	anim_time += delta
	if status_timer > 0.0:
		status_timer = maxf(0.0, status_timer - delta)
	if hint_timer > 0.0:
		hint_timer = maxf(0.0, hint_timer - delta)
		if hint_timer == 0.0:
			hint_bolt_id = -1
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(_to_design_space(event.position))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(_to_design_space(event.position))
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if current_screen == Screen.PLAY:
			if overlay == "pause":
				overlay = ""
			elif overlay == "":
				overlay = "pause"
			queue_redraw()
		elif current_screen != Screen.HOME:
			current_screen = Screen.HOME
			overlay = ""
			queue_redraw()

func _to_design_space(point: Vector2) -> Vector2:
	var view_size := get_viewport_rect().size
	if view_size.x <= 0.0 or view_size.y <= 0.0:
		return point
	return Vector2(point.x * DESIGN_W / view_size.x, point.y * DESIGN_H / view_size.y)

func _draw() -> void:
	_draw_background()
	match current_screen:
		Screen.HOME:
			_draw_home()
		Screen.LEVELS:
			_draw_levels()
		Screen.PLAY:
			_draw_play()
		Screen.SETTINGS:
			_draw_settings()
		Screen.HELP:
			_draw_help()

func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(DESIGN_W, DESIGN_H)), Color("#09242d"))
	for i in range(68):
		var x := float(32 + (i * 137) % 836)
		var y := float(35 + (i * 263) % 1525)
		var radius := 1.5 + float(i % 3) * 0.7
		draw_circle(Vector2(x, y), radius, Color(0.56, 0.73, 0.72, 0.10))
	_draw_round_rect(Rect2(24, 24, 852, 1552), Color("#0d3038"), 42, Color("#234b50"), 3.0)

func _draw_home() -> void:
	_draw_round_rect(Rect2(74, 112, 752, 330), Color("#123b43"), 40, Color("#47716c"), 3.0)
	_draw_logo(Vector2(450, 245), 1.0)
	_draw_text("BOLTWOOD", Vector2(450, 380), 76, GOLD)
	_draw_text("THE FASTENER WORKSHOP", Vector2(450, 430), 25, MUTED)

	_draw_round_rect(Rect2(90, 565, 720, 148), Color("#153e45"), 30, Color("#4b736f"), 2.0)
	_draw_text("YOUR WORKSHOP", Vector2(450, 608), 23, MUTED)
	_draw_text("LEVEL %02d" % highest_level, Vector2(300, 666), 38, Color("#fff0d2"))
	_draw_text("%d COINS" % coins, Vector2(650, 666), 32, GOLD)

	_draw_button(Rect2(112, 820, 676, 126), "PLAY WORKSHOP", true)
	_draw_button(Rect2(112, 982, 325, 110), "LEVEL MAP", false)
	_draw_button(Rect2(463, 982, 325, 110), "HOW TO PLAY", false)
	_draw_button(Rect2(112, 1124, 676, 94), "SETTINGS", false)
	_draw_text("30 ORIGINAL PUZZLE LEVELS", Vector2(450, 1320), 25, MUTED)
	_draw_text("BUILT FOR OFFLINE PLAY", Vector2(450, 1364), 21, Color("#6f9695"))

func _draw_logo(center: Vector2, scale_value: float) -> void:
	var size := 174.0 * scale_value
	_draw_round_rect(Rect2(center.x - size * 0.5, center.y - size * 0.5, size, size), Color("#d69b53"), 38.0 * scale_value, Color("#f8d18b"), 5.0 * scale_value)
	draw_circle(center, 54.0 * scale_value, Color("#647f82"))
	draw_circle(center, 40.0 * scale_value, Color("#bdcacc"))
	draw_arc(center, 40.0 * scale_value, 0.0, TAU, 48, Color("#f4f2dd"), 5.0 * scale_value, true)
	draw_line(center + Vector2(-19, 0) * scale_value, center + Vector2(19, 0) * scale_value, Color("#344e53"), 9.0 * scale_value, true)
	draw_line(center + Vector2(0, -19) * scale_value, center + Vector2(0, 19) * scale_value, Color("#344e53"), 9.0 * scale_value, true)

func _draw_levels() -> void:
	_draw_header("LEVEL MAP", "UNLOCKED: %02d / %02d" % [highest_level, LEVEL_COUNT])
	_draw_button(Rect2(68, 1430, 764, 94), "BACK TO WORKSHOP", false)
	for level in range(1, LEVEL_COUNT + 1):
		var column := (level - 1) % 5
		var row := int((level - 1) / 5)
		var rect := Rect2(72 + column * 152, 390 + row * 164, 132, 132)
		var unlocked := level <= highest_level
		var fill := Color("#24534f") if unlocked else Color("#18363b")
		var edge := GOLD if level == highest_level else Color("#4b7770")
		_draw_round_rect(rect, fill, 22, edge, 3.0)
		if unlocked:
			_draw_text("%02d" % level, rect.get_center() + Vector2(0, -4), 42, Color("#fff0d2"))
			_draw_text("PLAY" if level == highest_level else "OPEN", rect.get_center() + Vector2(0, 40), 16, MUTED)
		else:
			_draw_text("LOCKED", rect.get_center() + Vector2(0, 8), 18, Color("#728c8d"))

func _draw_settings() -> void:
	_draw_header("SETTINGS", "LOCAL PLAYER OPTIONS")
	_draw_round_rect(Rect2(80, 420, 740, 500), Color("#143b42"), 32, Color("#47716c"), 3.0)
	_draw_text("HAPTIC FEEDBACK", Vector2(450, 540), 30, Color("#fff0d2"))
	_draw_button(Rect2(160, 600, 580, 100), "ON" if haptics_enabled else "OFF", true)
	_draw_text("Your progress is saved on this device.", Vector2(450, 790), 22, MUTED)
	_draw_text("No account or internet connection is needed.", Vector2(450, 835), 20, MUTED)
	_draw_button(Rect2(100, 1430, 700, 94), "BACK", false)

func _draw_help() -> void:
	_draw_header("HOW TO PLAY", "CLEAR THE WOOD. KEEP THE TRAY UNDER CONTROL.")
	_draw_round_rect(Rect2(76, 390, 748, 760), Color("#143b42"), 30, Color("#47716c"), 3.0)
	var lines := [
		"1. Tap a visible metal bolt to remove it.",
		"2. A plank falls away after all its bolts are out.",
		"3. Bolts from a cleared plank leave the tray.",
		"4. The tray has five spaces by default.",
		"5. Clear one plank before filling the tray.",
		"6. Some bolts are hidden under upper planks.",
		"7. Use HINT to find an exposed bolt.",
		"8. UNDO takes back your last move.",
		"9. EXTRA SLOT adds one space for this level.",
		"10. Finish all planks to unlock the next level."
	]
	for i in range(lines.size()):
		_draw_text(lines[i], Vector2(450, 470 + i * 62), 22, Color("#e8e7d3"))
	_draw_text("Tip: Look at the top layer first.", Vector2(450, 1100), 22, GOLD)
	_draw_button(Rect2(100, 1430, 700, 94), "BACK", false)

func _draw_play() -> void:
	_draw_header("LEVEL %02d" % level_index, "MOVE %02d     COINS %d" % [move_count, coins])
	_draw_button(Rect2(54, 76, 132, 82), "BACK", false)
	_draw_button(Rect2(714, 76, 132, 82), "PAUSE", false)

	var cleared := pieces.size() - _active_piece_count()
	var total := maxi(1, pieces.size())
	_draw_round_rect(Rect2(100, 196, 700, 18), Color("#21484b"), 9, Color("#21484b"), 1.0)
	_draw_round_rect(Rect2(100, 196, 700.0 * float(cleared) / float(total), 18), GOLD, 9, GOLD, 1.0)

	_draw_round_rect(Rect2(62, 280, 776, 792), Color("#714a31"), 36, Color("#d5a369"), 5.0)
	_draw_round_rect(Rect2(82, 300, 736, 752), Color("#bd8750"), 28, Color("#e4b779"), 3.0)
	for i in range(12):
		var y := 330.0 + float(i) * 59.0
		draw_line(Vector2(108, y), Vector2(792, y), Color(0.42, 0.24, 0.13, 0.10), 2.0, true)
	draw_circle(Vector2(450, 675), 175, Color(0.91, 0.72, 0.43, 0.07))
	draw_circle(Vector2(450, 675), 128, Color(0.91, 0.72, 0.43, 0.05))

	for piece in pieces:
		if bool(piece["active"]):
			_draw_piece(piece)

	for bolt in bolts:
		if _bolt_visible(bolt):
			if bool(bolt["removed"]):
				_draw_hole(bolt["position"])
			else:
				var highlighted := int(bolt["id"]) == hint_bolt_id and hint_timer > 0.0
				_draw_bolt(bolt["position"], 1.0, highlighted)

	_draw_round_rect(Rect2(78, 1110, 744, 172), Color("#123b42"), 28, Color("#527971"), 3.0)
	_draw_text("FASTENER TRAY   %d / %d" % [tray.size(), tray_capacity], Vector2(450, 1148), 22, MUTED)
	for slot in range(tray_capacity):
		var center := Vector2(170 + slot * 140, 1210)
		draw_circle(center + Vector2(0, 5), 43, Color(0, 0, 0, 0.22))
		draw_circle(center, 39, Color("#0b252c"))
		draw_arc(center, 39, 0.0, TAU, 48, Color("#537477"), 4.0, true)
		if slot < tray.size():
			_draw_bolt(center, 0.72, false)

	_draw_button(Rect2(68, 1330, 238, 112), "HINT", false)
	_draw_button(Rect2(331, 1330, 238, 112), "UNDO", false)
	_draw_button(Rect2(594, 1330, 238, 112), "EXTRA SLOT", true)
	if status_timer > 0.0 and status_message != "":
		_draw_text(status_message, Vector2(450, 1490), 21, GOLD)
	else:
		_draw_text("REMOVE A PLANK'S BOLTS TO CLEAR IT", Vector2(450, 1490), 19, MUTED)

	if overlay != "":
		_draw_overlay()

func _draw_overlay() -> void:
	draw_rect(Rect2(0, 0, DESIGN_W, DESIGN_H), Color(0.01, 0.025, 0.03, 0.72), true)
	var title := "PAUSED"
	var subtitle := "Take a moment. Your level is safe."
	if overlay == "won":
		title = "LEVEL CLEARED!"
		subtitle = "A clean board. Nice work."
	elif overlay == "failed":
		title = "TRAY FULL"
		subtitle = "Try clearing one plank at a time."
	_draw_round_rect(Rect2(74, 580, 752, 470), Color("#153e45"), 36, Color("#d8a35e"), 4.0)
	_draw_text(title, Vector2(450, 690), 54, GOLD)
	_draw_text(subtitle, Vector2(450, 760), 21, MUTED)
	if overlay == "pause":
		_draw_button(Rect2(150, 825, 600, 90), "RESUME", true)
		_draw_button(Rect2(150, 930, 288, 82), "RESTART", false)
		_draw_button(Rect2(462, 930, 288, 82), "LEVEL MAP", false)
	elif overlay == "won":
		var label := "NEXT LEVEL" if level_index < LEVEL_COUNT else "LEVEL MAP"
		_draw_button(Rect2(150, 830, 600, 96), label, true)
		_draw_button(Rect2(150, 945, 600, 78), "REPLAY LEVEL", false)
	elif overlay == "failed":
		_draw_button(Rect2(150, 830, 600, 96), "TRY AGAIN", true)
		_draw_button(Rect2(150, 945, 600, 78), "LEVEL MAP", false)

func _draw_header(title: String, subtitle: String) -> void:
	_draw_round_rect(Rect2(42, 56, 816, 178), Color("#123940"), 30, Color("#416c68"), 2.0)
	_draw_text(title, Vector2(450, 128), 42, GOLD)
	_draw_text(subtitle, Vector2(450, 190), 19, MUTED)

func _draw_piece(piece: Dictionary) -> void:
	var center: Vector2 = piece["center"]
	var size: Vector2 = piece["size"]
	var angle: float = piece["angle"]
	var points := _plank_points(center + Vector2(0, 12), size, angle)
	draw_colored_polygon(points, Color(0, 0, 0, 0.25))
	var face := WOOD_PALETTES[int(piece["palette"]) % WOOD_PALETTES.size()]
	draw_colored_polygon(_plank_points(center, size, angle), face)
	var outline := _plank_points(center, size, angle)
	outline.append(outline[0])
	draw_polyline(outline, Color("#71472b"), 7.0, true)

	var direction := Vector2.RIGHT.rotated(angle)
	var normal := Vector2(-direction.y, direction.x)
	for grain in range(-2, 3):
		var offset := normal * float(grain) * size.y * 0.19
		var start := center - direction * size.x * 0.40 + offset
		var finish := center + direction * size.x * 0.40 + offset
		draw_line(start, finish, Color(0.37, 0.19, 0.09, 0.20), 2.0, true)
	draw_line(center - direction * size.x * 0.41 - normal * size.y * 0.30, center + direction * size.x * 0.41 - normal * size.y * 0.30, face.lightened(0.27), 3.0, true)
	draw_circle(center + direction * size.x * 0.18, 5.5, Color(0.42, 0.22, 0.11, 0.25))
	draw_circle(center - direction * size.x * 0.14, 4.0, Color(0.42, 0.22, 0.11, 0.20))

func _draw_bolt(center: Vector2, scale_value: float = 1.0, highlighted: bool = false) -> void:
	var radius := 25.0 * scale_value
	draw_circle(center + Vector2(0, 5) * scale_value, radius + 2.0, Color(0, 0, 0, 0.30))
	draw_circle(center, radius + 4.0, Color("#536c6e"))
	draw_circle(center, radius, METAL.lightened(0.10))
	draw_circle(center + Vector2(-5, -7) * scale_value, radius * 0.55, Color("#e2e9e6"))
	draw_arc(center, radius, 0.0, TAU, 48, Color("#425b60"), 3.0 * scale_value, true)
	draw_line(center + Vector2(-10, 0) * scale_value, center + Vector2(10, 0) * scale_value, Color("#52666a"), 4.0 * scale_value, true)
	draw_line(center + Vector2(0, -10) * scale_value, center + Vector2(0, 10) * scale_value, Color("#52666a"), 4.0 * scale_value, true)
	if highlighted:
		var pulse := 37.0 + sin(anim_time * 8.0) * 4.0
		draw_arc(center, pulse, 0.0, TAU, 48, GOLD, 5.0, true)

func _draw_hole(center: Vector2) -> void:
	draw_circle(center, 27, Color("#4a2d20"))
	draw_circle(center, 20, Color("#211c19"))
	draw_arc(center, 27, 0.0, TAU, 40, Color("#dfb173"), 4.0, true)
	draw_circle(center - Vector2(4, 4), 6, Color(0.75, 0.52, 0.30, 0.22))

func _draw_button(rect: Rect2, label: String, accent: bool) -> void:
	var fill := Color("#bd7b3d") if accent else Color("#1d4b50")
	var edge := Color("#f2cd8d") if accent else Color("#648783")
	_draw_round_rect(rect, fill, 24, edge, 3.0)
	_draw_round_rect(Rect2(rect.position + Vector2(8, 8), rect.size - Vector2(16, 16)), Color(1, 1, 1, 0.045), 18, Color(1, 1, 1, 0.03), 1.0)
	_draw_text(label, rect.get_center() + Vector2(0, 2), 26, Color("#fff2d7"))

func _draw_round_rect(rect: Rect2, fill: Color, radius: float, outline: Color = Color(0, 0, 0, 0), outline_width: float = 0.0) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var centers := [
		rect.position + Vector2(r, r),
		rect.position + Vector2(rect.size.x - r, r),
		rect.position + rect.size - Vector2(r, r),
		rect.position + Vector2(r, rect.size.y - r)
	]
	var points := PackedVector2Array()
	for corner in range(4):
		var start := -PI + float(corner) * PI * 0.5
		for step in range(7):
			var angle := start + PI * 0.5 * float(step) / 6.0
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, fill)
	if outline_width > 0.0:
		var closed := points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, outline, outline_width, true)

func _draw_text(label: String, center: Vector2, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	var width := maxf(180.0, float(label.length()) * float(font_size) * 0.78)
	var baseline := Vector2(center.x - width * 0.5, center.y + float(font_size) * 0.36)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)

func _plank_points(center: Vector2, size: Vector2, angle: float) -> PackedVector2Array:
	var direction := Vector2.RIGHT.rotated(angle)
	var normal := Vector2(-direction.y, direction.x)
	var along := direction * size.x * 0.5
	var across := normal * size.y * 0.5
	return PackedVector2Array([
		center - along - across,
		center + along - across,
		center + along + across,
		center - along + across
	])

func _handle_tap(point: Vector2) -> void:
	if overlay != "":
		_handle_overlay_tap(point)
		return

	match current_screen:
		Screen.HOME:
			if Rect2(112, 820, 676, 126).has_point(point):
				_start_level(highest_level)
			elif Rect2(112, 982, 325, 110).has_point(point):
				current_screen = Screen.LEVELS
			elif Rect2(463, 982, 325, 110).has_point(point):
				current_screen = Screen.HELP
			elif Rect2(112, 1124, 676, 94).has_point(point):
				current_screen = Screen.SETTINGS
		Screen.LEVELS:
			if Rect2(68, 1430, 764, 94).has_point(point):
				current_screen = Screen.HOME
			else:
				for level in range(1, LEVEL_COUNT + 1):
					var column := (level - 1) % 5
					var row := int((level - 1) / 5)
					var rect := Rect2(72 + column * 152, 390 + row * 164, 132, 132)
					if rect.has_point(point) and level <= highest_level:
						_start_level(level)
						break
		Screen.SETTINGS:
			if Rect2(100, 1430, 700, 94).has_point(point):
				current_screen = Screen.HOME
			elif Rect2(160, 600, 580, 100).has_point(point):
				haptics_enabled = not haptics_enabled
				_save_profile()
		Screen.HELP:
			if Rect2(100, 1430, 700, 94).has_point(point):
				current_screen = Screen.HOME
		Screen.PLAY:
			_handle_play_tap(point)
	queue_redraw()

func _handle_play_tap(point: Vector2) -> void:
	if Rect2(54, 76, 132, 82).has_point(point):
		current_screen = Screen.LEVELS
		return
	if Rect2(714, 76, 132, 82).has_point(point):
		overlay = "pause"
		return
	if Rect2(68, 1330, 238, 112).has_point(point):
		_use_hint()
		return
	if Rect2(331, 1330, 238, 112).has_point(point):
		_undo_move()
		return
	if Rect2(594, 1330, 238, 112).has_point(point):
		_buy_extra_slot()
		return

	for i in range(bolts.size() - 1, -1, -1):
		var bolt: Dictionary = bolts[i]
		if not bool(bolt["removed"]) and _bolt_visible(bolt) and point.distance_to(bolt["position"]) <= 45.0:
			_remove_bolt(i)
			return

func _handle_overlay_tap(point: Vector2) -> void:
	if overlay == "pause":
		if Rect2(150, 825, 600, 90).has_point(point):
			overlay = ""
		elif Rect2(150, 930, 288, 82).has_point(point):
			_start_level(level_index)
		elif Rect2(462, 930, 288, 82).has_point(point):
			overlay = ""
			current_screen = Screen.LEVELS
	elif overlay == "won":
		if Rect2(150, 830, 600, 96).has_point(point):
			overlay = ""
			if level_index < LEVEL_COUNT:
				_start_level(level_index + 1)
			else:
				current_screen = Screen.LEVELS
		elif Rect2(150, 945, 600, 78).has_point(point):
			_start_level(level_index)
	elif overlay == "failed":
		if Rect2(150, 830, 600, 96).has_point(point):
			_start_level(level_index)
		elif Rect2(150, 945, 600, 78).has_point(point):
			overlay = ""
			current_screen = Screen.LEVELS
	queue_redraw()

func _start_level(value: int, change_screen: bool = true) -> void:
	level_index = clampi(value, 1, LEVEL_COUNT)
	pieces.clear()
	bolts.clear()
	tray.clear()
	undo_history.clear()
	move_count = 0
	tray_capacity = BASE_TRAY_CAPACITY
	hint_bolt_id = -1
	hint_timer = 0.0
	overlay = ""
	status_message = ""
	status_timer = 0.0
	level_rewarded = false

	var specs := _layout_for_level(level_index)
	for piece_index in range(specs.size()):
		var spec: Dictionary = specs[piece_index]
		var bolt_ids: Array = []
		var bolt_count := 2
		if level_index >= 3 and (piece_index + level_index) % 3 == 0:
			bolt_count = 3
		for bolt_index in range(bolt_count):
			var along := -0.30 if bolt_index == 0 else 0.30
			if bolt_count == 3:
				along = [-0.31, 0.0, 0.31][bolt_index]
			var direction: Vector2 = Vector2.RIGHT.rotated(float(spec["angle"]))
			var bolt_position: Vector2 = spec["center"] + direction * float(spec["size"].x) * along
			var bolt_id := bolts.size()
			bolts.append({
				"id": bolt_id,
				"owner": piece_index,
				"position": bolt_position,
				"removed": false
			})
			bolt_ids.append(bolt_id)
		pieces.append({
			"id": piece_index,
			"center": spec["center"],
			"size": spec["size"],
			"angle": spec["angle"],
			"bolt_ids": bolt_ids,
			"active": true,
			"palette": (level_index + piece_index) % WOOD_PALETTES.size()
		})

	if change_screen:
		current_screen = Screen.PLAY
	queue_redraw()

func _layout_for_level(value: int) -> Array:
	var variant := (value - 1) % 6
	var left_x := 330.0 if variant % 2 == 0 else 315.0
	var right_x := 570.0 if variant % 2 == 0 else 585.0
	var top_y := 555.0 if variant < 3 else 535.0
	var bottom_y := 855.0 if variant < 3 else 875.0
	var specs: Array = [
		{"center": Vector2(left_x, 705), "size": Vector2(500, 94), "angle": PI * 0.5},
		{"center": Vector2(right_x, 705), "size": Vector2(500, 94), "angle": PI * 0.5},
		{"center": Vector2(450, top_y), "size": Vector2(540, 94), "angle": 0.0},
		{"center": Vector2(450, bottom_y), "size": Vector2(540, 94), "angle": 0.0}
	]
	var stage := int((value - 1) / 5)
	if stage >= 1:
		var middle_angle := 0.0 if variant % 3 == 0 else (PI * 0.25 if variant % 3 == 1 else -PI * 0.25)
		specs.append({"center": Vector2(450, 705), "size": Vector2(430, 82), "angle": middle_angle})
	if stage >= 2:
		var diagonal := PI * 0.25 if variant % 2 == 0 else -PI * 0.25
		specs.append({"center": Vector2(450, 705), "size": Vector2(540, 76), "angle": diagonal})
	if stage >= 3:
		specs.append({"center": Vector2(450, 705), "size": Vector2(430, 76), "angle": -PI * 0.25 if variant % 2 == 0 else PI * 0.25})
	if stage >= 4:
		specs.append({"center": Vector2(450, 445), "size": Vector2(430, 76), "angle": 0.0})
	if stage >= 5:
		specs.append({"center": Vector2(450, 705), "size": Vector2(420, 72), "angle": PI * 0.5})
	return specs

func _bolt_visible(bolt: Dictionary) -> bool:
	var owner := int(bolt["owner"])
	if owner < 0 or owner >= pieces.size():
		return false
	if not bool(pieces[owner]["active"]):
		return false
	var position: Vector2 = bolt["position"]
	for index in range(owner + 1, pieces.size()):
		var blocker: Dictionary = pieces[index]
		if bool(blocker["active"]) and _point_inside_piece(position, blocker):
			return false
	return true

func _point_inside_piece(point: Vector2, piece: Dictionary) -> bool:
	var center: Vector2 = piece["center"]
	var local := (point - center).rotated(-float(piece["angle"]))
	var size: Vector2 = piece["size"]
	return absf(local.x) <= size.x * 0.5 and absf(local.y) <= size.y * 0.5

func _find_accessible_bolt() -> int:
	for index in range(bolts.size()):
		var bolt: Dictionary = bolts[index]
		if not bool(bolt["removed"]) and _bolt_visible(bolt):
			return index
	return -1

func _remove_bolt(bolt_id: int) -> void:
	if bolt_id < 0 or bolt_id >= bolts.size() or overlay != "":
		return
	if tray.size() >= tray_capacity:
		overlay = "failed"
		return
	var bolt: Dictionary = bolts[bolt_id]
	if bool(bolt["removed"]) or not _bolt_visible(bolt):
		return

	_store_undo()
	bolt["removed"] = true
	bolts[bolt_id] = bolt
	tray.append(bolt_id)
	move_count += 1
	hint_bolt_id = -1
	hint_timer = 0.0
	_play_haptic(20)

	var owner := int(bolt["owner"])
	if _piece_bolts_complete(owner):
		pieces[owner]["active"] = false
		for piece_bolt_id in pieces[owner]["bolt_ids"]:
			tray.erase(piece_bolt_id)
		coins += 5
		status_message = "PLANK CLEARED  +5 COINS"
		status_timer = 1.5

	if tray.size() >= tray_capacity:
		overlay = "failed"
	elif _active_piece_count() == 0:
		overlay = "won"
		if not level_rewarded:
			coins += 20 + level_index * 2
			highest_level = maxi(highest_level, mini(LEVEL_COUNT, level_index + 1))
			level_rewarded = true
			status_message = "LEVEL COMPLETE"
			_save_profile()
	else:
		_save_profile()
	queue_redraw()

func _piece_bolts_complete(piece_id: int) -> bool:
	if piece_id < 0 or piece_id >= pieces.size():
		return false
	for bolt_id in pieces[piece_id]["bolt_ids"]:
		if not bool(bolts[int(bolt_id)]["removed"]):
			return false
	return true

func _active_piece_count() -> int:
	var count := 0
	for piece in pieces:
		if bool(piece["active"]):
			count += 1
	return count

func _store_undo() -> void:
	undo_history.append({
		"pieces": pieces.duplicate(true),
		"bolts": bolts.duplicate(true),
		"tray": tray.duplicate(),
		"move_count": move_count,
		"coins": coins,
		"tray_capacity": tray_capacity
	})
	if undo_history.size() > 30:
		undo_history.pop_front()

func _undo_move() -> void:
	if undo_history.is_empty():
		_show_status("NOTHING TO UNDO")
		return
	var snapshot: Dictionary = undo_history.pop_back()
	pieces = snapshot["pieces"]
	bolts = snapshot["bolts"]
	tray = snapshot["tray"]
	move_count = int(snapshot["move_count"])
	coins = int(snapshot["coins"])
	tray_capacity = int(snapshot["tray_capacity"])
	overlay = ""
	_save_profile()
	_show_status("LAST MOVE UNDONE")

func _use_hint() -> void:
	var bolt_id := _find_accessible_bolt()
	if bolt_id < 0:
		_show_status("NO OPEN BOLT FOUND")
		return
	if free_hints > 0:
		free_hints -= 1
	elif coins >= 25:
		coins -= 25
	else:
		_show_status("NEED 25 COINS FOR A HINT")
		return
	hint_bolt_id = bolt_id
	hint_timer = 4.0
	_show_status("TRY THE GLOWING BOLT")
	_save_profile()

func _buy_extra_slot() -> void:
	if tray_capacity > BASE_TRAY_CAPACITY:
		_show_status("EXTRA SLOT ALREADY ACTIVE")
		return
	if coins < 60:
		_show_status("EXTRA SLOT COSTS 60 COINS")
		return
	coins -= 60
	tray_capacity += 1
	_show_status("ONE EXTRA TRAY SPACE ADDED")
	_save_profile()

func _show_status(message: String) -> void:
	status_message = message
	status_timer = 2.0

func _play_haptic(milliseconds: int) -> void:
	if haptics_enabled and OS.has_feature("mobile"):
		Input.vibrate_handheld(milliseconds)

func _load_profile() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		highest_level = clampi(int(config.get_value("profile", "highest_level", 1)), 1, LEVEL_COUNT)
		coins = maxi(0, int(config.get_value("profile", "coins", 0)))
		free_hints = clampi(int(config.get_value("profile", "free_hints", 3)), 0, 99)
		haptics_enabled = bool(config.get_value("profile", "haptics_enabled", true))

func _save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "highest_level", highest_level)
	config.set_value("profile", "coins", coins)
	config.set_value("profile", "free_hints", free_hints)
	config.set_value("profile", "haptics_enabled", haptics_enabled)
	config.save(SAVE_PATH)
