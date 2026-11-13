extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/Player.gd")
const ENEMY_SCRIPT = preload("res://scripts/Enemy.gd")
const CHAPTER_TITLES := ["СМЕНА", "ТЕСТ", "ЭВАКУАЦИЯ", "ТЕХНИЧЕСКИЕ ТОННЕЛИ", "СВИДЕТЕЛЬ", "ЦЕРБЕР", "АРХИВ", "КОНТАКТ", "ПРОТОКОЛ", "ЦЕНТР", "ВЫБОР", "ТИШИНА"]
const CHAPTER_PLACES := ["Жилой уровень NOVA", "Лаборатория 09", "Зона эвакуации", "Сервисные шахты", "Затопленный склад", "Сектор безопасности", "Архив NOVA", "Камера содержания", "Коридоры охраны", "Центр управления", "Камера Объекта-09", "Поверхность"]
const CHAPTER_RADIO := [
    "РЕЙН: Алекс, добро пожаловать на объект. Проверьте питание лаборатории и поднимитесь на балкон наблюдения.",
    "СИСТЕМА: Критическая ошибка. РЕЙН: Алекс, если слышите меня — выберитесь из лаборатории!",
    "РЕЙН: Не идите к лифту. Там Цербер. Спускайтесь к реактору. Только вы знаете схему питания.",
    "РЕЙН: Показатели Объекта-09 нестабильны. Не приближайтесь к биомассе.",
    "ВОЛКОВ: Они знали, что она живая. Возьмите карту… Уровень минус две тысячи. Не верьте Рейн.",
    "КОВАЧ: Морган, ты не должен был выжить. Уходи. У меня приказ, и я его выполню.",
    "АРХИВ 1987: Объект не проявлял агрессии. Первый контакт — повторяющийся сигнал бедствия.",
    "ОБЪЕКТ-09: …БОЛЬ… ТЬМА… ОТПУСТИ…",
    "РЕЙН: Протокол уничтожит всё. КОВАЧ: Приказ изменён. Устранить всех, включая руководство NOVA.",
    "РЕЙН: Я не прошу прощения. Только закончи это. Аварийный тоннель выведет тебя наверх.",
    "ОБЪЕКТ-09: Я не прошу ничего. Я покажу тебе выход.",
    ""
]
const CHAPTER_OBJECTIVES := [
    "Осмотрите жилой уровень и найдите путь к лаборатории.", "Пройдите через разрушенную лабораторию.", "Пробейтесь через отряд Цербера.", "Найдите путь через технические тоннели.", "Доберитесь до выхода. Волков передал вам ключ-карту.", "Прорвитесь через зону наёмников.", "Найдите правду в архиве и продвигайтесь дальше.", "Доберитесь до камеры содержания.", "Переживите последнюю зачистку Цербера.", "Доберитесь до панели управления.", "Решите судьбу Объекта-09.", "Кампания завершена. Нажмите E, чтобы вернуться в меню."
]
const FLOOR_COLORS := ["41464a", "3b4248", "353c44", "263c43", "354347", "393d45", "353a46", "263842", "3c3b42", "33444a", "273946", "49525b"]
const WALL_COLORS := ["62676b", "4d555b", "4b515d", "28505a", "475a58", "4a4b55", "535269", "315060", "49434b", "345366", "314b58", "66737a"]

var player: CharacterBody3D
var level_root: Node3D
var hud: CanvasLayer
var chapter_label: Label
var health_label: Label
var weapon_label: Label
var ammo_label: Label
var objective_label: Label
var radio_label: Label
var center_label: Label
var chapter_index := 0
var ending := ""
var chapter_complete := false
var player_lost := false
var last_radio := ""
var damage_flash: ColorRect

func _ready() -> void:
    add_to_group("game")
    _setup_world()
    _create_player()
    _build_hud()
    chapter_index = clampi(CampaignState.current_chapter, 0, CHAPTER_TITLES.size() - 1)
    ending = CampaignState.last_ending
    _start_chapter(chapter_index)

