extends Node

const SAVE_PATH := "user://abyss_save.cfg"
const CHAPTER_COUNT := 12

var unlocked_chapter := 0
var current_chapter := 0
var selected_chapter := 0
var last_ending := ""
var campaign_started := false

func _ready() -> void:
    load_progress()

func load_progress() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        _reset_values()
        return
    unlocked_chapter = clampi(int(config.get_value("campaign", "unlocked_chapter", 0)), 0, CHAPTER_COUNT - 1)
    current_chapter = clampi(int(config.get_value("campaign", "current_chapter", 0)), 0, CHAPTER_COUNT - 1)
    selected_chapter = current_chapter
    last_ending = str(config.get_value("campaign", "last_ending", ""))
    campaign_started = bool(config.get_value("campaign", "started", false))

func start_new_campaign() -> void:
    unlocked_chapter = 0
    current_chapter = 0
    selected_chapter = 0
    last_ending = ""
    campaign_started = true
    _write_save()

func select_chapter(index: int) -> void:
    selected_chapter = clampi(index, 0, unlocked_chapter)

func begin_selected_chapter() -> void:
    current_chapter = selected_chapter
    campaign_started = true
    _write_save()

func mark_chapter_complete(index: int) -> void:
    var next_chapter := mini(index + 1, CHAPTER_COUNT - 1)
    unlocked_chapter = maxi(unlocked_chapter, next_chapter)
    current_chapter = next_chapter
    selected_chapter = current_chapter
    _write_save()

func set_ending(ending: String) -> void:
    last_ending = ending
    current_chapter = CHAPTER_COUNT - 1
    unlocked_chapter = CHAPTER_COUNT - 1
    _write_save()

func _reset_values() -> void:
    unlocked_chapter = 0
    current_chapter = 0
    selected_chapter = 0
    last_ending = ""
    campaign_started = false

func _write_save() -> void:
    var config := ConfigFile.new()
    config.set_value("campaign", "unlocked_chapter", unlocked_chapter)
    config.set_value("campaign", "current_chapter", current_chapter)
    config.set_value("campaign", "last_ending", last_ending)
    config.set_value("campaign", "started", campaign_started)
    config.save(SAVE_PATH)
