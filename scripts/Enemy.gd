extends CharacterBody3D

var health := 50
var move_speed := 3.2
var touch_damage := 10
var attack_wait := 0.0
var target: CharacterBody3D
var variant := "Изменённый"
var attack_range := 1.7

func configure(kind: String, hp: int, speed: float, damage: int) -> void:
    variant = kind
    health = hp
    move_speed = speed
    touch_damage = damage

func _ready() -> void:
    add_to_group("enemy")
    target = get_tree().get_first_node_in_group("player") as CharacterBody3D

func _physics_process(delta: float) -> void:
    if not is_instance_valid(target) or target.dead:
        return
    attack_wait = maxf(0.0, attack_wait - delta)
    var offset := target.global_position - global_position
    var flat := Vector3(offset.x, 0.0, offset.z)
    var distance := flat.length()
    if distance > attack_range:
        var direction := flat.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        if direction.length_squared() > 0.0:
            look_at(global_position + direction, Vector3.UP)
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)
        if attack_wait <= 0.0:
            target.hurt(touch_damage)
            attack_wait = 1.0
    if is_on_floor(): velocity.y = -0.1
    else: velocity.y -= 19.0 * delta
    move_and_slide()

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        queue_free()
