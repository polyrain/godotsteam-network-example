extends Node

# Define signals for your different kinds of messages here
signal move_message(payload)
signal die_message(player)

# Mapping of message 'type' to signal to emit
var signal_mappings: Dictionary = {}

func _init():
	register_callback('die', 'die_message_handler')
	register_callback('start_game', 'start_message_handler')

# Send a msg to a user. Specify the intended target by passing in their Identity reference name
func send_p2p_message(target, data):
	var PACKET_DATA: PoolByteArray = []
	PACKET_DATA.append_array(var2bytes(data))
	if target == "":
		for identity in Steam.getIdentities():
			if Steam.isIdentityInvalid(identity['reference_name']):
				continue
			if identity['reference_name'] != "steamid:"+str(Global.STEAM_ID) and not (Global.SERVER and identity['reference_name'] == 'host'): # Don't send to ourselves
				if not Steam.sendMessageToUser(identity['reference_name'], PACKET_DATA, 8, 0) == Steam.RESULT_OK:
					print("Failed to send a packet!")
	else:
		Steam.sendMessageToUser(target, PACKET_DATA, 8, 0)

# Read in messages and try and call the appropriate handler function
func read_p2p_messages():
	var msgs = Steam.receiveMessagesOnChannel(0, 16)
	for msg in msgs:
		#print("[DEBUG] Raw Steam msg %s" % msg)
		var decoded_msg = bytes2var(msg['payload'])
		#print("[DEBUG] Decoded Steam msg %s" % decoded_msg)
		if 'type' in decoded_msg and signal_mappings.get(decoded_msg['type'], false):
			funcref(self, signal_mappings[ decoded_msg['type'] ]).call_func(decoded_msg)
			# Alternatively, you could emit a signal with the same name as the type and let subscribers parse it
			emit_signal(decoded_msg['type'], decoded_msg)


# Put these in the map
func register_callback(message_type: String, function_name: String) -> void:
	signal_mappings[message_type] = function_name

# Format is {x: ?, y: ?}
func movement_message_handler(payload: Dictionary):
	if not 'x_pos' in payload or not 'y_pos' in payload:
		print('Invalid movement message!')
		return 
	
	emit_signal("move_message", payload.x_pos, payload.y_pos, payload.player)
	
func die_message_handler(payload: Dictionary):
	if not 'player' in payload:
		return
	emit_signal("die_message", payload.player)
	
func start_message_handler(payload: Dictionary):
	if not 'game_started' in payload:
		print("Invalid game start packet!")
		return
	Global.start_game()
