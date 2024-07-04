extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$AnimationPlayer.play("explode")
	
	var tween = create_tween()
	tween.tween_property(self,"modulate",Color8(108,49,130,255),0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.play()

func _on_animation_player_animation_finished(anim_name):
	queue_free()
