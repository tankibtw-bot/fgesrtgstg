extends CharacterBody3D

const MOVE_SPEED := 6.5
const SPRINT_SPEED := 9.5
const ACCELERATION := 10.0
const AIR_ACCELERATION := 3.0
const FRICTION := 12.0
const GRAVITY := 18.0
const JUMP_FORCE := 6.2
const MAX_HEALTH := 100
const MAX_AMMO := 30

var health := MAX_HEALTH
var ammo := MAX_AMMO
var reserve_ammo := 90
var fire_rate := 0.12
var fire_timer := 0.0
var dead := false
var pitch := 0.0
var yaw := 0.0

signal health_changed(value)
signal ammo_changed(current, reserve)

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

func _ready() -> void:
    add_to_group("player")
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    emit_signal("health_changed", health)
    emit_signal("ammo_changed", ammo, reserve_ammo)

func _unhandled_input(event: InputEvent) -> void:
    if dead:
        return

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * 0.0025
        pitch -= event.relative.y * 0.0020
        pitch = clamp(pitch, -1.35, 1.35)
        rotation.y = yaw
        head.rotation.x = pitch

    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        fire()

    if event is InputEventKey and event.pressed and event.keycode == KEY_R:
        reload()

func _process(delta: float) -> void:
    if dead:
        return

    fire_timer = max(0.0, fire_timer - delta)

    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_timer <= 0.0:
        fire()

func _physics_process(delta: float) -> void:
    if dead:
        return

    var input_dir := Vector2.ZERO

    if Input.is_key_pressed(KEY_W):
        input_dir.y -= 1
    if Input.is_key_pressed(KEY_S):
        input_dir.y += 1
    if Input.is_key_pressed(KEY_A):
        input_dir.x -= 1
    if Input.is_key_pressed(KEY_D):
        input_dir.x += 1

    if input_dir.length() > 0.0:
        input_dir = input_dir.normalized()

    var forward := -global_transform.basis.z
    var right := global_transform.basis.x
    var wish_dir := (forward * input_dir.y + right * input_dir.x)

    if want_jump() and is_on_floor():
        velocity.y = JUMP_FORCE

    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    else:
        velocity.y = min(velocity.y, 0.0)

    if wish_dir.length() > 0.0:
        wish_dir = wish_dir.normalized()
        var target_speed = SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else MOVE_SPEED
        var target_velocity = wish_dir * target_speed
        var accel = is_on_floor() ? ACCELERATION : AIR_ACCELERATION
        velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
        velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)
    else:
        var friction_value = is_on_floor() ? FRICTION : 0.6
        velocity.x = move_toward(velocity.x, 0.0, friction_value * delta)
        velocity.z = move_toward(velocity.z, 0.0, friction_value * delta)

    move_and_slide()

func want_jump() -> bool:
    return Input.is_key_pressed(KEY_SPACE)

func fire() -> void:
    if dead or fire_timer > 0.0 or ammo <= 0:
        return

    ammo -= 1
    fire_timer = fire_rate
    emit_signal("ammo_changed", ammo, reserve_ammo)

    var from: Vector3 = camera.global_position
    var dir: Vector3 = -camera.global_transform.basis.z.normalized()
    var to: Vector3 = from + dir * 100.0

    var query = PhysicsRayQueryParameters3D.new()
    query.from = from
    query.to = to
    query.exclude = [self]
    query.collide_with_areas = false
    query.collide_with_bodies = true

    var result = get_world_3d().direct_space_state.intersect_ray(query)
    if result:
        var actor = result.get("collider")
        if actor and actor.has_method("take_damage"):
            actor.take_damage(25)

func reload() -> void:
    if dead or ammo == MAX_AMMO or reserve_ammo <= 0:
        return

    var needed = MAX_AMMO - ammo
    var loaded = min(needed, reserve_ammo)
    ammo += loaded
    reserve_ammo -= loaded
    emit_signal("ammo_changed", ammo, reserve_ammo)

func hurt(amount: int) -> void:
    if dead:
        return

    health -= amount
    health = max(0, health)
    emit_signal("health_changed", health)

    if health <= 0:
        dead = true
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

