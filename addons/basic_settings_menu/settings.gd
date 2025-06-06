#TODO: ADD ICONS SAYING ESC FOR BACK, ENTER FOR SELECT
#TODO: ADD pause_on_alt_tab
#TODO: VolumeSliders makes sound when changed indicating the sound change
class_name SettingsUI extends Control
#FIXME: resoultion items not being applied properly, check if lazy mode works
#const BUS_MASTER = "Master"
#const BUS_MUSIC = "Music"
#const BUS_SFX = "SFX"

var awaiting_input : bool = false
var is_pop_up : bool = false



func _ready() -> void: 
	pass
	#gameplay_ready()
	#audio_ready()

#region Accessibility




#endregion

#region Gameplay

#func gameplay_ready() -> void:
	#%MaxFPSSpinBox.value = SettingsData.loaded_data.settings["gameplay_options"]["max_fps"]
	#Engine.set_max_fps(%MaxFPSSpinBox.value)
	#%HideTouchControlsButton.button_pressed = SettingsData.loaded_data.settings["gameplay_options"]["hide_touch_buttons"]
	##FIXME: The button wont work if the setting is not present in the dictionary, make it so the dictionary values if not present are added to the save file or not considered until saved...

#endregion

#region Video



#endregion

#region Audio

#func audio_ready() -> void:
	#%MainVolumeSlider.value = SettingsData.loaded_data.audio["Master"]
	#%MusicSlider.value = SettingsData.loaded_data.audio["Music"]
	#%SFXSlider.value = SettingsData.loaded_data.audio["SFX"]

#
#func on_audio_value_changed(bus: String ,value: float) -> void:
	#var _audio_bus := AudioServer.get_bus_index(bus)
	#AudioServer.set_bus_volume_db(_audio_bus, linear_to_db(value))
	#SettingsData.loaded_data.audio[bus] = value

#
#func _on_main_volume_slider_drag_ended(_value_changed: bool) -> void:
	#on_audio_value_changed(BUS_MASTER, %MainVolumeSlider.value)
	##%MasterBeepPlayer.play()
#
#func _on_music_slider_drag_ended(_value_changed: bool) -> void:
	#on_audio_value_changed(BUS_MUSIC, %MusicSlider.value)
	##%MusicBeepPlayer.play()
#
#func _on_sfx_slider_drag_ended(_value_changed: bool) -> void:
	#on_audio_value_changed(BUS_SFX, %SFXSlider.value)
	##%SFXBeepPlayer.play()

#endregion

#region signalled functions
#
#func _on_max_fps_spin_box_value_changed(value: int) -> void:
	#Engine.max_fps = value
	#SettingsData.loaded_data.settings["video"]["max_fps"] = value

#func _on_resolution_button_item_selected(index: int) -> void:
	#DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
	#var ws : Vector2 = RESOLUTIONS_ARRAY[index]
	#DisplayServer.window_set_size(ws)
	#var ss : Vector2 = DisplayServer.screen_get_size()
	#DisplayServer.window_set_position(ss*0.5-ws*0.5)
	

func _on_back_button_pressed() -> void:
	if is_pop_up:
		SettingsData.loaded_data.exit_settings(self)
	# Leaves without saving
	SettingsData.go_back_to_previous_scene_or_main_scene()
	#Set the scene to change to.


#func _on_borderless_button_toggled(toggled_on: bool) -> void:
	#DisplayServer.window_set_flag( DisplayServer.WINDOW_FLAG_BORDERLESS,toggled_on )
	#SettingsData.loaded_data.settings["video"]["borderless"] = toggled_on


#func _on_fullscreen_button_toggled(toggled_on: bool) -> void:
	#if !toggled_on:
		#DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
		#var ws : Vector2 = Vector2(1920, 1080)
		#DisplayServer.window_set_size(ws)
		#var ss : Vector2 = DisplayServer.screen_get_size()
		#DisplayServer.window_set_position(ss*0.5-ws*0.5)
	#else:
		#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		#DisplayServer.window_set_flag( DisplayServer.WINDOW_FLAG_BORDERLESS, SettingsData.loaded_data.settings["video"]["borderless"] )
	#
	#SettingsData.loaded_data.settings["video"]["fullscreen"] = toggled_on
	#_update_resolution_options_enabled()

#
#func _on_language_options_button_item_selected(index: int) -> void:
	#var locale: String = language_options_button.get_item_metadata(index)
	#TranslationServer.set_locale(locale)
	#SettingsData.loaded_data.settings["accessibility"]["current_locale"] = locale
	##FIXME: _update_ui()


func _on_save_button_pressed() -> void:
	SettingsData.save_settings()
	SettingsData.loaded_data.apply_settings(true)
