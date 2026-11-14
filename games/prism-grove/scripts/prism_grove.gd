extends Node2D

# Prism Grove: original, offline-first 8x8 tile-placement puzzle.
enum Screen { HOME, PLAY, PAUSE, GAME_OVER, DAILY_COMPLETE, HELP }
const W := 900.0
const H := 1600.0
const N := 8
const CELL := 78.0
const GAP := 7.0
const STEP := CELL + GAP
const BOARD_X := 72.0
const BOARD_Y := 420.0
const DAILY_GOAL := 12
const SAVE_PATH := "user://prism_grove.cfg"
const SHAPES := [
    [Vector2i(0,0)],
    [Vector2i(0,0),Vector2i(1,0)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
    [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],
    [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],
    [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1)],
    [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
    [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,2)],
    [Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(0,2)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)],
    [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0)],
    [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(0,4)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1),Vector2i(1,2)],
    [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(1,2)]
]
const PALETTES := [
    {"name":"Moss & Mint","bg":"#0b252c","panel":"#153b40","edge":"#416d68","empty":"#193b40","tiles":["#8dd4b1","#b6dc8d","#e7c77e","#82b8d4","#c49bd7","#e69d91"]},
    {"name":"Dawn Citrus","bg":"#2a2632","panel":"#493b43","edge":"#8e7165","empty":"#59464b","tiles":["#f5c36e","#f19b70","#c7d77b","#84c9b9","#d79bc0","#f0dfb4"]},
    {"name":"Ocean Glass","bg":"#102638","panel":"#1a4055","edge":"#477b90","empty":"#21465a","tiles":["#75c8db","#78aee1","#9ed8bb","#c5d98c","#b8a8e7","#f0c78a"]},
    {"name":"Lavender Night","bg":"#211e35","panel":"#393450","edge":"#746d94","empty":"#45405c","tiles":["#a9a0ec","#d6a7e3","#f1b9c8","#a3d3d6","#c7df9d","#f1d08a"]}
]

var screen := Screen.HOME
var board: Array = []
var tray: Array = []
var score := 0
var best_score := 0
var total_lines := 0
var combo := 0
var daily_lines := 0
var daily_mode := false
var daily_seed := 0
var palette_index := 0
var selected_slot := -1
var undo_used := false
var undo_snapshot: Dictionary = {}
var message := ""
var message_time := 0.0
var rng := RandomNumberGenerator.new()
var sound_enabled := true
var pulse := 0.0
var sfx_player: AudioStreamPlayer

const BTN_CLASSIC := Rect2(112, 850, 676, 116)
const BTN_DAILY := Rect2(112, 990, 676, 116)
const BTN_HELP := Rect2(112, 1130, 676, 92)
const BTN_THEME := Rect2(64, 118, 300, 66)
const BTN_SOUND := Rect2(710, 118, 126, 66)
const BTN_PAUSE := Rect2(746, 318, 90, 66)
const BTN_UNDO := Rect2(64, 1455, 226, 80)
const BTN_RESTART := Rect2(337, 1455, 226, 80)
const BTN_HOME := Rect2(610, 1455, 226, 80)

func _ready() -> void:
    sfx_player = AudioStreamPlayer.new()
    add_child(sfx_player)
    _load_profile()
    _new_board()
    queue_redraw()

func _play_sfx(sound_name: String) -> void:
    if not sound_enabled:
        return
    var stream := load("res://assets/audio/%s.wav" % sound_name) as AudioStreamWAV
    if stream != null:
        sfx_player.stream = stream
        sfx_player.play()

func _process(delta: float) -> void:
    pulse += delta
    if message_time > 0.0:
        message_time = maxf(0.0, message_time - delta)
    queue_redraw()

func _draw() -> void:
    var p: Dictionary = PALETTES[palette_index]
    draw_rect(Rect2(0,0,W,H), Color(p.bg))
    _draw_motes()
    match screen:
        Screen.HOME: _draw_home(p)
        Screen.PLAY: _draw_game(p)
        Screen.PAUSE:
            _draw_game(p)
            _draw_overlay(p, "PAUSED", "Your garden is waiting.", ["RESUME", "RESTART", "HOME"])
        Screen.GAME_OVER: _draw_game_over(p)
        Screen.DAILY_COMPLETE:
            _draw_game(p)
            _draw_overlay(p, "DAILY BLOOM", "%d lines cleared. Well done!" % daily_lines, ["CLASSIC", "HOME"])
        Screen.HELP: _draw_help(p)

