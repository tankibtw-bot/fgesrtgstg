extends Node

const GAME_SCENE := "res://scenes/Main.tscn"
const MENU_SCENE := "res://scenes/Menu.tscn"

var layer: CanvasLayer
var panel: ColorRect
var is_open := false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _create_overlay()

func _input(event: InputEvent) -> void:
    if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
        return
    var scene := get_tree().current_scene
    if scene == null or scene.scene_file_path != GAME_SCENE:
        return
    if is_open: resume_game()
    else: open_pause()
    get_viewport().set_input_as_handled()

func _create_overlay() -> void:
    layer = CanvasLayer.new()
    layer.name = "PauseOverlay"
    layer.layer = 100
    layer.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(layer)
    panel = ColorRect.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.color = Color(0.015, 0.025, 0.035, 0.9)
    panel.visible = false
    panel.process_mode = Node.PROCESS_MODE_ALWAYS
    layer.add_child(panel)
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_child(center)
    var column := VBoxContainer.new()
    column.custom_minimum_size = Vector2(420, 0)
    column.add_theme_constant_override("separation", 12)
    center.add_child(column)
    var title := Label.new()
    title.text = "ПАУЗА"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    column.add_child(title)
    _add_button(column, "ПРОДОЛЖИТЬ", resume_game)
    _add_button(column, "ПЕРЕЗАПУСТИТЬ ГЛАВУ", restart_chapter)
    _add_button(column, "ГЛАВНОЕ МЕНЮ", return_to_menu)
    _add_button(column, "ВЫХОД", quit_game)
    var hint := Label.new()
    hint.text = "Esc — вернуться в игру"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.modulate = Color("9baab0")
    column.add_child(hint)

func _add_button(parent: VBoxContainer, text: String, action: Callable) -> void:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(0, 46)
    button.process_mode = Node.PROCESS_MODE_ALWAYS
    button.add_theme_font_size_override("font_size", 17)
    button.pressed.connect(action)
    parent.add_child(button)

func open_pause() -> void:
    if is_open: return
    is_open = true
    panel.visible = true
    get_tree().paused = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume_game() -> void:
    if not is_open: return
    is_open = false
    panel.visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func restart_chapter() -> void:
    var game := get_tree().current_scene
    is_open = false
    panel.visible = false
    get_tree().paused = false
    if game != null and game.has_method("restart_current_chapter"):
        game.restart_current_chapter()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func return_to_menu() -> void:
    is_open = false
    panel.visible = false
    get_tree().paused = false
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    get_tree().change_scene_to_file(MENU_SCENE)

func quit_game() -> void:
    get_tree().quit()
