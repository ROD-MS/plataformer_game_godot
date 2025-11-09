extends CharacterBody2D
class_name Enemy

@onready var knockback_timer: Timer = $knockback_timer
@onready var repeat_move_timer: Timer = $repeat_move_timer
@onready var charge_attack_timer: Timer = $charge_attack
@onready var animation: AnimatedSprite2D = $animation

@export var max_health := 20.0

@export_category("Move sets")
@export var SPEED := 100.0
@export var follow_player := false # If active, the enemy will follow the player when they are near 

@export var repeat_move := false # If active, the enemy will move like a path and stop just to attack player
@export var time_to_change_move := 2.0 # This it used just in repeat_move

@export var idle_moves := true # If active, the enemy will be stopped and just attack and player come to it

@export_category("Attacks")
@export var DAMAGE := 5.0
@export var KNOCKBACK := 0.0
var STUN_TIME := 0.0
@export var charge_attack := 1.0 # Time to attack

var health: float
var knockback_duration := 0.0
var knockback := Vector2.ZERO

var player: Player = null
var direction := 1
var detected := false
var can_attack := false
var attack := false
var attacked := false
var hitted := false

func _ready() -> void:
	for child in get_owner().get_children():
		if child is Player:
			player = child
			break
			
	health = max_health
	
	repeat_move_timer.start(time_to_change_move)

func _physics_process(delta: float) -> void:

		
	if knockback_timer.time_left <= 0.0:
		moves_set(delta)

	if not is_on_floor():
		velocity += get_gravity() * delta

	animation_sysyem()

	move_and_slide()


	
func moves_set(delta: float):
	if follow_player:
		if detected:
			var direction = sign(player.global_position.x - global_position.x)
			velocity.x = direction * SPEED
		else:
			velocity.x = 0
			
		if can_attack:
			if charge_attack_timer.is_stopped():
				charge_attack_timer.start(charge_attack)
			
			if attack and !attacked:
				var _attack: Attack = Attack.new()
				_attack.damage = DAMAGE
				_attack.knockback = KNOCKBACK
				player.damage(_attack, self)
				attacked = true
				
	elif repeat_move:
		if repeat_move_timer.time_left <= 0.0:
			direction = -direction
			repeat_move_timer.start(time_to_change_move)
		
		if can_attack:
			repeat_move_timer.paused = true
			if charge_attack_timer.is_stopped():
				charge_attack_timer.start(charge_attack)
			
			if attack and !attacked:
				var _attack: Attack = Attack.new()
				_attack.damage = DAMAGE
				_attack.knockback = KNOCKBACK
				player.damage(_attack, self)
				attacked = true
				
			velocity.x = 0
				
		elif !can_attack and charge_attack_timer.time_left <= 0.0:
			repeat_move_timer.paused = false
			velocity.x = direction * SPEED
		
	elif idle_moves:
		if detected:
			if can_attack:
				if charge_attack_timer.is_stopped():
					charge_attack_timer.start(charge_attack)
				
				if attack and !attacked:
					var _attack: Attack = Attack.new()
					_attack.damage = DAMAGE
					_attack.knockback = KNOCKBACK
					player.damage(_attack, self)
					attacked = true
	
func animation_sysyem():
	if !hitted:
		if velocity == Vector2.ZERO and !attack:
			animation.play("idle")
		else:
			if velocity.x != 0 and !attack:
				animation.play("walk")
	
		if attack and attacked:
			animation.play("attack")
			await animation.animation_finished
			attacked = false
			attack = false
			
	if hitted:
		animation.play("hit")
		await animation.animation_finished
		hitted = false
		
	
func damage(attack: Attack, _player: Player):
	hitted = true
	health -= attack.damage
	
	# Knockback
	var knockback_direction = -(_player.global_position - global_position).normalized()
	knockback = knockback_direction * attack.knockback
	
	knockback_timer.start(knockback_duration)
	
	velocity = knockback
	
	if health <= 0:
		queue_free()

	
func _on_charge_attack_timeout() -> void:
	if can_attack:
		attack = true

# TO FOLLOW PLAYER
func _on_detect_player_body_entered(body: Node2D) -> void:
	if body is Player:
		detected = true

func _on_detect_player_body_exited(body: Node2D) -> void:
	if body is Player:
		detected = false

# TO ATTACK
func _on_player_near_body_entered(body: Node2D) -> void:
	if body is Player:
		can_attack = true

func _on_player_near_body_exited(body: Node2D) -> void:
	if body is Player:
		can_attack = false


func _on_knockback_timer_timeout() -> void:
	velocity = Vector2.ZERO
