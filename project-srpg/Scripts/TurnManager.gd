extends Node

# === Signals ===
signal turn_started(entity: Node)
signal turn_ended(entity: Node)

# === Queues ===
var turn_queue: Array = []
var current_entity: Node = null

# === Registration ===
func register_entity(entity: Node) -> void:
	if not turn_queue.has(entity):
		turn_queue.append(entity)

func unregister_entity(entity: Node) -> void:
	if turn_queue.has(entity):
		turn_queue.erase(entity)

# === Turn Control ===
func start_turn() -> void:
	if turn_queue.size() == 0:
		push_warning("TurnManager: No entities in queue.")
		return

	# Get next entity
	current_entity = turn_queue.pop_front()
	turn_queue.append(current_entity)  # rotate queue

	# Notify the entity
	if current_entity.has_method("on_turn_start"):
		current_entity.on_turn_start()

	emit_signal("turn_started", current_entity)

func end_turn() -> void:
	if current_entity == null:
		return

	if current_entity.has_method("on_turn_end"):
		current_entity.on_turn_end()

	emit_signal("turn_ended", current_entity)

	current_entity = null
	start_turn()
