extends Control

const GAME_SCENE := "res://scenes/Main.tscn"
const CHAPTER_TITLES := ["Смена", "Тест", "Эвакуация", "Технические тоннели", "Свидетель", "Цербер", "Архив", "Контакт", "Протокол", "Центр", "Выбор", "Тишина"]

var status_label: Label
var chapter_grid: GridContainer
var start_button: Button
var chapter_buttons: Array[Button] = []
var showing_controls := false

func _ready() -> void:
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _build_menu()
    _refresh_chapters()

func _build_menu() -> void:
    var background := ColorRect.new()
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color("071018")
    add_child(background)

    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.015, 0.025, 0.04, 0.45)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(center)

    var column := VBoxContainer.new()
    column.custom_minimum_size = Vector2(560, 0)
    column.add_theme_constant_override("separation", 9)
    center.add_child(column)

    var eyebrow := Label.new()
    eyebrow.text = "NOVA DEEP FACILITY  •  INCIDENT 09"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 15)
    eyebrow.modulate = Color("50c6d3")
    column.add_child(eyebrow)

    var title := Label.new()
    title.text = "A B Y S S"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 64)
    title.add_theme_color_override("font_color", Color("e8edf0"))
    column.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "НИЖЕ НАС — ТОЛЬКО ТЬМА И СИГНАЛЫ"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 14)
    subtitle.modulate = Color("a0b0b8")
    column.add_child(subtitle)

    var spacer := Control.new()
    spacer.custom_minimum_size.y = 5
    column.add_child(spacer)
    start_button = _add_button(column, "ПРОДОЛЖИТЬ", _continue_campaign)
    _add_button(column, "НОВАЯ КАМПАНИЯ", _new_campaign)
    _add_button(column, "УПРАВЛЕНИЕ", _show_controls)

    var chapter_title := Label.new()
    chapter_title.text = "ВЫБОР ГЛАВЫ  •  ПРОЙДЕННЫЕ ГЛАВЫ ОТКРЫТЫ"
    chapter_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter_title.add_theme_font_size_override("font_size", 13)
    chapter_title.modulate = Color("8ea1aa")
    column.add_child(chapter_title)

    chapter_grid = GridContainer.new()
    chapter_grid.columns = 4
    chapter_grid.add_theme_constant_override("h_separation", 7)
    chapter_grid.add_theme_constant_override("v_separation", 6)
    column.add_child(chapter_grid)
    for i in range(CHAPTER_TITLES.size()):
        var index := i
        var button := Button.new()
        button.custom_minimum_size = Vector2(132, 32)
        button.add_theme_font_size_override("font_size", 12)
        button.pressed.connect(func(): _choose_chapter(index))
        chapter_grid.add_child(button)
        chapter_buttons.append(button)

    status_label = Label.new()
    status_label.text = "12 глав • 3 финала • одиночная кампания"
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 13)
    status_label.modulate = Color("82939c")
    column.add_child(status_label)
    _add_button(column, "ВЫХОД", _quit_game)

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(0, 38)
    button.focus_mode = Control.FOCUS_ALL
    button.add_theme_font_size_override("font_size", 16)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("172630")
    normal.border_color = Color("31505b")
    normal.set_border_width_all(1)
    var hover := StyleBoxFlat.new()
    hover.bg_color = Color("21414c")
    hover.border_color = Color("50c6d3")
    hover.set_border_width_all(1)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", hover)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _refresh_chapters() -> void:
    if not is_instance_valid(chapter_grid): return
    for i in range(chapter_buttons.size()):
        var unlocked := i <= CampaignState.unlocked_chapter
        chapter_buttons[i].text = "%02d  %s" % [i + 1, CHAPTER_TITLES[i]] if unlocked else "%02d  ЗАКРЫТА" % (i + 1)
        chapter_buttons[i].disabled = not unlocked
    start_button.text = "ПРОДОЛЖИТЬ — ГЛАВА %02d" % (CampaignState.current_chapter + 1) if CampaignState.campaign_started else "ПРОДОЛЖИТЬ"

func _choose_chapter(index: int) -> void:
    CampaignState.select_chapter(index)
    status_label.text = "Выбрана глава %02d — %s. Нажмите «Продолжить»." % [index + 1, CHAPTER_TITLES[index]]
    start_button.text = "НАЧАТЬ С ГЛАВЫ %02d" % (index + 1)

func _continue_campaign() -> void:
    if CampaignState.selected_chapter == CampaignState.current_chapter:
        pass
    CampaignState.begin_selected_chapter()
    get_tree().change_scene_to_file(GAME_SCENE)

func _new_campaign() -> void:
    CampaignState.start_new_campaign()
    get_tree().change_scene_to_file(GAME_SCENE)

func _show_controls() -> void:
    showing_controls = not showing_controls
    status_label.text = "WASD движение • Shift бег • Space прыжок • Мышь обзор\nЛКМ атака • R перезарядка • 1–6 оружие • E действие • Esc пауза" if showing_controls else "12 глав • 3 финала • прогресс сохраняется автоматически"

func _quit_game() -> void:
    get_tree().quit()
