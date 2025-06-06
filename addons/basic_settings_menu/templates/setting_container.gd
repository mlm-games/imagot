@tool
extends HBoxContainer
#TODO: fix the setting of language to a different one
@export var setting_name : StringName: # ="EXAMPLE_SETTING"
	set(name):
		setting_name = tr(name)
		if Engine.is_editor_hint() and label: label.text = setting_name

@onready var modifiable_part_of_setting : Control = $ModifiablePartOfSetting
@onready var label: Label = $Label

func _ready() -> void:
	set_initial_state()
	label.text = setting_name
	if modifiable_part_of_setting is Slider:
		modifiable_part_of_setting.value_changed.connect(_on_modifiable_part_of_setting_value_changed.bind())
	if modifiable_part_of_setting is Range and not Slider:
		modifiable_part_of_setting.value_changed.connect(_on_modifiable_part_of_setting_value_changed.bind())
	if modifiable_part_of_setting is CheckButton:
		modifiable_part_of_setting.toggled.connect(_on_modifiable_part_of_setting_value_changed.bind())
	if modifiable_part_of_setting is OptionButton:
		modifiable_part_of_setting.item_selected.connect(_on_modifiable_part_of_setting_value_changed.bind())
	debug_audio_settings()

func set_initial_state():
	var setting_name = name.to_snake_case()
	var category = get_parent().name.to_snake_case()
	if modifiable_part_of_setting is OptionButton: #For option buttons, add here
		if setting_name == "current_locale":
			modifiable_part_of_setting.grab_focus()
			populate_and_set_locale_and_button_item()
		elif setting_name == "resolution":
			populate_resolution_button_items()
		else: #FIXME
			modifiable_part_of_setting.select(modifiable_part_of_setting.get_item_metadata(SettingsData.loaded_data.settings[category][setting_name]))
	elif modifiable_part_of_setting is CheckButton:
		modifiable_part_of_setting.button_pressed = SettingsData.loaded_data.settings[category][setting_name]
	elif modifiable_part_of_setting is Range:
		if "volume" in setting_name or "slider" in setting_name:
			var bus_name := setting_name.replace("_volume", "").capitalize()
			if SettingsData.loaded_data.settings[category].has(bus_name):
				modifiable_part_of_setting.value = SettingsData.loaded_data.settings[category][bus_name] * 100
			else:
				# If setting doesn't exist, initialize with default
				modifiable_part_of_setting.value = GameSettingsSave.DEFAULT_SETTINGS[category][bus_name] * 100
				SettingsData.loaded_data.settings[category][bus_name] = GameSettingsSave.DEFAULT_SETTINGS[category][bus_name]
		else:
			modifiable_part_of_setting.value = SettingsData.loaded_data.settings[category][setting_name]

func _on_modifiable_part_of_setting_value_changed(value: float) -> void:
	var setting_name = name.to_snake_case()
	var category = get_parent().name.to_snake_case()
	
	if modifiable_part_of_setting is Range:
		if "volume" in setting_name or "slider" in setting_name:
			var bus_name := setting_name.replace("_volume", "").capitalize()
			SettingsData.loaded_data.settings[category][bus_name] = value / 100 # in terms of percentage
			var bus_index : int = AudioServer.get_bus_index(bus_name)
			AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100))
			if bus_index >= 0:
				AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / 100))
			else:
				push_error("Audio bus not found: " + bus_name)
			SettingsData.test_play_sound(get_node("./" + bus_name + "BeepPlayer"))
		else:
			#Add your custom stuff here
			SettingsData.loaded_data.settings[category][setting_name] = value
	elif modifiable_part_of_setting is CheckButton:
		SettingsData.loaded_data.settings[category][setting_name] = value
	elif modifiable_part_of_setting is OptionButton:
		if setting_name == "current_locale":
			# Get the actual locale code from the metadata
			var locale = modifiable_part_of_setting.get_item_metadata(value)
			TranslationServer.set_locale(locale)
			# Store the index instead of the locale code
			SettingsData.loaded_data.settings[category]["current_locale"] = value
			print("Changed locale to: " + locale + " (index: " + str(value) + ")")
		elif "resolution" in setting_name:
			#HACK: Doesn't handle proper window placement, just resolution selection
			SettingsData.loaded_data.settings[category]["resolution"] = GameSettingsSave.RESOLUTIONS_ARRAY[value]
			set_resolution_button_item()
			
		else:
			SettingsData.loaded_data.settings[category][setting_name] = value
	
	# Emit signal to notify parent that settings have changed
	#emit_signal("setting_changed", category, setting_name, value)


