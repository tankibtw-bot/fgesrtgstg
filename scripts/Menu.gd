extends Control

const GAME_SCENE := "res://scenes/Main.tscn"

var status_label: Label
var buttons: Array[Button] = []

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _build_menu()

func _build_menu() -> void:
    var background := ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("071018")
    add_child(background)

    var grid := GridContainer.new()
    grid.columns = 2
    grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
    for i in range(18):
        var stripe := ColorRect.new()
        stripe.color = Color("101f2a") if i % 3 == 0 else Color("0b1720")
        stripe.custom_minimum_size = Vector2(1, 1)
        grid.add_child(stripe)
    background.add_child(grid)

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.015, 0.025, 0.04, 0.72)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var column := VBoxContainer.new()
    column.custom_minimum_size = Vector2(520, 0)
    column.add_theme_constant_override("separation", 14)
    center.add_child(column)

    var eyebrow := Label.new()
    eyebrow.text = "NOVA DEEP FACILITY  •  INCIDENT 09"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 16)
    eyebrow.modulate = Color("50c6d3")
    column.add_child(eyebrow)

    var title := Label.new()
    title.text = "A B Y S S"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 72)
    title.add_theme_color_override("font_color", Color("e8edf0"))
    column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "НИЖЕ НАС — ТОЛЬКО ТЬМА И СИГНАЛЫ"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 16)
    subtitle.modulate = Color("a0b0b8")
    column.add_child(subtitle)

    var spacer := Control.new()
    spacer.custom_minimum_size.y = 18
    column.add_child(spacer)

    _add_button(column, "НАЧАТЬ КАМПАНИЮ", _start_game)
    _add_button(column, "УПРАВЛЕНИЕ", _show_controls)
    _add_button(column, "ВЫХОД", _quit_game)

    status_label = Label.new()
    status_label.text = "12 глав • 3 финала • одиночная кампания"
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 14)
    status_label.modulate = Color("82939c")
    column.add_child(status_label)

    var footer := Label.new()
    footer.text = "WASD — движение   •   ЛКМ — атака   •   E — взаимодействие"
    footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
    footer.offset_top = -34
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    footer.add_theme_font_size_override("font_size", 14)
    footer.modulate = Color("71828b")
    add_child(footer)

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(0, 48)
    button.focus_mode = Control.FOCUS_ALL
    button.add_theme_font_size_override("font_size", 18)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("172630")
    normal.border_color = Color("31505b")
    normal.set_border_width_all(1)
    normal.content_margin_left = 18
    normal.content_margin_right = 18
    var hover := StyleBoxFlat.new()
    hover.bg_color = Color("21414c")
    hover.border_color = Color("50c6d3")
    hover.set_border_width_all(1)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    button.pressed.connect(callback)
    parent.add_child(button)
    buttons.append(button)

func _start_game() -> void:
    get_tree().change_scene_to_file(GAME_SCENE)

func _show_controls() -> void:
    status_label.text = "WASD: движение • Shift: бег • Space: прыжок • Мышь: обзор\nЛКМ: атака • R: перезарядка • 1–6: оружие • E: действие • Esc: пауза"

func _quit_game() -> void:
    get_tree().quit()
