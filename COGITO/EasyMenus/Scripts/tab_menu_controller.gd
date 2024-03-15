extends Control
signal resume
signal back_to_main_pressed

@onready var content : VBoxContainer = $%Content
@onready var tab_container: TabContainer = $Content/TabContainer
@onready var resume_game_button: Button = %ResumeGameButton
@onready var tab_menu_options: Control = $TabMenuOptions
@onready var save_button: CogitoUiButton = %SaveButton
@onready var load_button: CogitoUiButton = %LoadButton

@export var nodes_to_focus: Array[Control]

#region UI AUDIO
@export var sound_hover : AudioStream
@export var sound_click : AudioStream
var playback : AudioStreamPlaybackPolyphonic
var temp_screenshot : Image


func _enter_tree() -> void:
	# Create an audio player
	var player = AudioStreamPlayer.new()
	add_child(player)

	# Create a polyphonic stream so we can play sounds directly from it
	var stream = AudioStreamPolyphonic.new()
	stream.polyphony = 32
	player.stream = stream
	player.play()
	# Get the polyphonic playback stream to play sounds
	playback = player.get_stream_playback()

	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node:Node) -> void:
	if node is Button:
		# If the added node is a button we connect to its mouse_entered and pressed signals
		# and play a sound
		node.mouse_entered.connect(_play_hover)
		node.focus_entered.connect(_play_hover)
		node.pressed.connect(_play_pressed)


func _play_hover() -> void:
	playback.play_stream(sound_hover, 0, 0, 1)


func _play_pressed() -> void:
	playback.play_stream(sound_click, 0, 0, 1)
#endregion


func open_pause_menu():
	#Stops game and shows pause menu
	get_tree().paused = true
	save_button.text = "Save Slot " + CogitoSceneManager._active_slot
	load_button.text = "Load Slot " + CogitoSceneManager._active_slot
	temp_screenshot = grab_temp_screenshot()
	tab_container.set_current_tab(0)
	show()
	load_current_slot_data()
	resume_game_button.grab_focus.call_deferred()


func grab_temp_screenshot() -> Image:
	return get_viewport().get_texture().get_image()


func load_current_slot_data():
	# Load screenshot
	var image_path : String = CogitoSceneManager.get_active_slot_player_state_screenshot_path()
	if image_path != "":
		var image : Image = Image.load_from_file(image_path)
		var texture = ImageTexture.create_from_image(image)
		%Screenshot_Spot.texture = texture
	else:
		print("No screenshot for slot ", CogitoSceneManager._active_slot, " found.")
		
	# Load save state time
	var savetime : int
	if CogitoSceneManager._player_state:
		savetime = CogitoSceneManager._player_state.player_state_savetime
	if savetime == null or typeof(savetime) != TYPE_INT:
		%Label_SaveTime.text = ""
	else:
		var timeoffset = Time.get_time_zone_from_system().bias*60
		%Label_SaveTime.text = Time.get_datetime_string_from_unix_time(savetime+timeoffset,true)


func close_pause_menu():
	get_tree().paused = false
	hide()
	emit_signal("resume")

func _on_resume_game_button_pressed():
	close_pause_menu()


func _on_quit_button_pressed():
	get_tree().quit()


func _on_back_to_menu_button_pressed():
	close_pause_menu()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	emit_signal("back_to_main_pressed")


func _input(event):
	if (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")) and visible:
		accept_event()
		close_pause_menu()
	
	#Tab navigation
	if (event.is_action_pressed("ui_next_tab")):
		if tab_container.current_tab + 1 == tab_container.get_tab_count():
			tab_container.current_tab = 0
		else:
			tab_container.current_tab += 1
			
		if nodes_to_focus[tab_container.current_tab]:
			#print("Grabbing focus of : ", tab_container.current_tab, " - ", nodes_to_focus[tab_container.current_tab])
			nodes_to_focus[tab_container.current_tab].grab_focus.call_deferred()
		
	if (event.is_action_pressed("ui_prev_tab")):
		if tab_container.current_tab  == 0:
			tab_container.current_tab = tab_container.get_tab_count()-1
		else:
			tab_container.current_tab -= 1
			
		if nodes_to_focus[tab_container.current_tab]:
			#print("Grabbing focus of : ", tab_container.current_tab, " - ", nodes_to_focus[tab_container.current_tab])
			nodes_to_focus[tab_container.current_tab].grab_focus.call_deferred()


func _on_save_button_pressed() -> void:
	CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
	CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
	CogitoSceneManager._screenshot_to_save = temp_screenshot
	CogitoSceneManager.save_player_state(CogitoSceneManager._current_player_node,CogitoSceneManager._active_slot)
	CogitoSceneManager.save_scene_state(CogitoSceneManager._current_scene_name,CogitoSceneManager._active_slot)
	
	_on_resume_game_button_pressed()
	

func _on_load_button_pressed() -> void:
	print("LOAD BUTTON PRESSED")
	CogitoSceneManager._current_scene_name = get_tree().get_current_scene().get_name()
	CogitoSceneManager._current_scene_path = get_tree().current_scene.scene_file_path
	CogitoSceneManager.loading_saved_game(CogitoSceneManager._active_slot)
	
	_on_resume_game_button_pressed()
	
