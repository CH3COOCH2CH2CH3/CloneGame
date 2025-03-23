extends CharacterBody2D

const SPEED = 220.0
const JUMP_VELOCITY = -400.0
const DASH_SPEED = 400.0
const DASH_DURATION = 0.2
const HURT_DURATION = 0.5        # Tổng thời gian hiệu ứng hurt
const HURT_MIN_OVERRIDE = 0.1    # Ít nhất chạy hurt 0.1s trước khi override
const INVINCIBLE_TIME = 0.5      # Thời gian bất khả chiến khi vừa bị hurt

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var anim = $AnimatedSprite2D
@onready var parry_anim = $AnimatedSprite2D2

var hp = 500
var is_attacking = false
var is_parrying = false
var is_dashing = false
var is_dead = false         # Trạng thái chết
var is_hurt = false         # Hiệu ứng hurt đang chạy
var dash_timer = 0.0
var hurt_timer = 0.0        # Thời gian còn lại của hiệu ứng hurt
var invincible_timer = 0.0  # Thời gian không nhận thêm damage sau khi hurt

@onready var attack_area = $Area2D
@onready var attack_shape = $Area2D/CollisionShape2D
@onready var hp_label = $Hp

func _ready() -> void:
	anim.animation_finished.connect(_on_main_animation_finished)
	parry_anim.animation_finished.connect(_on_parry_animation_finished)
	parry_anim.visible = false
	attack_area.body_entered.connect(_on_area_2d_body_entered)
	attack_shape.disabled = true
	update_hp_label()

func _physics_process(delta: float) -> void:
	if is_dead:
		return  # Nếu đã chết thì không xử lý gì

	# Giảm dần thời gian bất khả chiến nếu đang trong thời gian invincible
	if invincible_timer > 0:
		invincible_timer -= delta

	# Nếu đang hurt, cập nhật hurt_timer
	if is_hurt:
		if hurt_timer > 0:
			hurt_timer -= delta
		# Cho phép override hurt khi đã chạy tối thiểu HURT_MIN_OVERRIDE
		if hurt_timer <= HURT_MIN_OVERRIDE and (
			Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or
			Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("jump") or
			Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("parry")
		):
			is_hurt = false
			hurt_timer = 0

	# Luôn cập nhật trọng lực
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Nếu không bị hurt, xử lý các input và animation
	if not is_hurt:
		# JUMP
		if Input.is_action_just_pressed("jump") and is_on_floor() and not is_parrying and not is_dashing:
			velocity.y = JUMP_VELOCITY

		# DASH
		if Input.is_action_just_pressed("dash") and not is_attacking and not is_parrying and not is_dashing:
			is_dashing = true
			dash_timer = DASH_DURATION
			anim.play("dash")
			var dash_direction = Input.get_axis("move_left", "move_right")
			# Nếu trục = 0, lấy hướng dựa trên flip_h
			if dash_direction == 0:
				dash_direction = -1 if anim.flip_h else 1
			velocity.x = dash_direction * DASH_SPEED

		if is_dashing:
			dash_timer -= delta
			if dash_timer <= 0:
				is_dashing = false

		# PARRY
		elif Input.is_action_just_pressed("parry") and not is_attacking and not is_parrying:
			is_parrying = true
			anim.stop()
			anim.visible = false
			parry_anim.flip_h = anim.flip_h
			parry_anim.visible = true
			parry_anim.play("parry")
			# Khi nhấn parry, nhân vật được bất tử trong 1 giây
			invincible_timer = 1.0

		# DI CHUYỂN TRÁI/PHẢI + ANIMATION
		elif not is_attacking and not is_parrying:
			var direction = Input.get_axis("move_left", "move_right")
			if is_dashing:
				# Nếu đang dash, có thể bỏ qua hoặc tinh chỉnh
				pass
			elif direction != 0:
				anim.flip_h = (direction < 0)
				velocity.x = direction * SPEED
				if is_on_floor():
					anim.play("run")
				else:
					anim.play("jump")
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				if is_on_floor():
					anim.play("idle")
				else:
					anim.play("jump")

		# ATTACK
		if Input.is_action_just_pressed("attack") and not is_attacking and not is_parrying and not is_dashing:
			is_attacking = true
			attack_shape.disabled = false
			anim.play("attack")
	else:
		# Nếu đang hurt, có thể vẫn cập nhật velocity
		# nhưng không gọi anim.play() để giữ nguyên animation "hurt"
		pass

	move_and_slide()

func _on_main_animation_finished() -> void:
	if anim.animation == "attack":
		do_attack()
		is_attacking = false
		attack_shape.disabled = true  # Tắt vùng tấn công
	elif anim.animation == "hurt":
		# Khi hurt animation kết thúc, reset trạng thái hurt
		is_hurt = false
		hurt_timer = 0

func _on_parry_animation_finished() -> void:
	if parry_anim.animation == "parry":
		is_parrying = false
		parry_anim.stop()
		parry_anim.visible = false
		anim.visible = true

func do_attack():
	print("Attack executed!")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if is_attacking and body.name == "Boss":
		body.apply_damage(1)
		print("Collision with: ", body.name)

func apply_damage(damage: int) -> void:
	# Nếu đã chết hoặc đang bất khả chiến thì bỏ qua
	if is_dead or invincible_timer > 0:
		return

	hp -= damage
	print("player hp: ", hp)
	update_hp_label()
	if hp <= 0:
		hp = 0
		is_dead = true
		anim.play("death")
		set_physics_process(false)
		$CollisionShape2D.disabled = true
	else:
		# Reset attacking state khi bị hurt
		is_attacking = false
		attack_shape.disabled = true
		if not is_hurt:
			is_hurt = true
			anim.play("hurt")
			hurt_timer = HURT_DURATION
			invincible_timer = INVINCIBLE_TIME

func update_hp_label() -> void:
	hp_label.text = str(hp)
