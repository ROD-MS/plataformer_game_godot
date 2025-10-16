extends CharacterBody2D
class_name Bullet

@export var SPEED := 1000.0

var player: Player = null

var damage := 0.0
var knockback := 0.0
var stun_time := 0.0

var direction = 0

func _physics_process(delta: float) -> void:
	velocity = Vector2(SPEED, 0).rotated(rotation)
	
	move_and_slide()


func _on_attack_collision_body_entered(body: Node2D) -> void:
	if body is Enemy:
		var enemy: Enemy = body
		var attack: Attack = Attack.new()
		attack.damage = damage
		attack.knockback = knockback
		attack.stun_time = stun_time
		enemy.damage(attack, player)
		queue_free()