func _process(_delta: float) -> void:
    if player_lost:
        center_label.text = "СИГНАЛ ПОТЕРЯН\nНажмите E, чтобы начать главу заново"
        if Input.is_key_pressed(KEY_E) and Input.is_action_just_pressed("ui_accept"):
            restart_current_chapter()
        return
    _update_objective()
    if Input.is_key_pressed(KEY_E) and Input.is_action_just_pressed("ui_accept"):
        _interact()

func _setup_world() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.025, 0.035, 0.05)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.55, 0.62, 0.72)
    env.ambient_light_energy = 0.75
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.fog_enabled = true
    env.fog_light_color = Color(0.09, 0.12, 0.16)
    env.fog_density = 0.009
    env_node.environment = env
    add_child(env_node)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -30, 0)
    sun.light_energy = 0.65
    add_child(sun)
    level_root = Node3D.new()
    level_root.name = "GeneratedLevel"
    add_child(level_root)

func _create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCRIPT)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.36
    capsule.height = 1.8
    collision.shape = capsule
    player.add_child(collision)
    var head := Node3D.new()
    head.name = "Head"
    head.position.y = 0.62
    player.add_child(head)
    var camera := Camera3D.new()
    camera.name = "Camera3D"
    camera.current = true
    camera.fov = 82.0
    head.add_child(camera)
    var gun := MeshInstance3D.new()
    gun.name = "RetroWeapon"
    var gun_mesh := BoxMesh.new()
    gun_mesh.size = Vector3(0.18, 0.16, 0.48)
    gun.mesh = gun_mesh
    gun.position = Vector3(0.28, -0.22, -0.48)
    var metal := StandardMaterial3D.new()
    metal.albedo_color = Color(0.22, 0.25, 0.27)
    gun.material_override = metal
    camera.add_child(gun)
    player.position = Vector3(0, 1.0, 13)
    add_child(player)
    player.stats_changed.connect(_on_stats_changed)
    player.player_died.connect(_on_player_died)

func _start_chapter(index: int) -> void:
    chapter_index = clampi(index, 0, CHAPTER_TITLES.size() - 1)
    CampaignState.current_chapter = chapter_index
    CampaignState.selected_chapter = chapter_index
    CampaignState.campaign_started = true
    CampaignState.call("_write_save")
    chapter_complete = false
    player_lost = false
    for child in level_root.get_children():
        child.free()
    player.global_position = Vector3(0, 1.0, 13)
    player.velocity = Vector3.ZERO
    player.dead = false
    player.health = 100
    player._publish_stats()
    _generate_level(chapter_index)
    _update_objective()
    _show_radio(CHAPTER_RADIO[chapter_index])

func restart_current_chapter() -> void:
    _start_chapter(chapter_index)

func _generate_level(index: int) -> void:
    var floor_color := Color(FLOOR_COLORS[index])
    var wall_color := Color(WALL_COLORS[index])
    var accent := Color("e0a34d") if index < 3 else Color("42bdd0")
    _box(Vector3(0, -0.5, 0), Vector3(42, 1, 42), floor_color, true)
    _box(Vector3(0, 2.2, -21), Vector3(42, 5, 1), wall_color, true)
    _box(Vector3(0, 2.2, 21), Vector3(42, 5, 1), wall_color, true)
    _box(Vector3(-21, 2.2, 0), Vector3(1, 5, 42), wall_color, true)
    _box(Vector3(21, 2.2, 0), Vector3(1, 5, 42), wall_color, true)
    for i in range(7):
        var z := -14.0 + float(i) * 4.5
        var side := -7.5 if i % 2 == 0 else 7.5
        _box(Vector3(side, 1.1, z), Vector3(4.0, 2.2, 2.0), wall_color.darkened(0.18), true)
    for i in range(3):
        _box(Vector3(-14 + i * 14, 3.8, -8), Vector3(0.22, 0.18, 4), accent, false, true)
    _make_chapter_set_dressing(index, accent)
    if index == 10:
        _make_ending_panels()
    elif index < 11:
        _make_exit()
    var enemy_count := 0
    if index in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
        enemy_count = mini(1 + index / 3, 4)
    if index == 10:
        enemy_count = 1
    for i in range(enemy_count):
        var spawn := Vector3(-13.0 + float((i * 13) % 26), 1.0, -7.0 - float((i * 9) % 9))
        var kind := _enemy_kind_for_chapter(index, i)
        _spawn_enemy(spawn, kind, index)
    if index == 2: player.grant_weapon(1)
    elif index == 5: player.grant_weapon(3)
    elif index == 6: player.grant_weapon(2)
    elif index == 7: player.grant_weapon(5)
    if index == 11: _build_epilogue()