func _draw_motes() -> void:
    for i in range(42):
        var x := float(22 + (i * 157) % 856)
        var y := float(24 + (i * 271) % 1548)
        draw_circle(Vector2(x,y), 1.5 + float(i % 4) * 0.5, Color(0.75,0.91,0.81,0.10))

func _draw_home(p: Dictionary) -> void:
    _panel(Rect2(52,120,796,540),p)
    _flower_logo(Vector2(450,300))
    _text("PRISM GROVE",Vector2(450,470),68,Color("#f3e7c4"))
    _text("A LITTLE SPACE TO THINK",Vector2(450,520),24,Color("#a8c7b8"))
    _panel(Rect2(112,700,676,110),p)
    _text("BEST SCORE  %s" % _fmt(best_score),Vector2(450,768),30,Color("#e6d39b"))
    _button(BTN_CLASSIC,"PLAY CLASSIC",p,true)
    _button(BTN_DAILY,"DAILY BLOOM  •  12 LINES",p,false)
    _button(BTN_HELP,"HOW TO PLAY",p,false)
    _text("OFFLINE  •  NO TIMER  •  YOUR OWN PACE",Vector2(450,1330),20,Color("#9ab7ad"))
    _text("THEME: %s" % p.name,Vector2(450,1380),20,Color("#809f95"))

func _draw_game(p: Dictionary) -> void:
    _text("PRISM GROVE",Vector2(450,84),28,Color("#c5d9c3"))
    _button(BTN_THEME,"THEME  %d/4" % (palette_index+1),p,false)
    _button(BTN_SOUND,"SFX  %s" % ("ON" if sound_enabled else "OFF"),p,false)
    _text(_fmt(score),Vector2(450,260),78,Color("#f5e7bd"))
    _text("SCORE",Vector2(450,302),18,Color("#9fbaad"))
    _button(BTN_PAUSE,"Ⅱ",p,false)
    _text("BEST  %s" % _fmt(best_score),Vector2(450,365),22,Color("#a9c4b6"))
    _text(("DAILY BLOOM  %d / %d LINES" % [daily_lines,DAILY_GOAL]) if daily_mode else "CLEAR ROWS + COLUMNS  •  BUILD A STREAK",Vector2(450,398),18,Color("#8eafa4"))
    _panel(Rect2(72,410,756,756),p)
    for y in range(N):
        for x in range(N):
            var r := _cell_rect(x,y)
            var occupied := int(board[y][x]) >= 0
            _tile(r, _tile_color(int(board[y][x]),p) if occupied else Color(p.empty), occupied)
    _text("CHOOSE A SHAPE, THEN TAP THE BOARD",Vector2(450,1192),18,Color("#9fbaad"))
    for i in range(3):
        var r := _slot_rect(i)
        _panel(r,p)
        if tray[i] == null:
            _text("USED",r.get_center()+Vector2(0,8),17,Color("#78958b"))
        else:
            _draw_shape(tray[i],r.get_center(),18,p, i == selected_slot)
    _button(BTN_UNDO,"UNDO  %s" % ("USED" if undo_used or undo_snapshot.is_empty() else "1 LEFT"),p,false)
    _button(BTN_RESTART,"RESTART",p,false)
    _button(BTN_HOME,"HOME",p,false)
    if message_time > 0.0:
        _text(message,Vector2(450,1430),20,Color("#f1d89d"))

func _draw_game_over(p: Dictionary) -> void:
    _draw_game(p)
    _dim()
    _panel(Rect2(74,570,752,690),p)
    _text("THE GROVE NEEDS ROOM",Vector2(450,670),39,Color("#f3e7c4"))
    _text("No remaining shape fits on the board.",Vector2(450,725),22,Color("#a8c7b8"))
    _text("SCORE  %s" % _fmt(score),Vector2(450,810),34,Color("#e8d49b"))
    _text("LINES  %d" % total_lines,Vector2(450,865),22,Color("#a8c7b8"))
    _button(Rect2(112,960,676,88),"UNDO LAST MOVE" if not undo_used and not undo_snapshot.is_empty() else "UNDO UNAVAILABLE",p,false)
    _button(Rect2(112,1070,676,88),"TRY AGAIN",p,true)
    _button(Rect2(112,1180,676,78),"BACK TO GARDEN",p,false)

