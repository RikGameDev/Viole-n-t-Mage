extends CharacterBody2D


var movement_speed = 40.0
var hp = 80
var maxhp = 80
var last_movement = Vector2.UP
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

#Attacks
var shadowBolt = preload("res://Player/attack/shadow_bolt.tscn")
var tornado = preload("res://Player/attack/tornado.tscn")
var javelin = preload("res://Player/attack/javelin.tscn")

#AttackNodes
@onready var shadowBoltTimer = get_node("%ShadowBoltTimer")
@onready var shadowBoltAttackTimer = get_node("%ShadowBoltAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var javelinBase = get_node("%JavelinBase")
@onready var healthBar = get_node("%HealthBar")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://Player/GUI/item_container.tscn")


#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

#ShadowBolt
var shadowbolt_ammo = 0
var shadowbolt_baseammo = 0
var shadowbolt_attackspeed = 1.5
var shadowbolt_level = 0

#Tornado
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3
var tornado_level = 0

#Javelin
var javelin_ammo = 0
var javelin_level = 0


#Enemy Related
var enemy_close = []

@onready var animated_sprite_2d = $AnimatedSprite2D


#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var lblTimer = get_node("%lblTimer")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")


#Signal
signal playerdeath



func _ready():
	upgrade_character("shadowbolt1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0) # set health bar at start

func _physics_process(_delta):
	movement()
	

	
func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov, y_mov)
	if mov.x > 0:
		animated_sprite_2d.flip_h = false
	elif mov.x < 0:
		animated_sprite_2d.flip_h = true
		
	if mov != Vector2.ZERO:
		last_movement = mov
		animated_sprite_2d.play("run")
	else:
		velocity = Vector2.ZERO
		animated_sprite_2d.play("idle")
		
	velocity = mov.normalized()*movement_speed
	move_and_slide()
	
	
func attack():
	if shadowbolt_level > 0:
		shadowBoltTimer.wait_time = shadowbolt_attackspeed * (1-spell_cooldown)
		if shadowBoltTimer.is_stopped():
			shadowBoltTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1-spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if javelin_level > 0:
		spawn_javelin()
	
	
func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	healthBar.max_value = maxhp    # set max hp
	healthBar.value = hp  # set current value
	if hp <= 0:
		death()
	



func _on_shadow_bolt_timer_timeout():
	shadowbolt_ammo += shadowbolt_baseammo + additional_attacks
	shadowBoltAttackTimer.start()
	
	



func _on_shadow_bolt_attack_timer_timeout():
	if shadowbolt_ammo > 0:
		var shadowbolt_attack = shadowBolt.instantiate()
		shadowbolt_attack.position = position
		shadowbolt_attack.target = get_random_target()
		shadowbolt_attack.level = shadowbolt_level
		add_child(shadowbolt_attack)
		shadowbolt_ammo -= 1
		if shadowbolt_ammo > 0:
			shadowBoltAttackTimer.start()
		else:
			shadowBoltAttackTimer.stop()
			
func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo + additional_attacks
	tornadoAttackTimer.start()

func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()


func spawn_javelin():
	var get_javelin_total = javelinBase.get_child_count()               # Get total javelins
	var calc_spawns = (javelin_ammo + additional_attacks) - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position # Spawn Javelin
		javelinBase.add_child(javelin_spawn)
		calc_spawns -= 1     # increase counter to exit loop
	#Upgrade Javelin
	var get_javelins = javelinBase.get_children()
	for i in get_javelins:
		if i.has_method("update_javelin"):
			i.update_javelin()


func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP


func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)


func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)




func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)


func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()   # calculate exp needed to level
	collected_experience += gem_exp   # transfer gem_exp to handler variable
	if experience + collected_experience >= exp_required:    # check if level up
		collected_experience -= exp_required-experience   # only take exp that is needed
		experience_level += 1  # actually level up
		experience = 0  # set exp tracking level
		exp_required = calculate_experiencecap()
		levelup()
	else:
		experience += collected_experience  # if not add collected exp to pool
		collected_experience = 0
	
	set_expbar(experience, exp_required) # alter exp bar



func calculate_experiencecap():   # calculate exp function called
	var exp_cap = experience_level
	if experience_level < 20:           
		exp_cap = experience_level*5
	elif experience_level < 40:
		exp_cap = 95 + (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
	return exp_cap

func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value   # adjust GUI

func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level: ",experience_level)  # change text on exp bar to match level
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel, "position", Vector2(220,50),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()   # tween panel to center of screen
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)   # add 3 children to the level panel
		options += 1
	get_tree().paused = true


func upgrade_character(upgrade):
	match upgrade:
		"shadowbolt1":
			shadowbolt_level = 1
			shadowbolt_baseammo += 1
		"shadowbolt2":
			shadowbolt_level = 2
			shadowbolt_baseammo += 1
		"shadowbolt3":
			shadowbolt_level = 3
		"shadowbolt4":
			shadowbolt_level = 4
			shadowbolt_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
	adjust_gui_collection(upgrade)
	attack()
	
	var option_children = upgradeOptions.get_children()
	for i in option_children:   # remove item children v
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false   # reset panel back to normal v
	levelPanel.position = Vector2(800,50)
	get_tree().paused = false
	calculate_experience(0) # calculate if there is any leftover experience

func get_random_item():
	var dblist = []    # empty array to add eligible items
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades:   # Find already collected upgrades
			pass
		elif i in upgrade_options:   # If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item":  # Dont pick food
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0:   # check for prerequisites
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:   # check prerequisites
				if not n in collected_upgrades:
					to_add = false  # if any are missing set to dont add
			if to_add:
				dblist.append(i)   # add item if we have prerequisites
		else:   # if prerequisites null
			dblist.append(i)
	if dblist.size() > 0:  # make sure we have at least 1 item to pick
		var randomitem = dblist.pick_random()  # pick random item
		upgrade_options.append(randomitem)  # make sure we dont add the same item for option 2 or 3
		return randomitem
	else:  # if no eligible items food will default
		return null

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s < 10:
		get_s = str(0,get_s)
	lblTimer.text = str(get_m,":",get_s)

func adjust_gui_collection(upgrade):
	var get_upgraded_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displayname in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)

func death():
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel, "position",Vector2(220,50),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >= 300:
		lblResult.text = "You Win"
		sndVictory.play()
	else:
		lblResult.text = "You Lose"
		sndLose.play()


func _on_btn_menu_click_end():
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")
