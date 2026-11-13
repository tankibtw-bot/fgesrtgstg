extends CharacterBody3D

var health := 60.0
var speed := 3.0
var attack_damage := 12
var attack_interval := 1.2
var attack_timer := 0.0
var player: Node3D

func _ready() -> void:
    add_to_group("enemy")
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
    if player == null:
        return

    if not is_on_floor():
        velocity.y -= 20.0 * delta
    else:
        velocity.y = 0.0

    if player.dead:
        velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
        move_and_slide()
        return

    var to_player = player.global_position - global_position
    var distance = to_player.length()
    if distance > 0.1:
        to_player = to_player.normalized()

    if distance < 1.8:
        attack_timer -= delta
        if attack_timer <= 0.0:
            player.hurt(attack_damage)
            attack_timer = attack_interval
        velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta)
    else:
        var chase_dir = Vector3(to_player.x, 0.0, to_player.z).normalized()
        velocity.x = chase_dir.x * speed
        velocity.z = chase_dir.z * speed
        look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

    move_and_slide()

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0.0:
        queue_free()

