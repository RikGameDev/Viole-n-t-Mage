extends Area2D

var level = 1
var hp = 9999
var speed = 200.0
var damage = 10
var knockback_amount = 100
var paths = 1
var attack_size = 1.0
var attack_speed = 5.0

var target = Vector2.ZERO
var target_array = []

var angle = Vector2.ZERO
var reset_pos = Vector2.ZERO

var spr_jav_reg = preload("res://Weapons/Souls Edge Eye Closed.png")
var spr_jav_atk = preload("res://Weapons/Souls Edge Eye open.png")

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var attackTimer = get_node("%AttackTimer")
@onready var changeDirectionTimer = get_node("%ChangeDirection")
@onready var resetPosTimer = get_node("%ResetPosTimer")
@onready var snd_attack = $snd_attack

signal remove_from_array(object)

func _ready():
	update_javelin()
	_on_reset_pos_timer_timeout()
	
func update_javelin():
	level = player.javelin_level
	match level:                  # Set javelin stats 
		1:
			hp = 9999
			speed = 200
			damage = 10
			knockback_amount = 100
			paths = 1
			attack_size = 1.0 * (1 + player.spell_size)
			attack_speed = 5.0 * (1-player.spell_cooldown)
		2:
			hp = 9999
			speed = 200
			damage = 10
			knockback_amount = 100
			paths = 2
			attack_size = 1.0 * (1 + player.spell_size)
			attack_speed = 5.0 * (1-player.spell_cooldown)
		3:
			hp = 9999
			speed = 200
			damage = 10
			knockback_amount = 100
			paths = 3
			attack_size = 1.0 * (1 + player.spell_size)
			attack_speed = 5.0 * (1-player.spell_cooldown)
		4:
			hp = 9999
			speed = 200
			damage = 15
			knockback_amount = 120
			paths = 1
			attack_size = 1.0 * (1 + player.spell_size)
			attack_speed = 5.0 * (1-player.spell_cooldown)
	
	scale = Vector2(0.8,0.8) * attack_size
	attackTimer.wait_time = attack_speed
	
func _physics_process(delta):
	if target_array.size() > 0:      # set target
		position += angle*speed*delta  # Position direction based on angle
	else:
		var player_angle = global_position.direction_to(reset_pos)    # get javelin to float back to player
		var distance_dif = global_position - player.global_position
		var return_speed = 20   # regular return speed
		if abs(distance_dif.x) > 500 or abs(distance_dif.y) > 500:  # if distance over 500 increase return speed
			return_speed = 100   # far return speed
		position += player_angle*return_speed*delta  # return speed used to speed up
		rotation = global_position.direction_to(player.global_position).angle() + deg_to_rad(135)

func add_paths():
	snd_attack.play()
	emit_signal("remove_from_array",self)    # Remove from hitonce hurtbox
	target_array.clear()     # clear array used to store targets
	var counter = 0
	while counter < paths:     # add target for every path we want to add
		var new_path = player.get_random_target()    # target gotten from player script
		target_array.append(new_path)     # add to the array of targets
		counter += 1   # close loop by increasing counter
	enable_attack(true)
	target = target_array[0] # Set target to first value in array
	process_path()
	
	
func process_path():
	angle = global_position.direction_to(target) # Gets angle between javelin position and target
	changeDirectionTimer.start()
	var tween = create_tween()
	var new_rotation_degrees = angle.angle() + deg_to_rad(135)
	tween.tween_property(self,"rotation",new_rotation_degrees,0.25).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	

func enable_attack(atk = true):
	if atk:
		collision.call_deferred("set","disabled", false)    # Activate collision if argument is true
		sprite.texture = spr_jav_atk
	else:
		collision.call_deferred("set","disabled", true)  # Disable collision if argument is true
		sprite.texture = spr_jav_reg

func _on_attack_timer_timeout():
	add_paths()


func _on_change_direction_timeout():
	if target_array.size() > 0:  # check if target_array has any value
		target_array.remove_at(0)  # removes first target from array
		if target_array.size() > 0:  # check if target_array has any value
			target = target_array[0]  # set target to first value in array
			process_path()  # set the new angle and rotate javelin to new target
			snd_attack.play()
			emit_signal("remove_from_array",self)  # let javelin hit hitonce hurtbox again
		else:
			changeDirectionTimer.stop() # stop change timer since no more targets
			attackTimer.start()   # start attack timer to get new targets
			enable_attack(false)  # disable if no more targets
	else:
		changeDirectionTimer.stop() # stop change timer since no more targets
		attackTimer.start()   # start attack timer to get new targets
		enable_attack(false)


func _on_reset_pos_timer_timeout():
	var choose_direction = randi() % 4
	reset_pos = player.global_position
	match choose_direction:            # Chooses random position 50 pixels near player
		0:
			reset_pos.x += 50
		1:
			reset_pos.x -= 50
		2:
			reset_pos.y += 50
		3:
			reset_pos.y -= 50