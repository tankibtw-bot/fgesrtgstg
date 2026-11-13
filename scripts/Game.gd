extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/Player.gd")
const ENEMY_SCRIPT = preload("res://scripts/Enemy.gd")
const CHAPTERS := [
    {"title":"01 — СМЕНА", "place":"Жилой уровень NOVA", "radio":"РЕЙН: Алекс, добро пожаловать на объект. Проверьте питание лаборатории и поднимитесь на балкон наблюдения.", "objective":"Осмотрите жилой уровень. Найдите выход к лаборатории.", "kind":"дрон"},
    {"title":"02 — ТЕСТ", "place":"Лаборатория 09", "radio":"СИСТЕМА: Критическая ошибка. РЕЙН: Алекс, если слышите меня — выберитесь из лаборатории!", "objective":"Пройдите через разрушенную лабораторию.", "kind":"дрон"},
    {"title":"03 — ЭВАКУАЦИЯ", "place":"Зона эвакуации", "radio":"РЕЙН: Не идите к лифту. Там Цербер. Спускайтесь к реактору. Только вы знаете схему питания.", "objective":"Пробейтесь через отряд Цербера.", "kind":"Цербер"},
    {"title":"04 — ТЕХНИЧЕСКИЕ ТОННЕЛИ", "place":"Сервисные шахты", "radio":"РЕЙН: Показатели Объекта-09 нестабильны. Не приближайтесь к биомассе.", "objective":"Найдите путь через тоннели.", "kind":"изменённый"},
    {"title":"05 — СВИДЕТЕЛЬ", "place":"Затопленный склад", "radio":"ВОЛКОВ: Они знали, что она живая. Возьмите карту… Уровень минус две тысячи. Не верьте Рейн.", "objective":"Доберитесь до выхода. Волков передал вам ключ-карту.", "kind":"изменённый"},
    {"title":"06 — ЦЕРБЕР", "place":"Монорельс», сектор безопасности", "radio":"КОВАЧ: Морган, ты не должен был выжить. Уходи. У меня приказ, и я его выполню.", "objective":"Прорваться через зону наёмников.", "kind":"Цербер"},
    {"title":"07 — АРХИВ", "place":"Архив NOVA", "radio":"АРХИВ 1987: Объект не проявлял агрессии. Первый контакт — повторяющийся сигнал бедствия.", "objective":"Найдите правду в архиве и продвигайтесь дальше.", "kind":"Цербер"},
    {"title":"08 — КОНТАКТ", "place":"Камера содержания", "radio":"ОБЪЕКТ-09: …БОЛЬ… ТЬМА… ОТПУСТИ…", "objective":"Доберитесь до камеры содержания.", "kind":"изменённый"},
    {"title":"09 — ПРОТОКОЛ", "place":"Коридоры охраны", "radio":"РЕЙН: Протокол уничтожит всё. КОВАЧ: Приказ изменён. Устранить всех, включая руководство NOVA.", "objective":"Переживите последнюю зачистку Цербера.", "kind":"Цербер"},
    {"title":"10 — ЦЕНТР", "place":"Центр управления", "radio":"РЕЙН: Я не прошу прощения. Только закончи это. Аварийный тоннель выведет тебя наверх.", "objective":"Подойдите к панели выбора. Решение за вами.", "kind":"элитный"},
    {"title":"11 — ВЫБОР", "place":"Камера Объекта-09", "radio":"ОБЪЕКТ-09: Я не прошу ничего. Я покажу тебе выход.", "objective":"Сделайте выбор действием: активируйте одну из трёх панелей.", "kind":"элитный"},
    {"title":"12 — ТИШИНА", "place":"Поверхность", "radio":"", "objective":"Кампания завершена. Нажмите E, чтобы начать заново.", "kind":""}
]

var player: CharacterBody3D
var level_root: Node3D
var hud: CanvasLayer
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
var interaction_text := ""
var trigger_used := false
var message_timer := 0.0

func _ready() -> void:
    add_to_group("game")
    _setup_inputs()
    _setup_world()
    _create_player()
    _build_hud()
    _start_chapter(0)

