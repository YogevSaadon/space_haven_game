# /scripts/ui/DamageNumber.gd  (Godot 4.3-safe)
extends Node2D
class_name DamageNumber

signal label_finished

const HOLD_TIME   : float = 0.08
const FADE_TIME   : float = 0.40
const FLOAT_SPEED : float = 30.0
const COUNT_SPEED : float = 60.0

var total_damage      : float = 0.0
var displayed_damage  : float = 0.0
var time_since_hit    : float = 0.0
var fading            : bool  = false
var tween             : Tween = null
var is_detached       : bool  = false

var crit_color : Color = Color(1, 0.3, 0.3)
var norm_color : Color = Color(1, 1, 1)

var label : Label                       # declared here, built in _ready()

# ─────────────────────────────
func _ready() -> void:
	label = Label.new()
	add_child(label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	label.text = ""
	_center_label()

func add_damage(amount: float, is_crit: bool) -> void:
	total_damage += amount
	label.modulate = crit_color if is_crit else norm_color

	#  if this is the first hit, jump the counter immediately
	if displayed_damage == 0.0:
		displayed_damage = total_damage          
		label.text = str(int(displayed_damage))  #
	else:
		label.text = str(int(total_damage))

	_center_label()
	time_since_hit = 0.0

	if fading:
		fading = false
		if tween and tween.is_valid():
			tween.kill()
		modulate.a = 1.0


func _process(delta: float) -> void:
	# smooth count-up
	if displayed_damage < total_damage:
		var step : float = min(COUNT_SPEED * delta,
							   total_damage - displayed_damage)
		displayed_damage += step
		label.text = str(int(displayed_damage))
		_center_label()

	# upward drift
	position.y -= FLOAT_SPEED * delta

	# fade timing
	time_since_hit += delta
	if not fading and time_since_hit >= HOLD_TIME:
		if not is_detached:
			detach()
		else:
			_start_fade()

# ─────────────────────────────
func _center_label() -> void:
	# place label so its center aligns with wrapper’s origin
	var size : Vector2 = label.get_minimum_size()
	label.position = Vector2(-size.x * 0.5, -size.y * 0.5)

func _start_fade() -> void:
	fading = true
	tween  = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_TIME)\
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_fade_done)

func _on_fade_done() -> void:
	emit_signal("label_finished")
	queue_free()

# ─────────────────────────────
func detach() -> void:
	if is_detached:
		return
	is_detached = true

	# Preserve world position
	var gpos : Vector2 = global_position

	# Cache the SceneTree reference **before** we remove ourselves
	var tree : SceneTree = get_tree()

	if get_parent():
		get_parent().remove_child(self)

	# Choose a safe parent for the floating number
	var target_parent : Node = null
	if tree != null:
		target_parent = tree.get_current_scene()
		if target_parent == null:
			target_parent = tree.root
	else:
		# Extremely rare: no SceneTree (tool-run or shutdown) → use ownerless root
		target_parent = get_viewport()

	target_parent.add_child(self)
	global_position = gpos
