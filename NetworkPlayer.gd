extends KinematicBody2D

# Updates when loaded
var steam_id = 0

func _ready():
	Networking.connect("move_message", self, "_update_Position")
	
func _update_Position(x_pos, y_pos, player_id):
	if player_id != steam_id:
		return
		
	position.x = x_pos
	position.y = y_pos
