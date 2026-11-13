extends CharacterBody3D

signal stats_changed(health: int, weapon_name: String, ammo_text: String)
signal player_died

const WALK_SPEED := 6.2
const SPRINT_SPEED := 8.8
const JUMP_SPEED := 6.0
const GRAVITY := 18.0
const WEAPONS := [
    {"name":"Монтировка", "mag":0, "reserve":0, "damage":45, "rate":0.42, "range":2.7},
    {"name":"Пистолет", "mag":12, "reserve":72, "damage":28, "rate":0.28, "range":70.0},
    {"name":"Дробовик", "mag":8, "reserve":32, "damage":13, "rate":0.82, "range":32.0},
    {"name":"Автомат", "mag":30, "reserve":120, "damage":18, "rate":0.095, "range":85.0},
    {"name":"Граната", "mag":4, "reserve":8, "damage":100, "rate":0.8, "range":15.0},
    {"name":"Импульсная", "mag":20, "reserve":80, "damage":42, "rate":0.2, "range":90.0},
]

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var health := 100
var pitch := 0.0
var yaw := 0.0
var selected_weapon := 0
var magazines := [0, 12, 8, 30, 4, 20]
var reserves := [0, 72, 32, 120, 8, 80]
var fire_cooldown := 0.0
var dead := false
var reloading := false
var reload_left := 0.0
var recoil := 0.0
var mouse_sensitivity := 0.0022

func _ready() -> void:
    add_to_group("player")
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _publish_stats()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not dead:
        yaw -= event.relative.x * mouse_sensitivity
        pitch = clampf(pitch - event.relative.y * mouse_sensitivity, -1.42, 1.42)
        rotation.y = yaw
        head.rotation.x = pitch
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
        if event.keycode >= KEY_1 and event.keycode <= KEY_6:
            equip(int(event.keycode) - int(KEY_1))
        if event.keycode == KEY_R:
            start_reload()

func _process(delta: float) -> void:
    if fire_cooldown > 0.0:
        fire_cooldown -= delta
    if recoil > 0.0:
        recoil = move_toward(recoil, 0.0, delta * 2.4)
    if reloading:
        reload_left -= delta
        if reload_left <= 0.0:
            finish_reload()
    if not dead and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and selected_weapon == 3:
            fire()
        elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_cooldown <= 0.0:
            fire()

func _physics_process(delta: float) -> void:
    if dead:
        return
    var move_input := Vector2.ZERO
    if Input.is_key_pressed(KEY_W): move_input.y -= 1.0
    if Input.is_key_pressed(KEY_S): move_input.y += 1.0
    if Input.is_key_pressed(KEY_A): move_input.x -= 1.0
    if Input.is_key_pressed(KEY_D): move_input.x += 1.0
    if move_input.length_squared() > 1.0:
        move_input = move_input.normalized()
    var forward := -global_transform.basis.z
    var right := global_transform.basis.x
    var wish := (forward * move_input.y + right * move_input.x).normalized()
    var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
    if wish.length_squared() > 0.0:
        velocity.x = move_toward(velocity.x, wish.x * speed, 28.0 * delta)
        velocity.z = move_toward(velocity.z, wish.z * speed, 28.0 * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
    if is_on_floor():
        if Input.is_key_pressed(KEY_SPACE): velocity.y = JUMP_SPEED
        else: velocity.y = -0.15
    else:
        velocity.y -= GRAVITY * delta
    move_and_slide()

func equip(index: int) -> void:
    if index < 0 or index >= WEAPONS.size() or index == selected_weapon:
        return
    selected_weapon = index
    reloading = false
    fire_cooldown = 0.0
    _publish_stats()

func fire() -> void:
    if dead or reloading or fire_cooldown > 0.0:
        return
    var weapon: Dictionary = WEAPONS[selected_weapon]
    if selected_weapon != 0 and magazines[selected_weapon] <= 0:
        start_reload()
        return
    fire_cooldown = float(weapon.rate)
    recoil = minf(recoil + 0.018, 0.08)
    if selected_weapon != 0:
        magazines[selected_weapon] -= 1
    _publish_stats()
    if selected_weapon == 4:
        _explode(camera.global_position + (-camera.global_transform.basis.z * 9.0), int(weapon.damage))
        return
    var pellets := 7 if selected_weapon == 2 else 1
    for i in range(pellets):
        var direction := -camera.global_transform.basis.z
        if selected_weapon == 2:
            direction = (direction + camera.global_transform.basis.x * randf_range(-0.09, 0.09) + camera.global_transform.basis.y * randf_range(-0.09, 0.09)).normalized()
        elif selected_weapon == 3:
            direction = (direction + camera.global_transform.basis.x * randf_range(-0.012, 0.012) + camera.global_transform.basis.y * randf_range(-0.012, 0.012)).normalized()
        var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + direction * float(weapon.range))
        query.exclude = [self]
        var hit := get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty():
            var target: Object = hit.get("collider")
            if target != null and target.has_method("take_damage"):
                target.take_damage(int(weapon.damage))
    if selected_weapon == 0:
        _make_melee_spark()

func start_reload() -> void:
    if selected_weapon == 0 or reloading or magazines[selected_weapon] >= int(WEAPONS[selected_weapon].mag) or reserves[selected_weapon] <= 0:
        return
    reloading = true
    reload_left = 1.25 if selected_weapon != 2 else 1.8

func finish_reload() -> void:
    var capacity: int = int(WEAPONS[selected_weapon].mag)
    var amount: int = mini(capacity - magazines[selected_weapon], reserves[selected_weapon])
    magazines[selected_weapon] += amount
    reserves[selected_weapon] -= amount
    reloading = false
    _publish_stats()

func hurt(amount: int) -> void:
    if dead:
        return
    health = maxi(health - amount, 0)
    _publish_stats()
    if health <= 0:
        dead = true
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        player_died.emit()

func heal(amount: int) -> void:
    health = mini(100, health + amount)
    _publish_stats()

func grant_weapon(index: int) -> void:
    if index > 0 and index < WEAPONS.size():
        equip(index)
        reserves[index] += int(WEAPONS[index].reserve) / 2
        _publish_stats()

func _publish_stats() -> void:
    if selected_weapon >= WEAPONS.size(): return
    var label := "∞" if selected_weapon == 0 else "%d / %d" % [magazines[selected_weapon], reserves[selected_weapon]]
    if reloading: label = "ПЕРЕЗАРЯДКА…"
    stats_changed.emit(health, str(WEAPONS[selected_weapon].name), label)

func _explode(point: Vector3, damage: int) -> void:
    var game := get_tree().get_first_node_in_group("game")
    if game != null and game.has_method("create_explosion"):
        game.create_explosion(point, damage)

func _make_melee_spark() -> void:
    var game := get_tree().get_first_node_in_group("game")
    if game != null and game.has_method("melee_swing"):
        game.melee_swing(camera.global_position, -camera.global_transform.basis.z)
