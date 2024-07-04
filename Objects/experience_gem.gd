extends Area2D

@export var experience = 1

var spr_green = preload("res://Experience coin.png")
var spr_blue = preload("res://Experience coin 2.png")
var spr_red = preload("res://Experience coin 3.png")

var target = null
var speed = -1   # created bounce away effect before coin comes to player

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var sound = $snd_collected


func _ready():
	if experience < 5:
		return
	elif experience < 25:
		sprite.texture = spr_blue
	else:
		sprite.texture = spr_red


func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 2*delta   # increases movement speed towards player

func collect():
	sound.play()
	collision.call_deferred("set", "disabled",true)
	sprite.visible = false   # removes gem visually only so sound can fully play out.
	return experience


func _on_snd_collected_finished():
	queue_free()   # actually deletes coin
