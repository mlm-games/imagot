extends Control

@onready var status_label: Label = %StatusLabel
@onready var file_dialog: FileDialog = %FileDialog
@onready var properties_dialog: AcceptDialog = %PropertiesDialog

@onready var viewport_container: TextureRect = %ViewportContainer
@onready var image_sprite: TextureRect = %ImageSprite
@onready var camera: Camera2D = %Camera2D

# --- Image and View State ---
var current_image_path: String = ""
var directory_files: Array[String] = []
var current_index: int = -1

# state variables for camera control
var is_panning: bool = false
var is_moving: bool = false
var pan_start_pos: Vector2
var move_start_pos: Vector2

# Godot's runtime-loadable image formats
const SUPPORTED_EXTENSIONS = ["png", "jpg", "jpeg", "webp", "bmp", "tga", "svg", "exr", "hdr"]


func _ready() -> void:
	%OpenButton.grab_focus()
	camera.make_current()

	_connect_signals()

	_handle_launch_args()


func load_image(path: String) -> void:
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		status_label.text = "Error: Cannot open file: %s" % path
		return
	
	var buffer = file.get_buffer(file.get_length())
	file.close()
	var err
	var image = Image.new()
	if path.get_extension() == "jpeg":
		err = image.load_jpg_from_buffer(buffer)
	else:
		err = image.call("load_" + path.get_extension() + "_from_buffer", buffer)

	if err != OK:
		status_label.text = "Error: Could not load image at %s" % path
		return

	# If loaded successfully, update state
	current_image_path = path
	image_sprite.texture = ImageTexture.create_from_image(image)
	
	# Reset sprite properties before fitting
	image_sprite.scale = Vector2.ONE
	image_sprite.rotation_degrees = 0
	
	scan_directory()
	
	# Fit the new image to the view
	_on_zoom_fit_pressed()

func update_status_bar() -> void:
	if not image_sprite.texture:
		return

	var image_size = image_sprite.texture.get_size()
	get_window().title = "%s - Imagot Viewer" % current_image_path.get_file()
	
	var zoom_percent = int(camera.zoom.x * 100)
	var rot_degrees = int(image_sprite.rotation_degrees)
	
	status_label.text = "%s | %dx%d | Zoom: %d%% | Rotation: %d° | Position: %dx%d" % [
		current_image_path.get_file(), image_size.x, image_size.y,
		zoom_percent, rot_degrees, camera.position.x, camera.position.y
	]

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				is_panning = true
				pan_start_pos = event.position
			else:
				is_panning = false
	
	
	if event is InputEventMouseMotion:
		#print(event)
		if is_panning:
			camera.position -= event.relative / camera.zoom
			update_status_bar()
	

	# Zooming with Mouse Wheel (to mouse position)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_handle_zoom_at_point(1.01, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_handle_zoom_at_point(0.99, event.position)

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

func _handle_zoom_at_point(zoom_factor: float, screen_position: Vector2) -> void:
	if not image_sprite.texture: return
	
	var viewport_rect = %ViewportContainer.get_global_rect()
	
	# Convert screen position to viewport position
	var viewport_position = screen_position - viewport_rect.position
	
	# Get the world position before zoom
	var world_pos_before = camera.get_global_transform().affine_inverse() * viewport_position
	
	# Apply zoom
	var old_zoom = camera.zoom
	var new_zoom = old_zoom * zoom_factor
	new_zoom = new_zoom.clamp(Vector2(0.1, 0.1), Vector2(10.0, 10.0))
	camera.zoom = new_zoom
	
	# Get the world position after zoom
	var world_pos_after = camera.get_global_transform().affine_inverse() * viewport_position
	
	# Adjust camera position to keep the same world point under the mouse
	camera.position += world_pos_before - world_pos_after
	
	update_status_bar()

func _handle_zoom_center(zoom_factor: float) -> void:
	if not image_sprite.texture: return
	
	var old_zoom = camera.zoom
	var new_zoom = old_zoom * zoom_factor
	if new_zoom == 0.1:
		new_zoom = -new_zoom * 10
	#new_zoom = new_zoom.clamp(Vector2(0.1, 0.1), Vector2(10.0, 10.0))
	camera.zoom = new_zoom
	
	update_status_bar()

