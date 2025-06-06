@tool
extends EditorPlugin

var pluginPath: String = get_script().resource_path.get_base_dir()
const SettingsData: String = "/settings_data.gd"


func _enter_tree():
	add_autoload_singleton("SettingsData", pluginPath + SettingsData)


func _exit_tree():
	remove_autoload_singleton("SettingsData")
