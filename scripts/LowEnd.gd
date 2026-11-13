extends Node

# Conservative defaults for older integrated GPUs (e.g. Intel HD 4000).
# The project uses the Compatibility renderer and a low internal resolution;
# this script removes expensive scene effects even if a level enables them.

const TARGET_FPS := 60

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    Engine.max_fps = TARGET_FPS
    Engine.physics_ticks_per_second = 60
    if not InputMap.has_action("ui_accept"):
        InputMap.add_action("ui_accept")
    var interact_key := InputEventKey.new()
    interact_key.keycode = KEY_E
    InputMap.action_add_event("ui_accept", interact_key)
    get_tree().scene_changed.connect(_on_scene_changed)
    call_deferred("_optimize_current_scene")

func _on_scene_changed(_scene: Node) -> void:
    call_deferred("_optimize_current_scene")

func _optimize_current_scene() -> void:
    var scene := get_tree().current_scene
    if scene == null:
        return
    _visit(scene)

func _visit(node: Node) -> void:
    if node is WorldEnvironment and node.environment != null:
        var environment: Environment = node.environment
        environment.fog_enabled = false
        environment.volumetric_fog_enabled = false
        environment.glow_enabled = false
        environment.adjustment_enabled = false
    elif node is DirectionalLight3D:
        node.shadow_enabled = false
    elif node is OmniLight3D or node is SpotLight3D:
        node.shadow_enabled = false
    elif node is Camera3D:
        node.attributes = null
        node.doppler_tracking = Camera3D.DOPPLER_TRACKING_DISABLED
    for child in node.get_children():
        _visit(child)