func _draw_overlay(p: Dictionary, heading: String, subtitle: String, labels: Array) -> void:
    _dim()
    _panel(Rect2(74,550,752,700),p)
    _text(heading,Vector2(450,700),46,Color("#f3e7c4"))
    _text(subtitle,Vector2(450,760),21,Color("#a8c7b8"))
    _button(Rect2(112,850,676,104),labels[0],p,true)
    if labels.size() > 1: _button(Rect2(112,990,676,100),labels[1],p,false)
    if labels.size() > 2: _button(Rect2(112,1120,676,92),labels[2],p,false)

func _draw_help(p: Dictionary) -> void:
    _panel(Rect2(60,220,780,1000),p)
    _text("HOW TO PLAY",Vector2(450,320),48,Color("#f3e7c4"))
    var lines := ["Choose one of the three shapes.","Tap an empty board cell to place it.","Fill a complete row or column to clear it.","Clear rows and columns together for bonus points.","Your three shapes refresh when all are used.","You get one Undo each round.","Daily Bloom: clear 12 lines.","No timer. No internet. Just think ahead."]
    for i in range(lines.size()): _text(lines[i],Vector2(450,430+i*74),23,Color("#c0d2c2"))
    _button(Rect2(112,1320,676,100),"BACK TO GARDEN",p,true)

func _panel(r: Rect2,p: Dictionary) -> void:
    draw_rect(r,Color(p.panel))
    draw_rect(r,Color(p.edge),false,3.0)

func _button(r: Rect2,label: String,p: Dictionary,primary: bool) -> void:
    var fill := Color(p.edge).lightened(0.16) if primary else Color(p.panel).lightened(0.10)
    draw_rect(r,fill)
    draw_rect(r,Color(p.edge).lightened(0.35),false,3.0)
    _text(label,r.get_center()+Vector2(0,9),26,Color("#f5eed9"))

func _text(value: String,at: Vector2,size: int,color: Color) -> void:
    var font: Font = ThemeDB.fallback_font
    draw_string(font,Vector2(0.0,at.y+float(size)*0.34),value,HORIZONTAL_ALIGNMENT_CENTER,W,size,color)

func _tile(r: Rect2,color: Color,raised: bool) -> void:
    draw_rect(r,color)
    if raised:
        draw_rect(Rect2(r.position+Vector2(5,5),Vector2(r.size.x-10,8)),Color(1,1,1,0.24))
        draw_rect(r,Color(0.06,0.12,0.13,0.40),false,2.0)
    else:
        draw_rect(r,Color(1,1,1,0.04),false,1.0)

func _draw_shape(shape: Array,center: Vector2,unit: float,p: Dictionary,selected: bool) -> void:
    var bounds := _shape_bounds(shape)
    var origin := center - Vector2(bounds.x,bounds.y)*unit*0.5
    var color := Color(p.tiles[mini(5,shape.size()%6)])
    for offset in shape:
        var r := Rect2(origin+Vector2(offset.x,offset.y)*unit+Vector2(2,2),Vector2(unit-4,unit-4))
        _tile(r,color,true)
    if selected:
        var border := Rect2(origin-Vector2(5,5),Vector2(bounds.x*unit+10,bounds.y*unit+10))
        draw_rect(border,Color("#fff0bd"),false,4.0)

func _flower_logo(center: Vector2) -> void:
    var colors := [Color("#8dd4b1"),Color("#e7c77e"),Color("#82b8d4"),Color("#c49bd7")]
    for i in range(4):
        var angle := float(i)*PI*0.5 + pulse*0.08
        draw_circle(center+Vector2(cos(angle),sin(angle))*52.0,28.0,colors[i])
    draw_circle(center,30.0,Color("#f3e7c4"))
    draw_circle(center,12.0,Color("#47716c"))

func _dim() -> void:
    draw_rect(Rect2(0,0,W,H),Color(0,0,0,0.58))

func _cell_rect(x: int,y: int) -> Rect2:
    return Rect2(Vector2(BOARD_X+x*STEP,BOARD_Y+y*STEP),Vector2(CELL,CELL))

