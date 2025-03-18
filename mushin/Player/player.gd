extends CharacterBody2D

const SPEED = 220.0
const JUMP_VELOCITY = -400.0

# Hằng số dash
const DASH_SPEED = 400.0
const DASH_DURATION = 0.2

var gravity = ProjectSettings.get_setting("physical/2d/default_gravity")

@onready var anim = $AnimatedSprite2D
@onready var parry_anim = $AnimatedSprite2D2

var is_attacking = false
var is_parrying = false
var is_dashing = false
var dash_timer = 0.0

func _ready() -> void:
	anim.animation_finished.connect(_on_main_animation_finished)
	parry_anim.animation_finished.connect(_on_parry_animation_finished)
	parry_anim.visible = false

func _physics_process(delta: float) -> void:
	# 1. Áp dụng trọng lực khi không đứng trên mặt đất
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 2. Nhảy – chỉ cho phép khi không đang parry hoặc dash
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_parrying and not is_dashing:
		velocity.y = JUMP_VELOCITY

	# 3. Dash: kiểm tra input cho dash
	if Input.is_action_just_pressed("ui_dash") and not is_attacking and not is_parrying and not is_dashing:
		is_dashing = true
		dash_timer = DASH_DURATION
		anim.play("dash")  # Đảm bảo có animation "dash"
		var dash_direction = Input.get_axis("ui_left", "ui_right")
		if dash_direction == 0:
			# Nếu không có input hướng, lấy hướng hiện tại dựa vào flip_h
			dash_direction = -1 if anim.flip_h else 1
		velocity.x = dash_direction * DASH_SPEED

	# 4. Nếu đang dash thì cập nhật dash_timer và bỏ qua xử lý input di chuyển thông thường
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	# 5. Parry: chỉ thực hiện khi không đang attack, dash hoặc parry
	elif Input.is_action_just_pressed("ui_parry") and not is_attacking and not is_parrying:
		is_parrying = true
		anim.stop()
		anim.visible = false
		parry_anim.flip_h = anim.flip_h
		parry_anim.visible = true
		parry_anim.play("parry")
	# 6. Xử lý di chuyển thông thường khi không ở trạng thái attack, parry hay dash
	elif not is_attacking and not is_parrying:
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			anim.flip_h = (direction < 0)
			velocity.x = direction * SPEED
			if is_on_floor():
				anim.play("run")
			else:
				anim.play("jump")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if not is_on_floor():
				anim.play("jump")
			else:
				anim.play("idle")

	# 7. Tấn công: chỉ thực hiện khi không attack, parry hoặc dash
	if Input.is_action_just_pressed("ui_attack") and not is_attacking and not is_parrying and not is_dashing:
		is_attacking = true
		anim.play("attack")
		
	move_and_slide()

func _on_main_animation_finished() -> void:
	if anim.animation == "attack":
		do_attack()
		is_attacking = false

func _on_parry_animation_finished() -> void:
	if parry_anim.animation == "parry":
		is_parrying = false
		parry_anim.stop()
		parry_anim.visible = false
		anim.visible = true

func do_attack():
	print("Attack executed!")
