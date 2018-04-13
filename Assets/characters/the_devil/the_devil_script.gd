extends KinematicBody

#signals
signal waiting
signal super_action_name
signal hide_time

var camera_angle = -19
var mouse_sensitivity = 0.3

var up = Vector3(0,1,0)
var side = Vector3(1,0,0)

var velocity = Vector3()
var direction = Vector3()

var character_direction = Vector3()

#camera
onready var camera = $head/devil_camera
onready var camera_ray = $head/camera_cast

#character vars
var ready_for_super = 0
var preparing = 0
var slamming = 0
var no_moving = 0

#walk_variables
#var gravity = 9.8 * 3
var gravity = 9.8 * 1.5

var is_moving = 1
var speed
const max_speed = 7
const air_speed = 3
const max_running_speed = 20
const accel = 2
const de_accel = 6
const slam = 50

#jumping vars
var ready_for_long_jump = 0
var jump_height = 12
var double_jump = 1
var super_jump = 30

#fly_variable
const fly_speed = 40
const fly_accelerate = 10

#body vars
var turn_speed = 6

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
#	$the_devil_mesh/AnimationPlayer.play("walk")
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _physics_process(delta):
	if !no_moving:
	#is our character is preparing for a super feat? No? Make him walk!
		move(delta, 7)
		if preparing == 0 and is_on_floor():
			walk(delta)	
		else:
			preparing_for_power(delta)
		
		if !is_on_floor():
			in_air(delta)
		
	else:
		wait(delta)

func _input(event):
	#only when the mouse moves
	if event is InputEventMouseMotion:
		#rotate side to side immediately
		$head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		#
		var change = -event.relative.y * mouse_sensitivity
		
		if change + camera_angle < 90 and change + camera_angle > -90:
			#$head.rotate_x(deg2rad(change))
			$head.rotate_object_local(side, -deg2rad(change))
			
			camera_angle += change

func walk(delta):
	
	#are we running? send the speed to the move function
#	var speed
	if Input.is_action_pressed("move_sprint"):
		speed = max_running_speed
	else:
		speed = max_speed

func in_air(delta):
#	if velocity.y < 0:
	max_speed = 30
	accel = 1
	#slam the ground if the slam key is pressed
	if Input.is_action_just_pressed("slam") and ready_for_super >= 1:
		$slam_timer.start()
		$slam_cast.enabled = true
		ready_for_super = 0
		slamming = 1
			
	if slamming == 1:
		if $slam_timer.time_left > 0:
			
			velocity.y = velocity.y/2
			velocity.x = velocity.x/2
			velocity.z = velocity.z/2	
		else:
			velocity.y -= slam
		
		#are we about to hit the ground, exit the slamming state
		if $slam_cast.is_colliding():
			print("hello!")
			emit_signal("super_action_name","WHAM!")
			$no_moving_timer.start()
			no_moving = 1
			slamming = 0
#			$slam_cast.enabled = false
	
	#double jump accounting	
	if Input.is_action_just_pressed("jump") and double_jump == 1:
		velocity.y = jump_height*1.5
		double_jump = 0

func preparing_for_power(delta):
	velocity.y -= gravity*delta	
	if $jump_timer.time_left < 1.5:
		velocity.x = velocity.x/1.1
		velocity.z = velocity.z/1.1
#	velocity = move_and_slide(velocity, up)
	if is_on_floor() and preparing == 1:
		#update the signal with waiting time at two decimal places
		emit_signal("waiting",str("%2.2f" % $jump_timer.time_left))
		if Input.is_action_just_released("jump") and $jump_timer.time_left > 0.2:
			set_double_jump()
			$jump_timer.stop()
			emit_signal("hide_time")
			velocity.y = jump_height
			preparing = 0
		elif Input.is_action_just_released("jump") and ready_for_long_jump == 1:
			set_double_jump()
			$jump_timer.stop()
			velocity.y = super_jump
			emit_signal("hide_time")
			emit_signal("super_action_name","SEE YA!")
			ready_for_super = 1
			ready_for_long_jump = 0
			preparing = 0

#if we want our character to wait a bit
# change the no_moving timer to tweak the duration of the wait
func wait(delta):
	#ease out the movement
	velocity.y -= gravity *delta
	velocity.x = velocity.x/2
	velocity.z = velocity.z/2
	velocity = move_and_slide(velocity,up)
	emit_signal("waiting",str("%2.2f" % $no_moving_timer.time_left))
	#once the timer is up we return to normal movements
	if $no_moving_timer.time_left == 0:
		emit_signal("super_action_name", "Let's do this!")
		emit_signal("hide_time")
		no_moving = 0
	

func fly(delta, speed):
	#reset the direction of the player
	direction = Vector3()
	#get the direction of the head
	var aim = $head.global_transform.basis

	#getting direction when keys are pressed
	if Input.is_action_pressed("move_forward"):
		direction += aim.z
	if Input.is_action_pressed("move_backward"):
		direction -= aim.z
	if Input.is_action_pressed("move_left"):
		direction += aim.x
	if Input.is_action_pressed("move_right"):
		direction -= aim.x
		
	direction = direction.normalized()
	#whats the max speed
	var target_vel = direction*fly_speed	
	#accel
	velocity = velocity.linear_interpolate(target_vel, fly_accelerate * delta)
	#move
	move_and_slide(velocity)
	
func rotate_body(desired_rotation,delta):
	#turn body only when on floor
	if is_on_floor():	
		var temp_rotation = $the_devil_mesh.rotation.linear_interpolate(Vector3(0, desired_rotation, 0), turn_speed * delta)
		$the_devil_mesh.rotation.y = temp_rotation.y
		
func rotate_body_02(angle):
	$the_devil_mesh.rotation.y = angle	
		
func set_double_jump():
	double_jump = 1

func _on_jump_timer_timeout():
	ready_for_long_jump = 1

func move(delta, speed):
	#reset the direction of the player
	direction = Vector3()
	#get the direction of the head
	var aim = $head.global_transform.basis

	#getting direction when keys are pressed
	if Input.is_action_pressed("move_forward"):
		direction += aim.z
		rotate_body($head.rotation.y, delta)
		
	if Input.is_action_pressed("move_backward"):
		direction -= aim.z
		rotate_body($head.rotation.y, delta)
		
	if Input.is_action_pressed("move_left"):
		direction += aim.x
		rotate_body($head.rotation.y, delta)
		
	if Input.is_action_pressed("move_right"):
		direction -= aim.x
		rotate_body($head.rotation.y, delta)
		
	direction = direction.normalized()
	
	velocity.y -= gravity * delta
	var temp_velocity = velocity
	temp_velocity.y = 0

	#accelerate	until we reach the optimal speed
	var acceleration
	if direction.dot(temp_velocity) > 0:
		acceleration = accel
	else:
		acceleration = de_accel
	
	#whats the max speed
	var target_vel = direction * speed
	
	#accel
	temp_velocity = temp_velocity.linear_interpolate(target_vel, accel * delta)
	
	velocity.x = temp_velocity.x
	velocity.z = temp_velocity.z
	
#	if velocity.z + velocity .x > 0.5:
#		rotate_body_02(atan2(velocity.x, velocity.z))
	
	#move
	velocity = move_and_slide(velocity, up)
	
	#jump logic
	if is_on_floor() and Input.is_action_pressed("jump"):
		#start the timer if the player is not preparing for something, we start the prep and change states
		if preparing == 0:
			$jump_timer.start()
			preparing = 1
	