func _enemy_kind_for_chapter(index: int, enemy_number: int) -> String:
    if index == 1: return "дрон"
    if index in [2, 5, 8, 9]: return "Цербер"
    if index == 10: return "элитный"
    if enemy_number == 0 and index in [3, 4, 7]: return "изменённый"
    return "Цербер" if enemy_number % 2 == 0 else "изменённый"

func _make_chapter_set_dressing(index: int, accent: Color) -> void:
    var sign := Label3D.new()
    sign.text = CHAPTER_PLACES[index].to_upper()
    sign.font_size = 48
    sign.pixel_size = 0.008
    sign.position = Vector3(-5.0, 3.0, -19.35)
    sign.modulate = accent
    level_root.add_child(sign)
    if index == 0:
        _box(Vector3(-13, 1.1, 3), Vector3(3.0, 2.2, 2.0), Color("53615e"), true)
        _box(Vector3(13, 1.1, 3), Vector3(3.0, 2.2, 2.0), Color("53615e"), true)
        _box(Vector3(0, 2.8, -2), Vector3(12, 0.18, 3), Color("70787b"), false)
    elif index == 1 or index == 7:
        _box(Vector3(0, 0.1, -3), Vector3(9, 0.12, 9), Color("123b4b"), false, true)
        for p in [Vector3(-12, 1.0, 3), Vector3(12, 1.0, -1), Vector3(0, 1.0, -13)]:
            _box(p, Vector3(1.0, 2.0, 1.0), Color("727b7d"), true)
    elif index == 3:
        _box(Vector3(0, 2.4, 0), Vector3(2.2, 4.8, 32), Color("27373c"), true)
        _box(Vector3(-7, 2.4, -7), Vector3(14, 4.8, 1), Color("27373c"), true)
        _box(Vector3(7, 2.4, 7), Vector3(14, 4.8, 1), Color("27373c"), true)
    elif index == 4:
        for p in [Vector3(-3, 0.1, 4), Vector3(4, 0.1, 6), Vector3(8, 0.1, 2)]:
            _box(p, Vector3(3.0, 0.14, 3.0), Color("123e49"), false, true)
        _box(Vector3(-13, 1.0, -9), Vector3(2, 2, 5), Color("5c615c"), true)
    elif index == 6:
        for i in range(5):
            _box(Vector3(-14 + i * 7, 1.5, -4), Vector3(1.0, 3.0, 7.0), Color("59566b"), true)
    elif index == 8 or index == 9:
        _box(Vector3(0, 0.1, -15), Vector3(5, 0.2, 2), Color("9b3023"), false, true)
        _box(Vector3(-13, 1.1, -8), Vector3(2, 2.2, 4), Color("48535c"), true)
        _box(Vector3(13, 1.1, -8), Vector3(2, 2.2, 4), Color("48535c"), true)

func _spawn_enemy(pos: Vector3, kind: String, chapter: int) -> void:
    var enemy := CharacterBody3D.new()
    enemy.set_script(ENEMY_SCRIPT)
    var hp := 48 + chapter * 5
    var speed := 3.0 + minf(float(chapter) * 0.06, 1.0)
    var damage := 9 + chapter
    if kind == "дрон":
        hp = 30
        speed = 3.8
        damage = 7
    elif kind == "Цербер":
        hp = 68
        speed = 2.7
        damage = 11
    elif kind == "элитный":
        hp = 180
        speed = 2.4
        damage = 18
    enemy.configure(kind, hp, speed, damage)
    enemy.position = pos
    var shape := CapsuleShape3D.new()
    shape.radius = 0.42 if kind != "элитный" else 0.7
    shape.height = 1.55 if kind != "элитный" else 2.3
    var collision := CollisionShape3D.new()
    collision.shape = shape
    enemy.add_child(collision)
    var visual := MeshInstance3D.new()
    visual.name = "MeshInstance3D"
    var mesh := CapsuleMesh.new()
    mesh.radius = shape.radius
    mesh.height = shape.height
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    if kind == "Цербер": material.albedo_color = Color("596b7c")
    elif kind == "дрон": material.albedo_color = Color("d58a45")
    elif kind == "элитный": material.albedo_color = Color("753f54")
    else: material.albedo_color = Color("6e9a80")
    material.roughness = 1.0
    visual.material_override = material
    enemy.add_child(visual)
    level_root.add_child(enemy)

