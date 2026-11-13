extends Node3D

var enemy_scene = preload("res://scenes/Enemy.tscn")

@onready var player: CharacterBody3D = $Player

var hud: CanvasLayer
var health_label: Label
var ammo_label: Label
var status_label: Label
var crosshair: Label

func _ready() -> void:
    build_level()
    build_hud()
    player.connect("health_changed", _on_health_changed)
    player.connect("ammo_changed", _on_ammo_changed)
    spawn_enemies()

func _process(_delta: float) -> void:
    if status_label == null:
        return

    var enemy_count = get_tree().get_nodes_in_group("enemy").size()

    if player.dead:
        status_label.text = "YOU ARE DEAD — PRESS R TO RESTART"
        if Input.is_key_pressed(KEY_R):
            get_tree().reload_current_scene()
        return

    if enemy_count == 0:
        status_label.text = "LEVEL CLEAR — PRESS R TO RESTART"
        if Input.is_key_pressed(KEY_R):
            get_tree().reload_current_scene()
    else:
        status_label.text = "ENEMIES LEFT: %d" % enemy_count

func build_level() -> void:
    # floor
    add_box(Vector3(0, -0.5, 0), Vector3(40, 1, 40), Color(0.16, 0.16, 0.18))

    # walls
    add_box(Vector3(0, 2, -20), Vector3(40, 4, 1), Color(0.26, 0.28, 0.33))
    add_box(Vector3(0, 2, 20), Vector3(40, 4, 1), Color(0.26, 0.28, 0.33))
    add_box(Vector3(-20, 2, 0), Vector3(1, 4, 40), Color(0.26, 0.28, 0.33))
    add_box(Vector3(20, 2, 0), Vector3(1, 4, 40), Color(0.26, 0.28, 0.33))

    # cover blocks
    add_box(Vector3(-8, 1, -5), Vector3(6, 2, 3), Color(0.36, 0.38, 0.44))
    add_box(Vector3(8, 1, 5), Vector3(6, 2, 3), Color(0.36, 0.38, 0.44))
    add_box(Vector3(-4, 1, 10), Vector3(3, 2, 7), Color(0.4, 0.44, 0.5))
    add_box(Vector3(10, 1, -9), Vector3(5, 2, 5), Color(0.4, 0.44, 0.5))

    # lights
    var light = DirectionalLight3D.new()
    light.position = Vector3(0, 12, 0)
    light.rotation_degrees = Vector3(-35, 40, 0)
    light.light_energy = 1.4
    add_child(light)

    var env = WorldEnvironment.new()
    var sky = Environment.new()
    sky.background_mode = Environment.BG_COLOR
    sky.background_color = Color(0.06, 0.06, 0.08)
    sky.ambient_light_color = Color(0.9, 0.92, 1.0)
    sky.ambient_light_energy = 0.8
    sky.tonemap_mode = Environment.TONE_MAPPER_LINEAR
    env.environment = sky
    add_child(env)

func add_box(position: Vector3, size: Vector3, color: Color = Color(0.3, 0.3, 0.3)) -> void:
    var body = StaticBody3D.new()
    body.position = position

    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = size
    mesh.mesh = box

    var material = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.8
    mesh.material_override = material

    var collision = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = size
    collision.shape = shape

    body.add_child(mesh)
    body.add_child(collision)
    add_child(body)

func build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)

    var root = MarginContainer.new()
    root.anchor_right = 1.0
    root.anchor_bottom = 1.0
    root.offset_left = 24
    root.offset_top = 18
    root.offset_right = -24
    root.offset_bottom = -18
    hud.add_child(root)

    var vbox = VBoxContainer.new()
    root.add_child(vbox)

    health_label = Label.new()
    health_label.text = "HEALTH: 100"
    health_label.add_theme_font_size_override("font_size", 24)
    health_label.modulate = Color(0.95, 0.3, 0.3)
    vbox.add_child(health_label)

    ammo_label = Label.new()
    ammo_label.text = "AMMO: 30 / 90"
    ammo_label.add_theme_font_size_override("font_size", 24)
    ammo_label.modulate = Color(0.97, 0.9, 0.5)
    vbox.add_child(ammo_label)

    status_label = Label.new()
    status_label.text = "ENEMIES LEFT: 0"
    status_label.position = Vector2(0, 0)
    status_label.add_theme_font_size_override("font_size", 20)
    status_label.modulate = Color(0.9, 0.95, 1.0)
    status_label.anchor_left = 0.5
    status_label.anchor_top = 1.0
    status_label.anchor_right = 0.5
    status_label.anchor_bottom = 1.0
    status_label.offset_left = -150
    status_label.offset_top = -70
    status_label.offset_right = 150
    status_label.offset_bottom = -20
    hud.add_child(status_label)

    crosshair = Label.new()
    crosshair.text = "+"
    crosshair.add_theme_font_size_override("font_size", 32)
    crosshair.modulate = Color(1, 1, 1)
    crosshair.anchor_left = 0.5
    crosshair.anchor_top = 0.5
    crosshair.anchor_right = 0.5
    crosshair.anchor_bottom = 0.5
    crosshair.offset_left = -12
    crosshair.offset_top = -16
    crosshair.offset_right = 12
    crosshair.offset_bottom = 16
    hud.add_child(crosshair)

func _on_health_changed(value: int) -> void:
    health_label.text = "HEALTH: %d" % value

func _on_ammo_changed(current: int, reserve: int) -> void:
    ammo_label.text = "AMMO: %d / %d" % [current, reserve]

func spawn_enemies() -> void:
    var spawn_positions = [
        Vector3(-10, 1.2, -10),
        Vector3(12, 1.2, -8),
        Vector3(-12, 1.2, 8),
        Vector3(8, 1.2, 12),
        Vector3(-2, 1.2, -14),
        Vector3(15, 1.2, 3),
    ]

    for spawn_pos in spawn_positions:
        var enemy = enemy_scene.instantiate()
        enemy.position = spawn_pos
        add_child(enemy)

