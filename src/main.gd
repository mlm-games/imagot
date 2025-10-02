extends Control

@onready var status_label: Label = %StatusLabel
@onready var file_dialog: FileDialog = %FileDialog
@onready var properties_dialog: AcceptDialog = %PropertiesDialog

@onready var viewport_container: SubViewportContainer = %ViewportContainer
@onready var sub_viewport: SubViewport = %SubViewport
@onready var image_sprite: Sprite2D = %ImageSprite
@onready var camera: Camera2D = %Camera2D

# --- Image and View State ---
var current_image_path: String = ""
var directory_files: Array[String] = []
var current_index: int = -1

var pinch_tween: Tween

# state variables for camera control
var is_panning: bool = false
var pan_start_pos: Vector2

# Godot's runtime-loadable image formats
const SUPPORTED_EXTENSIONS = ["png", "jpg", "jpeg", "webp", "bmp", "tga", "svg", "exr", "hdr"]

func _ready() -> void:
	%OpenButton.grab_focus()
	camera.make_current()
	_connect_signals()
	await get_tree().create_timer(0.1).timeout
	_handle_launch_args()
	get_tree().root.files_dropped.connect(_on_files_dropped)
	OS.request_permissions()
	# %FirstOpenLabel.show() # If desired

func load_image(path: String) -> void:
	%FirstOpenLabel.hide()

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		status_label.text = "Error: Cannot open file: %s" % path
		return

	var buffer := file.get_buffer(file.get_length())
	file.close()

	var image := Image.new()
	var ext := path.get_extension().to_lower()
	var err: int = ERR_CANT_OPEN

	match ext:
		"jpg", "jpeg":
			err = image.load_jpg_from_buffer(buffer)
		"png":
			err = image.load_png_from_buffer(buffer)
		"webp":
			err = image.load_webp_from_buffer(buffer)
		"bmp":
			err = image.load_bmp_from_buffer(buffer)
		"tga":
			err = image.load_tga_from_buffer(buffer)
		"svg":
			# Use default DPI; you can pass a scale for higher resolution if needed:
			err = image.load_svg_from_buffer(buffer)
		"exr":
			err = image.load_exr_from_buffer(buffer)
		"hdr":
			err = image.load_hdr_from_buffer(buffer)
		_:
			# Fallback: try the generic loader
			image = Image.load_from_file(path)

	if err != OK:
		status_label.text = "Error: Could not load image at %s" % path
		return

	current_image_path = path
	image_sprite.texture = ImageTexture.create_from_image(image)

	# Reset sprite transform
	image_sprite.scale = Vector2.ONE
	image_sprite.rotation_degrees = 0.0
	image_sprite.position = Vector2.ZERO  # keep image centered at world origin

	scan_directory()
	_on_zoom_fit_pressed()

func update_status_bar() -> void:
	if not image_sprite.texture:
		return

	var image_size := image_sprite.texture.get_size()
	get_window().title = "%s - Imagot Viewer" % current_image_path.get_file()

	var zoom_percent := int(round(camera.zoom.x * 100.0))
	var rot_degrees := int(round(image_sprite.rotation_degrees))
	var pos := camera.position

	status_label.text = "%s | %dx%d | Zoom: %d%% | Rotation: %d° | Position: %d,%d" % [
		current_image_path.get_file(), image_size.x, image_size.y,
		zoom_percent, rot_degrees, int(pos.x), int(pos.y)
	]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				is_panning = event.pressed
				if is_panning:
					pan_start_pos = event.position
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_handle_zoom_at_point(1.1, event.global_position)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_handle_zoom_at_point(0.9, event.global_position)

	if event is InputEventMouseMotion and is_panning:
		var world_delta := _screen_delta_to_world(event.relative)
		camera.position -= world_delta
		update_status_bar()

