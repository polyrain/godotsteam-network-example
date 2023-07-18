extends KinematicBody2D

# Updates when loaded
var steam_id = 0

func _ready():
	Networking.connect("move_message", self, "_update_Position")
	
func _update_Position(payload):
	
	if payload['player'] != steam_id:
		return
		
	position.x = payload['x_pos']
	position.y = payload['y_pos']
