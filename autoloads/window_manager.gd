extends Node

signal fullscreen_changed(is_fullscreen: bool)

var _stored_position: Vector2i = Vector2i.ZERO
var _stored_size: Vector2i = Vector2i.ZERO

func _input(event):
	# Desktop only, and not the Web export
	if not (OS.get_name() in ["Windows", "macOS", "Linux"]) or OS.has_feature("web"):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F11:
				toggle_fullscreen()
			# If you want ESC to exit fullscreen (and you're not using ESC in-game), uncomment:
			# KEY_ESCAPE:
			# 	if is_fullscreen():
			# 		exit_fullscreen()

func toggle_fullscreen():
	if is_fullscreen():
		exit_fullscreen()
	else:
		enter_fullscreen()

func enter_fullscreen():
	_store_window_state()
	# macOS doesn’t support "exclusive"
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_changed.emit(true)

func exit_fullscreen():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_restore_window_state()
	fullscreen_changed.emit(false)

func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	]

func _store_window_state():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		_stored_position = DisplayServer.window_get_position()
		_stored_size = DisplayServer.window_get_size()

func _restore_window_state():
	if _stored_size != Vector2i.ZERO:
		DisplayServer.window_set_size(_stored_size)
		DisplayServer.window_set_position(_stored_position)
