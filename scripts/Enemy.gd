extends CharacterBody3D

var health := 50
var move_speed := 3.2
var touch_damage := 10
var attack_wait := 0.0
var target: CharacterBody3D
var variant := "Изменённый"
var attack_range := 1.7
var preferred_range := 0.0
var strafe_sign := 1.0
var strafe_timer := 0.0
var hurt_flash := 0.0
var visual: MeshInstance3D

func configure(kind: String, hp: int, speed: float, damage: int) -> void:
    variant = kind
    health = hp
    move_speed = speed
    touch_damage = damage
    if kind == "Цербер":
        preferred_range = 10.0
        attack_range = 18.0
    elif kind == "дрон":
        preferred_range = 8.0
        attack_range = 15.0
    elif kind == "элитный":
        preferred_range = 2.3
        attack_range = 2.3

func _ready() -> void:
    add_to_group("enemy")
    target = get_tree().get_first_node_in_group("player") as CharacterBody3D
    visual = get_node_or_null("MeshInstance3D") as MeshInstance3D
    strafe_timer = randf_range(0.4, 1.6)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target) or target.dead:
        return
    attack_wait = maxf(0.0, attack_wait - delta)
    strafe_timer -= delta
    hurt_flash = maxf(0.0, hurt_flash - delta)
    var offset := target.global_position - global_position
    var flat := Vector3(offset.x, 0.0, offset.z)
    var distance := flat.length()
    var can_see := _has_line_of_sight()
    if strafe_timer <= 0.0:
        strafe_sign *= -1.0 if randf() < 0.65 else 1.0
        strafe_timer = randf_range(0.65, 1.5)

    if preferred_range > 0.0:
        _update_ranged_enemy(flat, distance, can_see, delta)
    elif distance > attack_range:
        var direction := flat.normalized()
        var side := Vector3(-direction.z, 0.0, direction.x) * strafe_sign * 0.22
        _set_horizontal_velocity((direction + side).normalized() * move_speed, delta)
        if direction.length_squared() > 0.0:
            look_at(global_position + direction, Vector3.UP)
    else:
        _set_horizontal_velocity(Vector3.ZERO, delta)
        _face_target()
        if attack_wait <= 0.0:
            target.hurt(touch_damage)
            attack_wait = 1.0 if variant != "элитный" else 0.72

    if is_on_floor(): velocity.y = -0.1
    else: velocity.y -= 19.0 * delta
    move_and_slide()
    _update_flash()

func _update_ranged_enemy(flat: Vector3, distance: float, can_see: bool, delta: float) -> void:
    var toward := flat.normalized() if distance > 0.01 else Vector3.ZERO
    var move := Vector3.ZERO
    if not can_see or distance > preferred_range * 1.35:
        move = toward
    elif distance < preferred_range * 0.58:
        move = -toward
    elif variant == "Цербер":
        move = Vector3(-toward.z, 0.0, toward.x) * strafe_sign * 0.48
    _set_horizontal_velocity(move * move_speed, delta)
    _face_target()
    if can_see and distance <= attack_range and attack_wait <= 0.0:
        _fire_at_player(distance)
        attack_wait = 1.05 if variant == "Цербер" else 1.4

func _set_horizontal_velocity(desired: Vector3, delta: float) -> void:
    var acceleration := 12.0 if is_on_floor() else 4.0
    velocity.x = move_toward(velocity.x, desired.x, acceleration * delta)
    velocity.z = move_toward(velocity.z, desired.z, acceleration * delta)

func _face_target() -> void:
    var look_point := Vector3(target.global_position.x, global_position.y, target.global_position.z)
    if global_position.distance_squared_to(look_point) > 0.01:
        look_at(look_point, Vector3.UP)

func _has_line_of_sight() -> bool:
    var from := global_position + Vector3.UP * 1.25
    var to := target.global_position + Vector3.UP * 0.5
    var query := PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    return result.is_empty() or result.get("collider") == target

func _fire_at_player(distance: float) -> void:
    var origin := global_position + Vector3.UP * 1.25
    var target_point := target.global_position + Vector3.UP * 0.55
    var aim_error := 0.055 if variant == "Цербер" else 0.12
    var direction := (target_point - origin).normalized()
    direction = (direction + Vector3(randf_range(-aim_error, aim_error), randf_range(-aim_error, aim_error), randf_range(-aim_error, aim_error))).normalized()
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * minf(distance + 1.0, attack_range))
    query.exclude = [self]
    var result := get_world_3d().direct_space_state.intersect_ray(query)
    if not result.is_empty() and result.get("collider") == target:
        target.hurt(touch_damage)
    _spawn_tracer(origin, origin + direction * minf(distance, attack_range), variant == "дрон")

func _spawn_tracer(from: Vector3, to: Vector3, energy_shot: bool) -> void:
    var beam := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.018 if not energy_shot else 0.055
    cylinder.bottom_radius = cylinder.top_radius
    cylinder.height = from.distance_to(to)
    beam.mesh = cylinder
    beam.position = (from + to) * 0.5
    beam.look_at(to, Vector3.UP)
    beam.rotate_object_local(Vector3.RIGHT, PI / 2.0)
    var material := StandardMaterial3D.new()
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = Color("ffb24d") if not energy_shot else Color("42d9ff")
    material.emission_enabled = true
    material.emission = material.albedo_color
    beam.material_override = material
    get_tree().current_scene.add_child(beam)
    get_tree().create_timer(0.09).timeout.connect(beam.queue_free)

func _update_flash() -> void:
    if not is_instance_valid(visual): return
    var material := visual.material_override as StandardMaterial3D
    if material == null: return
    material.emission_enabled = hurt_flash > 0.0
    if hurt_flash > 0.0:
        material.emission = Color(1.0, 0.12, 0.08)

func take_damage(amount: int) -> void:
    health -= amount
    hurt_flash = 0.12
    if health <= 0:
        queue_free()