func _unhandled_input(event: InputEvent) -> void:
	# Keyboard shortcuts
	if event.is_action_pressed("zoom_in"):
		_handle_zoom_center(1.25)
	if event.is_action_pressed("zoom_out"):
		_handle_zoom_center(0.8)
	if event.is_action_pressed("zoom_fit"):
		_on_zoom_fit_pressed()
	if event.is_action_pressed("actual_size"):
		_on_actual_size_pressed()
	if event.is_action_pressed("rotate_left"):
		_on_rotate_left_pressed()
	if event.is_action_pressed("rotate_right"):
		_on_rotate_right_pressed()
	if event.is_action_pressed("flip_horizontal"):
		_on_flip_h_pressed()
	if event.is_action_pressed("flip_vertical"):
		_on_flip_v_pressed()
	if event.is_action_pressed("show_properties"):
		_show_properties_dialog()
	if event.is_action_pressed("navigate_right"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("navigate_left"):
		_on_prev_pressed()
		get_viewport().set_input_as_handled()
	if event is InputEventMagnifyGesture:
		_handle_zoom_at_point(event.factor, get_global_mouse_position())

# --- Coordinate helpers (map screen -> SubViewport -> world) ---

func _sv_content_scale_and_offset() -> Dictionary:
	# How the SubViewport texture is drawn into the SubViewportContainer (letterbox/pillarbox)
	var csize: Vector2 = viewport_container.size
	var vsize: Vector2 = Vector2(sub_viewport.size)
	if vsize.x <= 0.0 or vsize.y <= 0.0:
		return {"scale": 1.0, "offset": Vector2.ZERO}
	var scale := minf(csize.x / vsize.x, csize.y / vsize.y)
	var drawn_size : Vector2 = vsize * scale
	var offset := (csize - drawn_size) * 0.5
	return {"scale": scale, "offset": offset}

func _to_subviewport_pos(screen_pos: Vector2) -> Vector2:
	var rect := viewport_container.get_global_rect()
	var local_in_container := screen_pos - rect.position
	var d := _sv_content_scale_and_offset()
	return (local_in_container - d.offset) / d.scale

func _screen_delta_to_world(screen_delta: Vector2) -> Vector2:
	var d := _sv_content_scale_and_offset()
	# Convert from screen pixels to SubViewport pixels, then to world by dividing by zoom
	var delta_sv : Vector2 = screen_delta / d.scale
	return delta_sv / camera.zoom

# --- Zoom handlers ---

func _handle_zoom_at_point(zoom_factor: float, screen_position: Vector2) -> void:
	if not image_sprite.texture:
		return
	var pos_in_sv := _to_subviewport_pos(screen_position)
	var xform := camera.get_screen_transform()
	var world_before := xform.affine_inverse() * pos_in_sv

	var new_scale := clampf(camera.zoom.x * zoom_factor, 0.1, 10.0)
	camera.zoom = Vector2(new_scale, new_scale)

	var xform_after := camera.get_screen_transform()
	var world_after := xform_after.affine_inverse() * pos_in_sv

	camera.position += world_before - world_after
	update_status_bar()

func _handle_zoom_center(zoom_factor: float) -> void:
	if not image_sprite.texture:
		return
	var new_scale := clampf(camera.zoom.x * zoom_factor, 0.1, 10.0)
	camera.zoom = Vector2(new_scale, new_scale)
	update_status_bar()

# --- UI signal wiring ---

func _connect_signals() -> void:
	# File
	%OpenButton.pressed.connect(_on_open_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	# Navigation
	%PrevButton.pressed.connect(_on_prev_pressed)
	%NextButton.pressed.connect(_on_next_pressed)
	# View
	%ZoomOutButton.pressed.connect(func(): _handle_zoom_center(0.8))
	%ZoomInButton.pressed.connect(func(): _handle_zoom_center(1.25))
	%ZoomFitButton.pressed.connect(_on_zoom_fit_pressed)
	%ActualSizeButton.pressed.connect(_on_actual_size_pressed)
	# Transform
	%RotateLeftButton.pressed.connect(_on_rotate_left_pressed)
	%RotateRightButton.pressed.connect(_on_rotate_right_pressed)
	%FlipHButton.pressed.connect(_on_flip_h_pressed)
	%FlipVButton.pressed.connect(_on_flip_v_pressed)
	# Info
	%PropertiesButton.pressed.connect(_show_properties_dialog)
	# Keep SubViewport size in sync with container
	get_window().size_changed.connect(func(): sub_viewport.size = Vector2i(viewport_container.size))
	viewport_container.resized.connect(func(): sub_viewport.size = Vector2i(viewport_container.size))

# --- Fit / Actual size ---

func _on_zoom_fit_pressed() -> void:
	if not image_sprite.texture:
		return
	var padding := 0.95
	var view_size := Vector2(sub_viewport.size) * padding
	var image_size := image_sprite.texture.get_size()
	if image_size.x == 0 or image_size.y == 0:
		return
	var scale_x := view_size.x / image_size.x
	var scale_y := view_size.y / image_size.y
	var z := clampf(min(scale_x, scale_y), 0.1, 10.0)
	camera.zoom = Vector2(z, z)
	# Center the camera on the image (image is at world origin)
	camera.position = image_sprite.global_position
	update_status_bar()

func _on_actual_size_pressed() -> void:
	camera.zoom = Vector2.ONE
	camera.position = image_sprite.global_position
	update_status_bar()

# --- Rotate / Flip ---

func _on_rotate_left_pressed() -> void:
	image_sprite.rotation_degrees = fmod(image_sprite.rotation_degrees - 90.0, 360.0)
	update_status_bar()

func _on_rotate_right_pressed() -> void:
	image_sprite.rotation_degrees = fmod(image_sprite.rotation_degrees + 90.0, 360.0)
	update_status_bar()

func _on_flip_h_pressed() -> void:
	image_sprite.scale.x *= -1.0
	update_status_bar()

func _on_flip_v_pressed() -> void:
	image_sprite.scale.y *= -1.0
	update_status_bar()

# --- Properties ---

func _show_properties_dialog() -> void:
	if current_image_path.is_empty():
		return
	var file_name := current_image_path.get_file()
	var file_size_bytes := FileAccess.get_file_as_bytes(current_image_path).size()
	var file_size_str := str(file_size_bytes) + " B"
	if file_size_bytes > 1024 * 1024:
		file_size_str = "%.2f MB" % (file_size_bytes / (1024.0 * 1024.0))
	elif file_size_bytes > 1024:
		file_size_str = "%.2f KB" % (file_size_bytes / 1024.0)

	%ValueName.text = file_name
	%ValuePath.text = current_image_path
	%ValueDims.text = "%s x %s" % [image_sprite.texture.get_width(), image_sprite.texture.get_height()]
	%ValueSize.text = file_size_str
	%ValueFormat.text = current_image_path.get_extension().to_upper()

	properties_dialog.popup_centered()

# --- Startup & navigation ---

func _handle_launch_args() -> void:
	var args := OS.get_cmdline_args()
	if args.size() > 0:
		var path: String = args[0]
		if FileAccess.file_exists(path):
			if SUPPORTED_EXTENSIONS.has(path.get_extension().to_lower()):
				load_image(path)
		else:
			print("No starter file by cmd path, open main screen")
	if current_image_path.is_empty():
		status_label.text = "Open an image to begin..."

func scan_directory() -> void:
	if current_image_path.is_empty():
		return

	directory_files.clear()
	var dir_path := current_image_path.get_base_dir()
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension().to_lower() in SUPPORTED_EXTENSIONS:
				directory_files.append(dir_path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()

		directory_files.sort()
		current_index = directory_files.find(current_image_path)

func _on_files_dropped(files: PackedStringArray) -> void:
	if files.size() > 0:
		var path := files[0]
		if SUPPORTED_EXTENSIONS.has(path.get_extension().to_lower()):
			load_image(path)

func _on_open_pressed() -> void:
	file_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	load_image(path)

func _on_next_pressed() -> void:
	if current_index != -1 and current_index < directory_files.size() - 1:
		current_index += 1
		load_image(directory_files[current_index])

func _on_prev_pressed() -> void:
	if current_index > 0:
		current_index -= 1
		load_image(directory_files[current_index])
