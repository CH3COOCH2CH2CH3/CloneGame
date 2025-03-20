extends CharacterBody2D

const SPEED = 230.0
const JUMP_VELOCITY = -400.0

enum State { IDLE, RUN, ATTACK }
var state = State.IDLE

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var anim = $Node2D/AnimatedSprite2D
@onready var player = get_node("../CharacterBody2D")

var atk_anims = ["atk", "atk2", "atk3"]

func _ready() -> void:
	randomize()
	anim.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
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
			if not (anim.animation in atk_anims):
				anim.play(atk_anims[randi() % atk_anims.size()])

	move_and_slide()

func _on_animation_finished() -> void:
	if state == State.ATTACK:
		state = State.RUN