func _make_exit() -> void:
    _box(Vector3(0, 1.1, -18.5), Vector3(2.8, 2.2, 0.22), Color("0c594f"), false, true)

func _make_ending_panels() -> void:
    var labels := ["УНИЧТОЖИТЬ", "ОСВОБОДИТЬ", "УЙТИ"]
    var colors := [Color("d9442e"), Color("38c4d6"), Color("d3b64c")]
    for i in range(3):
        var x := float(i - 1) * 5.5
        _box(Vector3(x, 1.3, -13.8), Vector3(2.2, 2.6, 0.6), Color("202b32"), true)
        var panel := Area3D.new()
        panel.position = Vector3(x, 1.3, -12.9)
        panel.set_meta("ending", i)
        var shape := BoxShape3D.new()
        shape.size = Vector3(2.4, 2.6, 1.8)
        var collision := CollisionShape3D.new()
        collision.shape = shape
        panel.add_child(collision)
        var text := Label3D.new()
        text.text = labels[i] + "\n[E]"
        text.font_size = 34
        text.position.y = 1.6
        text.modulate = colors[i]
        panel.add_child(text)
        level_root.add_child(panel)

func _box(pos: Vector3, size: Vector3, color: Color, solid: bool, emissive: bool = false) -> void:
    var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
    body.position = pos
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 1.0
    if emissive:
        material.emission_enabled = true
        material.emission = color * 0.35
    visual.material_override = material
    body.add_child(visual)
    if solid:
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
    level_root.add_child(body)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    hud.name = "HUD"
    add_child(hud)
    chapter_label = _label(Vector2(18, 12), 17, Color("bcd0d4"))
    health_label = _label(Vector2(18, 40), 21, Color("f05a4f"))
    objective_label = _label(Vector2(240, 12), 16, Color("f0d89c"))
    objective_label.size = Vector2(470, 48)
    radio_label = _label(Vector2(20, 394), 16, Color("75c9d4"))
    radio_label.size = Vector2(900, 70)
    radio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    weapon_label = _label(Vector2(18, 492), 17, Color("d9e1e2"))
    ammo_label = _label(Vector2(800, 492), 20, Color("f5d276"))
    center_label = _label(Vector2(270, 230), 23, Color.WHITE)
    center_label.size = Vector2(420, 100)
    center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var crosshair := _label(Vector2(471, 253), 24, Color("e8f4e3"))
    crosshair.text = "+"
    var controls := _label(Vector2(650, 12), 13, Color("81969e"))
    controls.text = "WASD движение • Shift бег • Space прыжок\nЛКМ огонь • R перезарядка • 1–6 оружие • E действие"
    controls.size = Vector2(300, 44)
    controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    damage_flash = ColorRect.new()
    damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    damage_flash.color = Color(0.8, 0.05, 0.02, 0.0)
    damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(damage_flash)