func _slot_rect(i: int) -> Rect2:
    return Rect2(58+i*270,1215,245,210)

func _tile_color(index: int,p: Dictionary) -> Color:
    var colors: Array = p.tiles
    return Color(colors[posmod(index,colors.size())])

func _shape_bounds(shape: Array) -> Vector2i:
    var mx := 0
    var my := 0
    for cell in shape:
        mx = maxi(mx,cell.x)
        my = maxi(my,cell.y)
    return Vector2i(mx+1,my+1)

func _fmt(value: int) -> String:
    var s := str(maxi(0,value))
    var out := ""
    while s.length() > 3:
        out = ","+s.substr(s.length()-3,3)+out
        s = s.substr(0,s.length()-3)
    return s+out

func _new_board() -> void:
    board.clear()
    for y in range(N):
        var row: Array = []
        for x in range(N): row.append(-1)
        board.append(row)

func start_new_game(is_daily: bool=false) -> void:
    daily_mode = is_daily
    daily_lines = 0
    score = 0
    total_lines = 0
    combo = 0
    undo_used = false
    undo_snapshot.clear()
    selected_slot = -1
    message = ""
    message_time = 0.0
    _new_board()
    if daily_mode:
        daily_seed = int(Time.get_date_string_from_system().replace("-",""))
        rng.seed = daily_seed
    else:
        rng.randomize()
    _fill_tray()
    screen = Screen.PLAY
    queue_redraw()

func _fill_tray() -> void:
    tray.clear()
    for i in range(3): tray.append(SHAPES[rng.randi_range(0,SHAPES.size()-1)].duplicate())
    selected_slot = -1

func can_place(shape: Array,x: int,y: int) -> bool:
    if shape.is_empty(): return false
    for offset in shape:
        var px := x+offset.x
        var py := y+offset.y
        if px < 0 or py < 0 or px >= N or py >= N: return false
        if int(board[py][px]) >= 0: return false
    return true

func place_piece(slot: int,x: int,y: int) -> bool:
    if screen != Screen.PLAY or slot < 0 or slot >= tray.size() or tray[slot] == null: return false
    var shape: Array = tray[slot]
    if not can_place(shape,x,y): return false
    undo_snapshot = {"board":board.duplicate(true),"tray":tray.duplicate(true),"score":score,"lines":total_lines,"combo":combo,"daily_lines":daily_lines}
    var color_index := rng.randi_range(0,5)
    for offset in shape: board[y+offset.y][x+offset.x] = color_index
    score += shape.size()*10
    tray[slot] = null
    selected_slot = -1
    var cleared := clear_full_lines()
    if cleared > 0:
        combo += 1
        total_lines += cleared
        daily_lines += cleared
        score += cleared*100+(combo-1)*40
        _show_message("GREAT CLEAR  +%d" % (cleared*100))
    else:
        combo = 0
    best_score = maxi(best_score,score)
    if daily_mode and daily_lines >= DAILY_GOAL:
        screen = Screen.DAILY_COMPLETE
    elif _all_tray_used():
        _fill_tray()
        if is_game_over(): screen = Screen.GAME_OVER
    elif is_game_over():
        screen = Screen.GAME_OVER
    _play_sfx("place")
    if cleared > 0:
        _play_sfx("clear")
    _save_profile()
    queue_redraw()
    return true

func clear_full_lines() -> int:
    var rows: Array[int] = []
    var cols: Array[int] = []
    for y in range(N):
        var full := true
        for x in range(N):
            if int(board[y][x]) < 0:
                full = false
                break
        if full:
            rows.append(y)
    for x in range(N):
        var full := true
        for y in range(N):
            if int(board[y][x]) < 0:
                full = false
                break
        if full:
            cols.append(x)
    var clearing: Dictionary = {}
    for row in rows:
        for x in range(N): clearing[Vector2i(x,row)] = true
    for col in cols:
        for y in range(N): clearing[Vector2i(col,y)] = true
    for cell in clearing.keys(): board[cell.y][cell.x] = -1
    return rows.size()+cols.size()

func is_game_over() -> bool:
    for shape in tray:
        if shape == null: continue
        for y in range(N):
            for x in range(N):
                if can_place(shape,x,y): return false
    return true

func _all_tray_used() -> bool:
    for shape in tray:
        if shape != null: return false
    return true

