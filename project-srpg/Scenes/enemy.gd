extends CharacterBody3D

## Enemy Properties
@export var health: int = 15
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("Enemy")
	

func take_damage(amount: int):
	health -= amount
	print("Enemy hit! Health remaining: ", health) # TEMP CHECK
	
	if health <= 0:
		die()

func die():
	print("Enemy destroyed!")
	queue_free()