func _connect_signals() -> void:
	# File
	%OpenButton.pressed.connect(_on_open_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	# Navigation
	%PrevButton.pressed.connect(_on_prev_pressed)
	%NextButton.pressed.connect(_on_next_pressed)
	# View
	%ZoomOutButton.pressed.connect(func(): _handle_zoom(0.8))
	%ZoomInButton.pressed.connect(func(): _handle_zoom(1.25))
	%ZoomFitButton.pressed.connect(_on_zoom_fit_pressed)
	%ActualSizeButton.pressed.connect(_on_actual_size_pressed)
	# Transform
	%RotateLeftButton.pressed.connect(_on_rotate_left_pressed)
	%RotateRightButton.pressed.connect(_on_rotate_right_pressed)
	%FlipHButton.pressed.connect(_on_flip_h_pressed)
	%FlipVButton.pressed.connect(_on_flip_v_pressed)
	# Info
	%PropertiesButton.pressed.connect(_show_properties_dialog)
	# Resize event to keep the viewport updated
	get_window().size_changed.connect(func(): %SubViewport.size = %ViewportContainer.size)


func _handle_zoom(zoom_multiplier: float) -> void:
	if not image_sprite.texture: return
	
	var old_zoom = camera.zoom
	var new_zoom = old_zoom * zoom_multiplier
	
	# Get mouse position relative to the viewport
	var mouse_in_viewport = viewport_container.get_global_mouse_position()
	
	# Find where the mouse is pointing in the "world" (the SubViewport)
	var point_in_world = camera.get_canvas_transform().affine_inverse() * (mouse_in_viewport)
	
	camera.zoom = new_zoom
	
	# Reposition camera so the world point stays under the mouse
	var new_point_in_viewport = camera.get_canvas_transform() * (point_in_world)
	camera.position += (mouse_in_viewport - new_point_in_viewport) / camera.zoom
	
	update_status_bar()


func _show_properties_dialog() -> void:
	if current_image_path.is_empty(): return
	
	var file_name = current_image_path.get_file()
	var file_size_bytes = FileAccess.get_file_as_bytes(current_image_path).size()
	var file_size_str = str(file_size_bytes) + " B"
	if file_size_bytes > 1024 * 1024:
		file_size_str = "%.2f MB" % (file_size_bytes / (1024.0*1024.0))
	elif file_size_bytes > 1024:
		file_size_str = "%.2f KB" % (file_size_bytes / 1024.0)

	%ValueName.text = file_name
	%ValuePath.text = current_image_path
	%ValueDims.text = "%s x %s" % [image_sprite.texture.get_width(), image_sprite.texture.get_height()]
	%ValueSize.text = file_size_str
	%ValueFormat.text = current_image_path.get_extension().to_upper()
	
	properties_dialog.popup_centered()

func _handle_launch_args() -> void:
	var args = OS.get_cmdline_args()
	if args.size() > 0:
		var path : String = args[0]#" ".join(args.slice(1))
		if FileAccess.file_exists(args[0]):
			if SUPPORTED_EXTENSIONS.has(path.get_extension()):
				print("Starter file exists and is supported")
				load_image(args[0])
		else :
			print("NO")
	
	if current_image_path.is_empty():
		status_label.text = "Open an image to begin..."

func scan_directory() -> void:
	if current_image_path.is_empty(): return

	directory_files.clear()
	var dir_path = current_image_path.get_base_dir()
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension().to_lower() in SUPPORTED_EXTENSIONS:
				directory_files.append(dir_path.path_join(file_name))
			file_name = dir.get_next()
		
		directory_files.sort()
		current_index = directory_files.find(current_image_path)

#  Signals

func _on_open_pressed() -> void:
	file_dialog.popup_centered()

func _on_file_selected(path: String) -> void:
	print(path)
	load_image(path)

func _on_next_pressed() -> void:
	if current_index != -1 and current_index < directory_files.size() - 1:
		current_index += 1
		load_image(directory_files[current_index])

func _on_prev_pressed() -> void:
	if current_index > 0:
		current_index -= 1
		load_image(directory_files[current_index])

func _on_zoom_fit_pressed() -> void:
	if not image_sprite.texture: return
	
	var view_size = viewport_container.size * 0.95 # Small padding
	var image_size = image_sprite.texture.get_size()
	
	if image_size.x == 0 or image_size.y == 0: return

	var scale_x = view_size.x / image_size.x
	var scale_y = view_size.y / image_size.y
	
	camera.zoom = Vector2.ONE * min(scale_x, scale_y)
	
	# Center the camera on the image
	camera.position = viewport_container.size/2  #- Vector2(image_size.x/2, image_size.y/2)
	
	update_status_bar()

func _on_actual_size_pressed() -> void:
	camera.zoom = Vector2.ONE
	camera.position = Vector2.ZERO
	update_status_bar()

func _on_rotate_left_pressed() -> void:
	image_sprite.rotation_degrees = fmod(image_sprite.rotation_degrees - 90.0, 360.0)
	update_status_bar()

func _on_rotate_right_pressed() -> void:
	image_sprite.rotation_degrees = fmod(image_sprite.rotation_degrees + 90.0, 360.0)
	update_status_bar()

func _on_flip_h_pressed() -> void:
	image_sprite.scale.x *= -1
	update_status_bar()

func _on_flip_v_pressed() -> void:
	image_sprite.scale.y *= -1
	update_status_bar()
