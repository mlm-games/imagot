extends Control

@onready var texture_rect: TextureRect = %TextureRect
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var status_label: Label = %StatusLabel
@onready var file_dialog: FileDialog = %FileDialog

# --- Image State ---
var current_image_path: String = ""
var directory_files: Array[String] = []
var current_index: int = -1
var zoom_factor: float = 1.0
var img_rotation_degrees: float = 0.0

# Godot's runtime-loadable image formats
const SUPPORTED_EXTENSIONS = ["png", "jpg", "jpeg", "webp", "bmp", "tga", "svg", "ktx", "exr", "hdr"]


func _ready() -> void:
	%OpenButton.pressed.connect(_on_open_pressed)
	%PrevButton.pressed.connect(_on_prev_pressed)
	%NextButton.pressed.connect(_on_next_pressed)
	%ZoomOutButton.pressed.connect(_on_zoom_out_pressed)
	%ZoomInButton.pressed.connect(_on_zoom_in_pressed)
	%ZoomFitButton.pressed.connect(_on_zoom_fit_pressed)
	%RotateLeftButton.pressed.connect(_on_rotate_left_pressed)
	%RotateRightButton.pressed.connect(_on_rotate_right_pressed)
	file_dialog.file_selected.connect(_on_file_selected)

	# --- THIS IS THE KEY FOR "SET AS DEFAULT" ---
	# Check if the app was launched with a file path argument.
	var args = OS.get_cmdline_args()
	if args.size() > 1:
		# Note: The first argument is the executable path, so we check the second.
		# Handle paths with spaces by joining subsequent args.
		var potential_path = " ".join(args.slice(1))
		if FileAccess.file_exists(potential_path):
			load_image(potential_path)
	
	if current_image_path.is_empty():
		status_label.text = "Open an image to begin (Ctrl+O or use the 'Load' button)."

func load_image(path: String) -> void:
	var image = Image.new()
	var err = image.load(path)

	if err != OK:
		status_label.text = "Error: Could not load image at %s" % path
		return

	# If loaded successfully, update state
	current_image_path = path
	texture_rect.texture = ImageTexture.create_from_image(image)
	texture_rect.scale = Vector2.ONE
	
	# Scan the directory for other images
	scan_directory()
	
	# Reset view and fit the new image
	img_rotation_degrees = 0
	_on_zoom_fit_pressed() # This also calls update_display()

func update_display() -> void:
	if not texture_rect.texture:
		return

	# Apply transformations
	texture_rect.rotation_degrees = img_rotation_degrees
	texture_rect.scale = Vector2(zoom_factor, zoom_factor)

	# Update the status bar
	var image_size = texture_rect.texture.get_size()
	get_window().title = "%s - Godot Image Viewer" % current_image_path.get_file()
	status_label.text = "%s | %dx%d | Zoom: %d%% | Rotation: %d°" % [
		current_image_path.get_file(),
		image_size.x,
		image_size.y,
		int(zoom_factor * 100),
		int(img_rotation_degrees)
	]

func scan_directory() -> void:
	if current_image_path.is_empty():
		return

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

# --- Button Signal Handlers ---

func _on_open_pressed() -> void:
	file_dialog.popup_centered()
	file_dialog.show()

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

func _on_zoom_in_pressed() -> void:
	zoom_factor *= 1.2
	update_display()

func _on_zoom_out_pressed() -> void:
	zoom_factor /= 1.2
	update_display()

func _on_zoom_fit_pressed() -> void:
	if not texture_rect.texture:
		return
	
	# Small padding to avoid scrollbars appearing unnecessarily
	var view_size = scroll_container.size * 0.98
	var image_size = texture_rect.texture.get_size()
	
	if image_size.x == 0 or image_size.y == 0:
		return

	var scale_x = view_size.x / image_size.x
	var scale_y = view_size.y / image_size.y
	zoom_factor = min(scale_x, scale_y)
	
	update_display()

func _on_rotate_left_pressed() -> void:
	img_rotation_degrees = fmod(img_rotation_degrees - 90.0, 360.0)
	update_display()

func _on_rotate_right_pressed() -> void:
	img_rotation_degrees = fmod(img_rotation_degrees + 90.0, 360.0)
	update_display()
