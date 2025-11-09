extends CharacterBody3D

# ----- Enemy Properties -------------
@export var health: int = 15
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
# ------------------------------------

# ----- Enemy Constructor ------------
func _ready():
	add_to_group("Enemy")
# ------------------------------------

# ----- Enemy Turn Helper ------------


# ----- Enemy Turn Function ----------
func enemy_turn():
	#pathfind towards player
	#coinflip attack player
	#end turn	

# ----- Enemy Damage -----------------
func take_damage(amount: int):
	health -= amount
	# Enemy Death Check
	if health <= 0:
		die()

# Die Function
func die():
	print("Enemy destroyed!")
	queue_free()
# -------------------------------------