func _label(pos: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.modulate = color
    hud.add_child(label)
    return label

func _show_radio(text: String) -> void:
    last_radio = text
    radio_label.text = text

func _on_stats_changed(value: int, weapon: String, ammo: String) -> void:
    health_label.text = "ЗДОРОВЬЕ  %03d" % value
    weapon_label.text = "ОРУЖИЕ: " + weapon
    ammo_label.text = ammo

func _on_player_died() -> void:
    player_lost = true
    center_label.text = "СИГНАЛ ПОТЕРЯН\nНажмите E, чтобы начать главу заново"

func _update_objective() -> void:
    chapter_label.text = "%02d  |  %s — %s" % [chapter_index + 1, CHAPTER_TITLES[chapter_index], CHAPTER_PLACES[chapter_index]]
    var enemies := get_tree().get_nodes_in_group("enemy")
    if chapter_index == 11:
        objective_label.text = "ФИНАЛ: " + ending.to_upper() + "   •   E — главное меню"
        center_label.text = _ending_text()
        chapter_complete = true
    elif chapter_index == 10:
        objective_label.text = "Подойдите к одной из трёх панелей и нажмите E."
        center_label.text = "ТРИ ПУТИ.\nОДИН ВЫБОР."
    elif enemies.is_empty():
        chapter_complete = true
        objective_label.text = "ЦЕЛЬ ВЫПОЛНЕНА  •  Найдите зелёный выход и нажмите E"
        center_label.text = "ПУТЬ ОТКРЫТ\nИщите зелёный выход"
    else:
        chapter_complete = false
        objective_label.text = CHAPTER_OBJECTIVES[chapter_index] + "   •   ЦЕЛИ: " + str(enemies.size())
        center_label.text = ""

func _interact() -> void:
    if chapter_index == 11:
        get_tree().change_scene_to_file("res://scenes/Menu.tscn")
        return
    if chapter_index == 10:
        for node in level_root.get_children():
            if node is Area3D and node.has_meta("ending") and player.global_position.distance_to(node.global_position) < 3.2:
                ending = ["Уничтожить", "Освободить", "Уйти"][int(node.get_meta("ending"))]
                CampaignState.set_ending(ending)
                _start_chapter(11)
                return
    if not chapter_complete:
        _show_radio("Сначала выполните цель главы.")
        return
    var exit_position := Vector3(0, 1.1, -18.5)
    if player.global_position.distance_to(exit_position) < 4.0:
        CampaignState.mark_chapter_complete(chapter_index)
        player.heal(25)
        _start_chapter(chapter_index + 1)
    else:
        _show_radio("Выход отмечен зелёным светом — найдите его.")

func create_explosion(point: Vector3, damage: int) -> void:
    for enemy in get_tree().get_nodes_in_group("enemy"):
        var distance := enemy.global_position.distance_to(point)
        if distance < 6.0:
            enemy.take_damage(int(float(damage) * maxf(0.0, 1.0 - distance / 8.0)))
    var flash := OmniLight3D.new()
    flash.position = point
    flash.light_color = Color(1.0, 0.48, 0.12)
    flash.light_energy = 4.0
    flash.omni_range = 7.0
    level_root.add_child(flash)
    get_tree().create_timer(0.12).timeout.connect(flash.queue_free)

func melee_swing(origin: Vector3, direction: Vector3) -> void:
    for enemy in get_tree().get_nodes_in_group("enemy"):
        var offset: Vector3 = enemy.global_position - origin
        if offset.length() < 2.7 and direction.dot(offset.normalized()) > 0.45:
            enemy.take_damage(45)

func _build_epilogue() -> void:
    var ground := StandardMaterial3D.new()
    ground.albedo_color = Color("344652")
    _box(Vector3(0, 8, -22), Vector3(80, 0.5, 60), Color("263c49"), false)
    var sky_light := OmniLight3D.new()
    sky_light.position = Vector3(0, 8, -10)
    sky_light.light_color = Color("91cbdc")
    sky_light.light_energy = 2.5
    sky_light.omni_range = 35.0
    level_root.add_child(sky_light)
    for i in range(9):
        var ridge := _box(Vector3(-30 + i * 7.5, 2.0 + (i % 3) * 1.2, -26 - (i % 2) * 6), Vector3(8, 5 + (i % 3), 5), Color("40545c"), false)
        ridge.rotation_degrees.y = float(i * 19)

func _ending_text() -> String:
    match ending:
        "Уничтожить": return "Пыль оседает на склоне.\n«Надеюсь, это было правильно»."
        "Освободить": return "Она уходит в чистое небо.\n«Монстрами были мы»."
        "Уйти": return "Рассвет. Глубоко внизу всё ещё горит свет.\n«Я просто хотел домой»."
    return "Кампания завершена"
