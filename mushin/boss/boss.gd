extends CharacterBody2D

const SPEED = 230.0
const JUMP_VELOCITY = -400.0

enum State { IDLE, RUN, ATTACK, HURT }
var state = State.IDLE

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var anim = $Node2D/AnimatedSprite2D
@onready var player = get_node("../CharacterBody2D")

var atk_anims = ["atk", "atk2", "atk3"]

var hp = 10
var is_attacking = false
var is_dead = false
var previous_state = State.IDLE
var hit_count = 0
var is_invincible = false
var invincible_timer = 0.0

@onready var attack_area = $Area2D
@onready var attack_shape = $Area2D/CollisionShape2D
@onready var hp_label = $HPLabel
func _ready() -> void:
	randomize()
	anim.animation_finished.connect(_on_animation_finished)
	attack_shape.disabled = true
	update_hp_label()
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			is_invincible = false

	velocity.y += gravity * delta
	var distance_to_player = position.distance_to(player.position)
	var direction_x = sign(player.position.x - position.x)
	$Node2D.scale.x = 1 if direction_x > 0 else -1

	match state:
		State.IDLE:
			velocity.x = 0
			if anim.animation != "idle":
				anim.play("idle")
			if distance_to_player < 500:
				state = State.RUN

		State.RUN:
			velocity.x = direction_x * SPEED
			if anim.animation != "run":
				anim.play("run")
			if distance_to_player < 80:
				state = State.ATTACK
			elif distance_to_player >= 500:
				state = State.IDLE

			if is_on_floor():
				if position.y + 20 < player.position.y and abs(position.x - player.position.x) < 30:
					velocity.y = JUMP_VELOCITY
					anim.play("jump")
				elif player.position.y < position.y and distance_to_player < 300:
					velocity.y = JUMP_VELOCITY
					anim.play("jump")

		State.ATTACK:
			velocity.x = 0
			is_attacking = true
			attack_shape.disabled = false
			if not (anim.animation in atk_anims):
				anim.play(atk_anims[randi() % atk_anims.size()])

		State.HURT:
			velocity.x = 0  # Dừng di chuyển ngang khi bị thương

	move_and_slide()

func _on_animation_finished() -> void:
	if state == State.ATTACK:
		is_attacking = false
		attack_shape.disabled = true
		state = State.RUN
	elif state == State.HURT:
		if not is_invincible:
			state = previous_state
		else:
			state = State.RUN  # Chuyển sang RUN khi bất tử

func _on_area_2d_body_entered(body: Node) -> void:
	if is_attacking and body.name == "CharacterBody2D":
		await get_tree().create_timer(0.2).timeout
		if is_attacking:
			body.apply_damage(1)
			print("Boss collision with: ", body.name)

func apply_damage(damage: int) -> void:
	if is_dead or is_invincible:
		return

	hp -= damage
	hit_count += 1
	print("boss hp: ", hp, " hit_count: ", hit_count)
	update_hp_label()
	if hp <= 0:
		hp = 0
		is_dead = true
		anim.play("dead")
		set_physics_process(false)
		$CollisionShape2D.disabled = true
	else:
		previous_state = state
		state = State.HURT
		anim.play("hurt")
		if hit_count >= 3:
			is_invincible = true
			invincible_timer = 2.0
			hit_count = 0
			
			
func update_hp_label() -> void:
	hp_label.text = str(hp)
