extends CharacterBody2D
class_name Player

# FIRST THING: CONFIG THE CONTROLLS

var last_direction: int = 1

# DAMAGES
var knockback := Vector2.ZERO
var knockback_duration := 0.0
@onready var knockback_timer: Timer = $knockback_timer
@onready var stun_timer: Timer = $stun_timer

@onready var dash_timer: Timer = $dash_timer
@onready var melle_attack_collision: Area2D = $melle_attack_collision
@onready var aim_shoot: Node2D = $aim_shoot
@onready var animation: AnimatedSprite2D = $animation

@export var max_health: float = 50.0
var health := 0.0
var hitted := false

@export_category("Player move")
@export var SPEED := 300.0
@export var JUMP_VELOCITY := -400.0

@export_group("Acceleration and deceleration")
@export var has_acceleration := false # If active, the player will have acceleration and deceleration moves
@export var ACCELERATION := 20.0
@export var DECELERATION := 20.0

@export_group("Run and Dash")
@export var has_run := false
@export var RUN_SPEED := 300.0
@export var has_dash := false
var dashing := false
@export var DASH_FORCE := 300.0
@export var DASH_USE_TIMER := 0.5 # It set the time that Player can use dash again

@export_category("Attacks")
var attacked := false
var enemy_detected: Enemy = null

@export_group("Shoot")
@export var has_shoot := false
const BULLET = preload("res://scenes/player/bullet.tscn") # You can change this if you want, but make a node bullet type
# The damage and other configs must be configured in the bullet node
@export var eight_direction := false
@export var aim_in_mouse := false # if eight_direction is active, this variable won't work
# If just "has_shoot" is active, the Player will shoot justa 4 directions (up, down, left, right)
@export var SHOOT_DAMAGE := 5.0
@export var SHOOT_KNOCKBACK := 0.0
@export var SHOOT_STUN_TIME := 0.0 # STUN CANCEL KNOCKBACK

@export_group("Melee")
@export var has_melee = false
@export var MELEE_DAMAGE := 5.0
@export var MELEE_KNOCKBACK := 0.0
@export var MELEE_STUN_TIME := 0.0 # STUN CANCEL KNOCKBACK

func _ready() -> void:
	health = max_health
	dash_timer.wait_time = DASH_USE_TIMER


func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("restart_level"):
		get_tree().reload_current_scene()
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move(delta)
	melee_attack(delta)
	shoot_attack(delta)
	animation_sysyem()

	#print(dash_timer.time_left)
	move_and_slide()
	
func move(delta: float):
	# JUMP
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# BASICS MOVES
	var direction := Input.get_axis("left", "right")
	if direction != 0:
		last_direction = direction
	
	var max_speed := SPEED
	if has_run and Input.is_action_pressed("run"):
		max_speed = SPEED + RUN_SPEED
		
	if direction:
		if has_acceleration:
			velocity.x = move_toward(velocity.x, max_speed * direction , ACCELERATION)
		else:
			velocity.x = direction * max_speed
			
		# DASH
		if has_dash and dash_timer.time_left == 0 and Input.is_action_just_pressed("dash"):
			velocity.x = direction * (max_speed + DASH_FORCE)
			dash_timer.start(DASH_USE_TIMER)
			dashing = true
			
	else:
		if has_acceleration:
			velocity.x = move_toward(velocity.x, 0, DECELERATION)
		else:
			velocity.x = move_toward(velocity.x, 0, max_speed)
			
# MELEE ATTACK SYSTEM
func melee_attack(delta: float):
	# Set attack_collider position
	melle_attack_collision.rotation = deg_to_rad((last_direction * 90) - 90) 
	
	if has_melee == true:
		if Input.is_action_just_pressed("attack") and !attacked and !hitted:
			if enemy_detected != null:
				var attack: Attack = Attack.new()
				attack.damage = MELEE_DAMAGE
				attack.knockback = MELEE_KNOCKBACK
				attack.stun_time = MELEE_STUN_TIME
				enemy_detected.damage(attack, self)
			attacked = true
		
func _on_melle_attack_collision_body_entered(body: Node2D) -> void:
	if body is Enemy:
		enemy_detected = body
		
func _on_melle_attack_collision_body_exited(body: Node2D) -> void:
	enemy_detected = null

# SHOOT ATTACK SYSTEM
func shoot_attack(delta: float):
	if has_shoot:
		if aim_in_mouse:
			aim_shoot.global_position = get_global_mouse_position()
		
		if Input.is_action_just_pressed("shoot"):
			var _bullet = BULLET.instantiate()
			_bullet.global_position = global_position
			_bullet.damage = SHOOT_DAMAGE
			_bullet.knockback = SHOOT_KNOCKBACK
			_bullet.stun_time = SHOOT_STUN_TIME
			_bullet.player = self
			
			if aim_in_mouse:
				_bullet.look_at(aim_shoot.global_position)
			elif eight_direction:
				print("8 dir")
			else:
				_bullet.rotate(deg_to_rad((last_direction * 90) - 90))
				
			get_owner().add_child(_bullet)
			
func damage(attack: Attack, _enemy: Enemy):
	hitted = true
	health -= attack.damage
	
	print(health)
	
	# Knockback
	var knockback_direction = -(_enemy.global_position - global_position).normalized()
	knockback = knockback_direction * attack.knockback
	
	knockback_timer.start(knockback_duration)
	
	velocity = knockback
	
	# Stun time
	var _stun_timer = attack.stun_time
	
	if _stun_timer != 0.0:
		stun_timer.start(_stun_timer)
	
	if health <= 0:
		get_tree().reload_current_scene()
			
func animation_sysyem():
	# FLIP CHARACTER
	if last_direction > 0:
		animation.flip_h = false
	elif last_direction < 0:
		animation.flip_h = true
	
	if !hitted:
		if velocity == Vector2.ZERO and !attacked:
			animation.play("idle")
			
		if dashing:
			animation.play("dash")
			await animation.animation_finished
			dashing = false
			
		elif attacked:
			animation.play("attack")
			await animation.animation_finished
			attacked = false
			
		else:
				
			if velocity.y > 0.0:
				animation.play("fall")
				
			if velocity.y < 0.0 and Input.is_action_just_pressed("jump"):
				animation.play("jump")
				
			elif velocity.x != 0 and is_on_floor():
				if Input.is_action_pressed("run"):
					animation.play("run")
				else:
					animation.play("walk")
			
			if Input.is_action_just_pressed("shoot"):
				animation.play("shoot")
			
	if hitted:
		animation.play("hit")
		await animation.animation_finished
		hitted = false
		
	