func _process(delta: float) -> void:
    message_timer = maxf(0.0, message_timer - delta)
    if player_lost:
        center_label.text = "СИГНАЛ ПОТЕРЯН\nНажмите E, чтобы начать заново"
        if Input.is_action_just_pressed("interact"):
            get_tree().reload_current_scene()
        return
    _update_objective()
    if Input.is_action_just_pressed("interact"):
        _interact()
    if chapter_index == 11 and chapter_complete and Input.is_action_just_pressed("interact"):
        get_tree().reload_current_scene()

func _setup_inputs() -> void:
    _bind_key("interact", KEY_E)
    _bind_key("jump", KEY_SPACE)
    _bind_key("reload", KEY_R)

func _bind_key(action: String, key: Key) -> void:
    if not InputMap.has_action(action): InputMap.add_action(action)
    var event := InputEventKey.new()
    event.keycode = key
    InputMap.action_add_event(action, event)

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
    env.fog_density = 0.012
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
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.36
    capsule.height = 1.8
    var collision := CollisionShape3D.new()
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
    chapter_index = clampi(index, 0, CHAPTERS.size() - 1)
    chapter_complete = false
    trigger_used = false
    interaction_text = ""
    for child in level_root.get_children(): child.queue_free()
    player.global_position = Vector3(0, 1.0, 13)
    player.velocity = Vector3.ZERO
    _generate_level(chapter_index)
    if chapter_index == 11:
        _finish_ending_scene()
    _update_objective()

func _generate_level(index: int) -> void:
    var chapter: Dictionary = CHAPTERS[index]
    var palette := _chapter_palette(index)
    _box(Vector3(0, -0.5, 0), Vector3(42, 1, 42), palette.floor, true)
    _box(Vector3(0, 2.2, -21), Vector3(42, 5, 1), palette.wall, true)
    _box(Vector3(0, 2.2, 21), Vector3(42, 5, 1), palette.wall, true)
    _box(Vector3(-21, 2.2, 0), Vector3(1, 5, 42), palette.wall, true)
    _box(Vector3(21, 2.2, 0), Vector3(1, 5, 42), palette.wall, true)
    for i in range(7):
        var z := -14.0 + float(i) * 4.5
        _box(Vector3(-7.5 if i % 2 == 0 else 7.5, 1.1, z), Vector3(4.0, 2.2, 2.0), palette.cover, true)
    for i in range(3):
        _box(Vector3(-14 + i * 14, 3.8, -8), Vector3(0.22, 0.18, 4), palette.light, false, true)
    _box(Vector3(0, 0.1, -18.2), Vector3(2.4, 2.2, 0.4), Color(0.15, 0.55, 0.62), true, true)
    _spawn_chapter_props(index, palette)
    if index == 10:
        _make_ending_panels()
    elif index < 11:
        _make_exit()
    var count := 0 if index == 0 or index == 11 else mini(2 + index / 2, 7)
    for i in range(count):
        var spawn := Vector3(-14 + float((i * 11) % 28), 1.0, -8 - float((i * 7) % 8))
        _spawn_enemy(spawn, str(chapter.kind), index)
    if index == 0:
        _spawn_enemy(Vector3(10, 1, -8), "дрон", index)
    if index in [2, 5, 8]:
        player.grant_weapon(1 if index == 2 else 3)
    if index == 6: player.grant_weapon(2)
    if index == 7: player.grant_weapon(5)
    _show_radio(str(chapter.radio))

func _chapter_palette(index: int) -> Dictionary:
    var floors := [Color("41464a"), Color("3b4248"), Color("353c44"), Color("263c43"), Color("354347"), Color("393d45"), Color("353a46"), Color("263842"), Color("3c3b42"), Color("33444a"), Color("273946"), Color("49525b")]
    var walls := [Color("62676b"), Color("4d555b"), Color("4b515d"), Color("28505a"), Color("475a58"), Color("4a4b55"), Color("535269"), Color("315060"), Color("49434b"), Color("345366"), Color("314b58"), Color("66737a")]
    return {"floor": floors[index], "wall": walls[index], "cover": walls[index].darkened(0.18), "light": Color(0.92, 0.64, 0.28) if index < 4 else Color(0.22, 0.78, 0.92)}

