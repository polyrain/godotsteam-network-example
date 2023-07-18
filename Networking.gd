extends Node

# Define signals for your different kinds of messages here
signal movement(payload)
signal start_game(payload)

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

# Read in messages, and emit the signal type
# As messages come in, we can apply basic authentication on structure etc 
# Before emitting a signal with the body of the message for those interested
# To unpack/do something useful with
func read_p2p_messages():
	var msgs = Steam.receiveMessagesOnChannel(0, 16)
	for msg in msgs:
		#print("[DEBUG] Raw Steam msg %s" % msg)
		var decoded_msg = bytes2var(msg['payload'])
		#print("[DEBUG] Decoded Steam msg %s" % decoded_msg)
		if 'type' in decoded_msg:
			# emit a signal with the same name as the type and let subscribers parse it
			emit_signal(decoded_msg['type'], decoded_msg)
