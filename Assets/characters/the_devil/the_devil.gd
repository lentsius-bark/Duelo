extends Spatial

signal waiting
signal super_action
signal hide_time
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

#when our hero does sometyhing awesome
func _on_super_action_executed(super_power):
	emit_signal("super_action",super_power)

#when one needs to wait
func _on_waiting_change(time):
	emit_signal("waiting",time)


func _on_hide_time():
	emit_signal("hide_time")
