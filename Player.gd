extends KinematicBody2D
 
const MOVE_SPEED = 500
const JUMP_FORCE = 1000
const GRAVITY = 50
const MAX_FALL_SPEED = 1000
 
onready var anim_player = $AnimationPlayer
onready var sprite = $Sprite
 
var y_velo = 0
var facing_right = false

# Determines if this instance of a player is "real" or not
var is_puppet: bool = false
# Default the steam_id of this player to be the hosts
var steam_id: int = Global.STEAM_ID 

# Where we WANT to move to if we're a puppet
var target_x: float = 0.0
var target_y: float = 0.0
var lerp_time = 0
var duration = 0.1  # We expect a new packet every 100ms

func _ready():
	Networking.connect("movement", self, "_on_Movement_Update")
 
func _physics_process(delta):
	if is_puppet:
		if lerp_time < duration:
			lerp_time += delta
			position.x = lerp(position.x, target_x, lerp_time / duration)
			position.y = lerp(position.y, target_y, lerp_time / duration)
		else:
			lerp_time = 0 # Reset the lerp timer since new packet is in
		return
	var move_dir = 0
	if Input.is_action_pressed("move_right"):
		move_dir += 1
	if Input.is_action_pressed("move_left"):
		move_dir -= 1
	move_and_slide(Vector2(move_dir * MOVE_SPEED, y_velo), Vector2(0, -1))
 
	var grounded = is_on_floor()
	y_velo += GRAVITY
	if grounded and Input.is_action_just_pressed("jump"):
		y_velo = -JUMP_FORCE
	if grounded and y_velo >= 5:
		y_velo = 5
	if y_velo > MAX_FALL_SPEED:
		y_velo = MAX_FALL_SPEED
 
	if facing_right and move_dir < 0:
		flip()
	if !facing_right and move_dir > 0:
		flip()
 
	if grounded:
		if move_dir == 0:
			play_anim("idle")
		else:
			play_anim("walk")
	else:
		play_anim("jump")
 
func flip():
	facing_right = !facing_right
	sprite.flip_h = !sprite.flip_h
 
func play_anim(anim_name):
	if anim_player.is_playing() and anim_player.current_animation == anim_name:
		return
	anim_player.play(anim_name)

# Every 100ms this fires and sends a message with the position of this player
func _on_PacketTimeout_timeout():
	var player_pos_data: Dictionary = {}
	player_pos_data['type'] = 'movement'
	player_pos_data['x_pos'] = position.x
	player_pos_data['y_pos'] = position.y
	player_pos_data['player'] = Global.STEAM_ID
	Networking.send_p2p_message('', player_pos_data)
	
# Responds to movement messages being received, check if this is for this player
# and apply
func _on_Movement_Update(payload):
	if payload['player'] != steam_id:
		return
	if not 'x_pos' in payload or not 'y_pos' in payload or not 'vel' in payload:
		print('Invalid movement message!')
		return 
	
	target_x = payload['x_pos']
	target_y = payload['y_pos']
	
		
