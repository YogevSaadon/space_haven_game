# scripts/actors/Actor.gd
extends Node2D
class_name Actor

# ========================
# EXPORTS (Configurable Stats)
# ========================
@export var max_health: int = 100
@export var health: int = 100
@export var max_shield: int = 0
@export var shield: int = 0
@export var speed: float = 0.0
@export var shield_recharge_rate: float = 0.0

# ========================
# INTERNAL STATE
# ========================
var velocity: Vector2 = Vector2.ZERO

# ========================
# MOVEMENT + SHIELD
# ========================
func move(delta: float) -> void:
	# Default movement for Node2D actors
	position += velocity * delta

func recharge_shield(delta: float) -> void:
	if shield < max_shield:
		shield = min(shield + shield_recharge_rate * delta, max_shield)

# ========================
# DAMAGE + DEATH
# ========================
func take_damage(amount: int) -> void:
	if shield > 0:
		shield -= amount
		if shield < 0:
			health += shield  # shield is negative, subtracts from health
			shield = 0
	else:
		health -= amount

	if health <= 0:
		destroy()

func destroy() -> void:
	on_death()
	queue_free()

func on_death() -> void:
	pass

# ========================
# GETTERS
# ========================
func get_actor_stats() -> Dictionary:
	return {
		"max_hp": max_health,
		"hp": health,
		"max_shield": max_shield,
		"shield": shield,
		"speed": speed,
		"shield_recharge_rate": shield_recharge_rate,
	}