func populate_and_set_locale_and_button_item():
	var current_locale := TranslationServer.get_locale()
	var saved_locale_index := 0
	
	for locale:String in SettingsData.loaded_data.LOCALES:
		modifiable_part_of_setting.add_item(SettingsData.loaded_data.LOCALES[locale])
		modifiable_part_of_setting.set_item_metadata(modifiable_part_of_setting.get_item_count() - 1, locale)
		if current_locale.begins_with(locale):
			saved_locale_index = modifiable_part_of_setting.get_item_count() - 1
	
	modifiable_part_of_setting.select(saved_locale_index)
	

func set_resolution_button_item():
	var window : Window = get_window()
	window.connect("size_changed", _preselect_resolution.bind(window))
	_update_ui()

func populate_resolution_button_items():
	for resolution in GameSettingsSave.RESOLUTIONS_ARRAY:
		var resolution_string : String = "%d x %d" % [resolution.x, resolution.y]
		modifiable_part_of_setting.add_item(resolution_string)

func _update_ui(window : Window = get_window()) -> void:
	#%FullscreenButton.button_pressed = SettingsData.loaded_data.settings["video"]["fullscreen"]
	if !SettingsData.loaded_data.settings["video"]["fullscreen"]:
			var ws : Vector2 = SettingsData.loaded_data.settings["video"]["resolution"]
			window.size = ws
			var ss : Vector2 = DisplayServer.screen_get_size()
			window.position = ss*0.5-ws*0.5

	_preselect_resolution(window)
	_update_resolution_options_enabled()

func _preselect_resolution(window : Window) -> void:
	modifiable_part_of_setting.text = str(window.size)
	SettingsData.loaded_data.settings["video"]["resolution"] = window.size

func _update_resolution_options_enabled() -> void:
	#TODO: translation stuff
	if OS.has_feature("web"):
		modifiable_part_of_setting.disabled = true
		modifiable_part_of_setting.tooltip_text = "Disabled for web"
	elif SettingsData.loaded_data.settings["video"]["fullscreen"]:
		modifiable_part_of_setting.disabled = true
		modifiable_part_of_setting.tooltip_text = "Disabled for fullscreen"
	else:
		modifiable_part_of_setting.disabled = false
		modifiable_part_of_setting.tooltip_text = "Select a screen size"

func handle_locale_mismatch(current_locale: String) -> String:
	# Iterate through SettingsData.loaded_data.LOCALES and find a matching language code
	for locale:String in SettingsData.loaded_data.LOCALES:
		if current_locale.begins_with(locale):
			return locale
	
	#If no match is found, use the default locale
	return SettingsData.loaded_data.LOCALES.keys()[0]



func debug_audio_settings():
	print("--- AUDIO SETTINGS DEBUG ---")
	
	# Print all available audio buses
	print("Available audio buses:")
	for i in range(AudioServer.get_bus_count()):
		var bus_name = AudioServer.get_bus_name(i)
		var volume_db = AudioServer.get_bus_volume_db(i)
		var volume_linear = db_to_linear(volume_db)
		print("  Bus #" + str(i) + ": " + bus_name + " (Volume: " + str(volume_db) + " dB, " + str(volume_linear * 100) + "%)")
	
	# Print stored audio settings
	print("Stored audio settings:")
	if SettingsData.loaded_data and SettingsData.loaded_data.settings.has("audio"):
		for key in SettingsData.loaded_data.settings["audio"]:
			print("  " + key + ": " + str(SettingsData.loaded_data.settings["audio"][key]))
	else:
		print("  No audio settings found!")
	
	print("------------------------")
