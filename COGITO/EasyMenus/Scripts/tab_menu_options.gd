extends Control
signal options_updated

const HSliderWLabel = preload("res://COGITO/EasyMenus/Scripts/slider_w_labels.gd")

@onready var sfx_volume_slider : HSliderWLabel = $%SFXVolumeSlider
@onready var music_volume_slider: HSliderWLabel = $%MusicVolumeSlider
@onready var render_scale_current_value_label: Label = %RenderScaleCurrentValueLabel
@onready var render_scale_slider: HSlider = %RenderScaleSlider
@onready var vsync_check_button: CheckButton = %VSyncCheckButton
@onready var invert_y_check_button: CheckButton = %InvertYAxisCheckButton
@onready var anti_aliasing_2d_option_button: OptionButton = $%AntiAliasing2DOptionButton
@onready var anti_aliasing_3d_option_button: OptionButton = $%AntiAliasing3DOptionButton
@onready var window_mode_option_button: OptionButton = %WindowModeOptionButton

var sfx_bus_index
var music_bus_index
var config = ConfigFile.new()

# Array to set window modes.
const WINDOW_MODE_ARRAY : Array[String] = [
	"Full screen",
	"Exclusive full screen",
	"Windowed",
	"Borderless windowed",	
]


func _ready() -> void:
	add_window_mode_items()
	window_mode_option_button.item_selected.connect(on_window_mode_selected)

# Called from outside initializes the options menu
func on_open():
	sfx_bus_index = AudioServer.get_bus_index(OptionsConstants.sfx_bus_name)
	music_bus_index = AudioServer.get_bus_index(OptionsConstants.music_bus_name)
	
	load_options()


# Adding window modes to the window mode button.
func add_window_mode_items() -> void:
	for mode in WINDOW_MODE_ARRAY:
		window_mode_option_button.add_item(mode)


# Function to change window modes. Hooked up to the window_mode_option_button
func on_window_mode_selected(index: int) -> void:
	match index:
		0: #Full screen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		1: #Exclusive full screen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		2: #Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		3: #Borderless windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)


func _on_sfx_volume_slider_value_changed(value):
	set_volume(sfx_bus_index, value)
	_on_apply_changes_pressed()


func _on_music_volume_slider_value_changed(value):
	set_volume(music_bus_index, value)
	_on_apply_changes_pressed()


# Sets the volume for the given audio bus
func set_volume(bus_index, value):
	print("Setting volume on bus_index ", bus_index, " to ", value)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


# Saves the options when the options menu is closed
func save_options():
	config.set_value(OptionsConstants.section_name, OptionsConstants.sfx_volume_key_name, sfx_volume_slider.hslider.value)
	config.set_value(OptionsConstants.section_name, OptionsConstants.music_volume_key_name, music_volume_slider.hslider.value)
	config.set_value(OptionsConstants.section_name, OptionsConstants.windowmode_key_name, window_mode_option_button.selected)
	config.set_value(OptionsConstants.section_name, OptionsConstants.render_scale_key, render_scale_slider.value);
	config.set_value(OptionsConstants.section_name, OptionsConstants.vsync_key, vsync_check_button.button_pressed)
	config.set_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, invert_y_check_button.button_pressed)
	config.set_value(OptionsConstants.section_name, OptionsConstants.msaa_2d_key, anti_aliasing_2d_option_button.get_selected_id())
	config.set_value(OptionsConstants.section_name, OptionsConstants.msaa_3d_key, anti_aliasing_3d_option_button.get_selected_id())
	
	config.save(OptionsConstants.config_file_name)

# Loads options and sets the controls values to loaded values. Uses default values if config file does not exist
func load_options():
	var err = config.load(OptionsConstants.config_file_name)
	
	var sfx_volume = config.get_value(OptionsConstants.section_name, OptionsConstants.sfx_volume_key_name, 1)
	var music_volume = config.get_value(OptionsConstants.section_name, OptionsConstants.music_volume_key_name, 1)
	var window_mode = config.get_value(OptionsConstants.section_name, OptionsConstants.windowmode_key_name, 0)
	var render_scale = config.get_value(OptionsConstants.section_name, OptionsConstants.render_scale_key, 1)
	var vsync = config.get_value(OptionsConstants.section_name, OptionsConstants.vsync_key, true)
	var invert_y = config.get_value(OptionsConstants.section_name, OptionsConstants.invert_vertical_axis_key, true)
	var msaa_2d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_2d_key, 0)
	var msaa_3d = config.get_value(OptionsConstants.section_name, OptionsConstants.msaa_3d_key, 0)

	sfx_volume_slider.hslider.value = sfx_volume
	music_volume_slider.hslider.value = music_volume
	window_mode_option_button._select_int(window_mode)
	render_scale_slider.value = render_scale
	
	# Need to set it like that to guarantee signal to be triggered
	vsync_check_button.set_pressed_no_signal(vsync)
	vsync_check_button.emit_signal("toggled", vsync)
	
	invert_y_check_button.set_pressed_no_signal(invert_y)
	invert_y_check_button.emit_signal("toggled", invert_y)
	
	anti_aliasing_2d_option_button.selected = msaa_2d
	anti_aliasing_2d_option_button.emit_signal("item_selected", msaa_2d)
	anti_aliasing_3d_option_button.selected = msaa_3d
	anti_aliasing_3d_option_button.emit_signal("item_selected", msaa_3d)


func _on_render_scale_slider_value_changed(value):
	get_viewport().scaling_3d_scale = value
	render_scale_current_value_label.text = str(value)


func _on_v_sync_check_button_toggled(button_pressed):
	# There are multiple V-Sync Methods supported by Godot 
	# For now we just use the simple ones could be worth a consideration to add the others
	# Just sets V-Sync for the first window. So no support for multi window games
	if button_pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_anti_aliasing_2d_option_button_item_selected(index):
	set_msaa("msaa_2d", index)


func _on_anti_aliasing_3d_option_button_item_selected(index):
	set_msaa("msaa_3d", index)


func set_msaa(mode, index):
	match index:
		0:
			get_viewport().set(mode,Viewport.MSAA_DISABLED)
		1:
			get_viewport().set(mode,Viewport.MSAA_2X)
		2:
			get_viewport().set(mode,Viewport.MSAA_4X)
		3:
			get_viewport().set(mode,Viewport.MSAA_8X)


func _on_apply_changes_pressed() -> void:
	save_options()
	print("Options saved.")
	emit_signal("options_updated")