func _spawn_chapter_props(index: int, palette: Dictionary) -> void:
    var label_text := str(CHAPTERS[index].place)
    var sign := Label3D.new()
    sign.text = label_text.to_upper()
    sign.font_size = 48
    sign.pixel_size = 0.008
    sign.position = Vector3(-4.3, 3.0, -19.35)
    sign.modulate = palette.light
    level_root.add_child(sign)
    if index == 4:
        for p in [Vector3(-3, 0.1, 4), Vector3(4, 0.1, 6), Vector3(8, 0.1, 2)]:
            _box(p, Vector3(2.5, 0.15, 2), Color(0.12, 0.32, 0.38), false)
    if index == 6:
        _box(Vector3(0, 0.05, -5), Vector3(8, 0.12, 8), Color(0.15, 0.29, 0.35), false, true)
    if index == 9:
        _box(Vector3(0, 0.1, -15), Vector3(5, 0.2, 2), Color(0.75, 0.19, 0.12), false, true)

func _spawn_enemy(pos: Vector3, kind: String, chapter: int) -> void:
    var enemy := CharacterBody3D.new()
    enemy.set_script(ENEMY_SCRIPT)
    var hp := 50 + chapter * 4
    var speed := 3.0 + minf(float(chapter) * 0.08, 1.3)
    var damage := 9 + chapter
    if kind == "дрон":
        hp = 30
        speed = 3.8
        damage = 7
    elif kind == "Цербер":
        hp = 75
        speed = 2.7
        damage = 12
    elif kind == "элитный":
        hp = 150
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
    var door := Area3D.new()
    door.name = "ExitDoor"
    door.position = Vector3(0, 1.1, -18.5)
    door.set_meta("exit", true)
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(3.0, 2.4, 1.5)
    collision.shape = shape
    door.add_child(collision)
    var marker := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3(2.6, 2.0, 0.18)
    marker.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.08, 0.7, 0.62)
    mat.emission_enabled = true
    mat.emission = Color(0.03, 0.38, 0.32)
    marker.material_override = mat
    door.add_child(marker)
    level_root.add_child(door)

func _make_ending_panels() -> void:
    var labels := ["УНИЧТОЖИТЬ", "ОСВОБОДИТЬ", "УЙТИ"]
    var colors := [Color(0.85, 0.2, 0.12), Color(0.15, 0.75, 0.85), Color(0.8, 0.72, 0.3)]
    for i in range(3):
        var x := float(i - 1) * 5.5
        _box(Vector3(x, 1.3, -13.8), Vector3(2.2, 2.6, 0.6), Color(0.2, 0.23, 0.28), true)
        var panel := Area3D.new()
        panel.name = "EndingPanel%d" % i
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
        var glow := MeshInstance3D.new()
        var box := BoxMesh.new()
        box.size = Vector3(1.2, 0.35, 0.08)
        glow.mesh = box
        glow.position = Vector3(0, 0.55, -0.15)
        var material := StandardMaterial3D.new()
        material.albedo_color = colors[i]
        material.emission_enabled = true
        material.emission = colors[i]
        glow.material_override = material
        panel.add_child(glow)
        level_root.add_child(panel)

func _box(pos: Vector3, size: Vector3, color: Color, solid: bool, emissive: bool = false) -> void:
    var body: Node3D
    if solid: body = StaticBody3D.new()
    else: body = Node3D.new()
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
    add_child(hud)
    var top := Label.new()
    top.name = "Chapter"
    top.position = Vector2(18, 12)
    top.add_theme_font_size_override("font_size", 18)
    top.modulate = Color(0.74, 0.88, 0.92)
    hud.add_child(top)
    health_label = _label(Vector2(18, 42), 22, Color(0.95, 0.35, 0.3))
    weapon_label = _label(Vector2(18, 492), 18, Color(0.85, 0.9, 0.92))
    ammo_label = _label(Vector2(790, 492), 20, Color(0.98, 0.82, 0.38))
    objective_label = _label(Vector2(250, 12), 17, Color(0.95, 0.88, 0.68))
    objective_label.size = Vector2(650, 54)
    radio_label = _label(Vector2(20, 395), 16, Color(0.58, 0.86, 0.91))
    radio_label.size = Vector2(900, 74)
    radio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    center_label = _label(Vector2(250, 240), 24, Color(1, 1, 1))
    center_label.size = Vector2(460, 110)
    center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var crosshair := _label(Vector2(471, 253), 24, Color(0.9, 0.95, 0.85))
    crosshair.text = "+"
    var controls := _label(Vector2(655, 12), 14, Color(0.65, 0.7, 0.75))
    controls.text = "WASD движение • Shift бег • Space прыжок\nЛКМ огонь • R перезарядка • 1–6 оружие • E действие"
    controls.size = Vector2(290, 42)
    controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var chapter_label := top
    chapter_label.text = "ABYSS — NOVA DEEP FACILITY"

