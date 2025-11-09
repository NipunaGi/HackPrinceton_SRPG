# Enemy Script (Attached to the node hit by the raycast)
extends CharacterBody3D

@export var health: int = 15

const SPEED = 5.0
func _ready():
	add_to_group("Enemy")
	
func _process(delta: float) -> void:
	if health <= 0:
		print("Enemy destroyed!")
		queue_free()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
# Optional: Preferred method for applying damage
func take_damage(amount: int):
	health -= amount
