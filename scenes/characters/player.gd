extends CharacterBody3D

var SPEED = 5.0
const JUMP_VELOCITY = 4.5

const sens = 0.2

var player_locomotion_state
enum player_locomotion_states {IDLE, WALK, RUN}

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player_locomotion_state = player_locomotion_states.IDLE

func _input(event):
	if event is InputEventMouseMotion:
		$CameraController.rotation.y+=deg_to_rad(-event.relative.x*sens)
		var new_camera_rotation = deg_to_rad(-event.relative.y*(sens*sens))
		var next_camera_x_rotation = rad_to_deg($CameraController.rotation.x+new_camera_rotation)
		if next_camera_x_rotation>-30 and next_camera_x_rotation<45:
			$CameraController.rotation.x+=new_camera_rotation
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
	if Input.is_action_pressed("run"):
		SPEED = lerp(SPEED, 4.0, 0.1)
		player_locomotion_state = player_locomotion_states.RUN
	else:
		SPEED = lerp(SPEED, 2.0, 0.1)
		player_locomotion_state = player_locomotion_states.WALK

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$AnimationTree.set("parameters/JumpTrigger/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var blend_position:float = $AnimationTree.get("parameters/Locomotion/blend_position")
	var blend_value = 0.03
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		var body_rotation = atan2(-input_dir.x, -input_dir.y)
		$Armature.rotation.y=lerp_angle($Armature.rotation.y, body_rotation, 0.1)
		
		rotation.y=lerp_angle(rotation.y, $CameraController.rotation.y, 0.1)
		
		if player_locomotion_state == player_locomotion_states.RUN:
			blend_position = clamp(blend_position + blend_value, blend_position, 1)
		else:
			if blend_position > 0.5:
				blend_position = clamp(blend_position - blend_value, 0.5, blend_position)
			else:
				blend_position = clamp(blend_position + blend_value, blend_position, 0.5)
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		player_locomotion_state = player_locomotion_states.IDLE
		blend_position = clamp(blend_position - blend_value, 0.0, blend_position)
	
	$AnimationTree.set("parameters/Locomotion/blend_position", blend_position)

	move_and_slide()

	$CameraController.position=lerp($CameraController.position,position,0.1)