func _label(pos: Vector2, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.position = pos
    label.add_theme_font_size_override("font_size", font_size)
    label.modulate = color
    hud.add_child(label)
    return label

func _show_radio(text: String) -> void:
    radio_label.text = text
    message_timer = 12.0

func _on_stats_changed(health: int, weapon: String, ammo: String) -> void:
    health_label.text = "ЗДОРОВЬЕ  %03d" % health
    weapon_label.text = "ОРУЖИЕ: " + weapon
    ammo_label.text = ammo

func _on_player_died() -> void:
    player_lost = true
    center_label.text = "СИГНАЛ ПОТЕРЯН\nНажмите E, чтобы начать заново"

func _update_objective() -> void:
    var chapter: Dictionary = CHAPTERS[chapter_index]
    var title := str(chapter.title)
    get_node("CanvasLayer/Chapter").text = title + "  |  " + str(chapter.place)
    var enemies := get_tree().get_nodes_in_group("enemy")
    if chapter_index == 11:
        objective_label.text = "КОНЕЦ: " + ending.to_upper() + "   •   Нажмите E, чтобы начать заново"
        center_label.text = _ending_text()
        chapter_complete = true
        return
    if chapter_index == 10:
        objective_label.text = "Решение за вами. Подойдите к панели и нажмите E."
        center_label.text = "ТРИ ПУТИ.\nОДИН ВЫБОР."
        return
    if enemies.is_empty():
        chapter_complete = true
        objective_label.text = "ЦЕЛЬ ВЫПОЛНЕНА  •  Найдите зелёную дверь и нажмите E"
        center_label.text = "ПУТЬ ОТКРЫТ\nИщите зелёный выход"
    else:
        chapter_complete = false
        objective_label.text = str(chapter.objective) + "   •   ЦЕЛИ: " + str(enemies.size())
        center_label.text = ""

func _interact() -> void:
    if chapter_index == 11 and chapter_complete:
        get_tree().reload_current_scene()
        return
    if chapter_index == 10:
        for node in level_root.get_children():
            if node is Area3D and node.has_meta("ending") and player.global_position.distance_to(node.global_position) < 3.2:
                var choice: int = int(node.get_meta("ending"))
                ending = ["Уничтожить", "Освободить", "Уйти"][choice]
                chapter_complete = true
                _start_chapter(11)
                return
    if not chapter_complete:
        return
    var door_pos := Vector3(0, 1.1, -18.5)
    if player.global_position.distance_to(door_pos) < 4.0:
        _start_chapter(chapter_index + 1)

func create_explosion(point: Vector3, damage: int) -> void:
    for enemy in get_tree().get_nodes_in_group("enemy"):
        var distance := enemy.global_position.distance_to(point)
        if distance < 6.0:
            enemy.take_damage(int(float(damage) * (1.0 - distance / 8.0)))
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

func _finish_ending_scene() -> void:
    for child in level_root.get_children():
        if child is Area3D: child.queue_free()
    var color := Color(0.7, 0.75, 0.78)
    _box(Vector3(0, 4, -7), Vector3(42, 0.4, 30), Color(0.34, 0.42, 0.48), false)
    var sun := OmniLight3D.new()
    sun.position = Vector3(0, 7, -5)
    sun.light_color = color
    sun.light_energy = 3.0
    sun.omni_range = 24.0
    level_root.add_child(sun)

func _ending_text() -> String:
    match ending:
        "Уничтожить": return "Пыль оседает на склоне.\n«Надеюсь, это было правильно»."
        "Освободить": return "Она уходит в чистое небо.\n«Монстрами были мы»."
        "Уйти": return "Рассвет. Глубоко внизу всё ещё горит свет.\n«Я просто хотел домой»."
    return "Кампания завершена"