func undo_last_move() -> bool:
    if undo_used or undo_snapshot.is_empty(): return false
    board = undo_snapshot.board.duplicate(true)
    tray = undo_snapshot.tray.duplicate(true)
    score = int(undo_snapshot.score)
    total_lines = int(undo_snapshot.lines)
    combo = int(undo_snapshot.combo)
    daily_lines = int(undo_snapshot.daily_lines)
    undo_used = true
    undo_snapshot.clear()
    screen = Screen.PLAY
    selected_slot = -1
    _show_message("LAST MOVE UNDONE")
    _save_profile()
    queue_redraw()
    return true

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed: _tap(_to_design(event.position))
    elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: _tap(_to_design(event.position))
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        if screen == Screen.PLAY: screen = Screen.PAUSE
        elif screen == Screen.PAUSE: screen = Screen.PLAY
        elif screen != Screen.HOME: screen = Screen.HOME
        queue_redraw()

func _to_design(point: Vector2) -> Vector2:
    var view := get_viewport_rect().size
    return Vector2(point.x*W/maxf(1.0,view.x),point.y*H/maxf(1.0,view.y))

func _tap(point: Vector2) -> void:
    match screen:
        Screen.HOME:
            if BTN_CLASSIC.has_point(point): start_new_game(false)
            elif BTN_DAILY.has_point(point): start_new_game(true)
            elif BTN_HELP.has_point(point): screen = Screen.HELP
        Screen.HELP:
            if Rect2(112,1320,676,100).has_point(point): screen = Screen.HOME
        Screen.PLAY:
            if BTN_THEME.has_point(point):
                palette_index = (palette_index+1)%PALETTES.size()
                _save_profile()
            elif BTN_SOUND.has_point(point):
                sound_enabled = not sound_enabled
                _save_profile()
            elif BTN_PAUSE.has_point(point):
                screen = Screen.PAUSE
            elif BTN_UNDO.has_point(point):
                undo_last_move()
            elif BTN_RESTART.has_point(point):
                start_new_game(daily_mode)
            elif BTN_HOME.has_point(point):
                screen = Screen.HOME
                _save_profile()
            else:
                var slot := _slot_at(point)
                if slot >= 0 and tray[slot] != null:
                    selected_slot = slot
                elif selected_slot >= 0 and _inside_board(point):
                    var cell := Vector2i(int((point.x-BOARD_X)/STEP),int((point.y-BOARD_Y)/STEP))
                    if not place_piece(selected_slot,cell.x,cell.y):
                        _show_message("THAT SPACE ISN'T OPEN")
                        _play_sfx("invalid")
        Screen.PAUSE:
            if Rect2(112,850,676,104).has_point(point): screen = Screen.PLAY
            elif Rect2(112,990,676,100).has_point(point): start_new_game(daily_mode)
            elif Rect2(112,1120,676,92).has_point(point): screen = Screen.HOME
        Screen.GAME_OVER:
            if Rect2(112,960,676,88).has_point(point): undo_last_move()
            elif Rect2(112,1070,676,88).has_point(point): start_new_game(daily_mode)
            elif Rect2(112,1180,676,78).has_point(point): screen = Screen.HOME
        Screen.DAILY_COMPLETE:
            if Rect2(112,850,676,104).has_point(point): start_new_game(false)
            elif Rect2(112,990,676,100).has_point(point): screen = Screen.HOME
    queue_redraw()

func _slot_at(point: Vector2) -> int:
    for i in range(3):
        if _slot_rect(i).has_point(point): return i
    return -1

func _inside_board(point: Vector2) -> bool:
    return Rect2(BOARD_X,BOARD_Y,N*STEP-GAP,N*STEP-GAP).has_point(point)

func _show_message(value: String) -> void:
    message = value
    message_time = 1.5

func _load_profile() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SAVE_PATH) == OK:
        best_score = maxi(0,int(cfg.get_value("profile","best_score",0)))
        palette_index = posmod(int(cfg.get_value("profile","palette_index",0)),PALETTES.size())
        sound_enabled = bool(cfg.get_value("profile","sound_enabled",true))

func _save_profile() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("profile","best_score",best_score)
    cfg.set_value("profile","palette_index",palette_index)
    cfg.set_value("profile","sound_enabled",sound_enabled)
    cfg.save(SAVE_PATH)
