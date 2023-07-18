extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	Steam.connect("lobby_created", self, "_on_Lobby_Created")
	Steam.connect("lobby_joined", self, "_on_Lobby_Joined")
	Steam.connect("network_messages_session_request", self, "on_network_messages_session_request")

	# Check for command line arguments
	_check_Command_Line()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

############################
# Godot Steam example code #
############################
# When a lobby is joined
func _on_Lobby_Joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining succeed, this will be 1
	if response == 1:
		# Set this lobby ID as your lobby ID
		Global.LOBBY_ID = lobby_id		
		_get_Lobby_Members()

		var owner_id = Steam.getLobbyOwner(Global.LOBBY_ID)
		Steam.addIdentity('host')
		Steam.setIdentitySteamID('host', owner_id)
		Networking.send_p2p_message('host', {'msg': "Hello!"})

func _create_Lobby() -> void:
	# Make sure a lobby is not already set
	if Global.LOBBY_ID == 0:
		Steam.createLobby(Global.LOBBY_AVAILABILITY.PUBLIC, Global.LOBBY_MAX_MEMBERS)
		
		
func on_network_messages_session_request(identity: String):
	var id = identity.split(':', true)[1]
	Steam.addIdentity(identity)
	Steam.setIdentitySteamID(identity, int(id))
	Steam.acceptSessionWithUser(identity)
	
func _check_Command_Line() -> void:
	var ARGUMENTS: Array = OS.get_cmdline_args()

	# There are arguments to process
	if ARGUMENTS.size() > 0:

		# A Steam connection argument exists
		if ARGUMENTS[0] == "+connect_lobby":

			# Lobby invite exists so try to connect to it
			if int(ARGUMENTS[1]) > 0:

				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				print("CMD Line Lobby ID: "+str(ARGUMENTS[1]))
				_join_Lobby(int(ARGUMENTS[1]))

func _get_Lobby_Members() -> void:
	# Clear your previous lobby list
	Global.LOBBY_MEMBERS.clear()

	# Get the number of members from this lobby from Steam
	var MEMBERS: int = Steam.getNumLobbyMembers(Global.LOBBY_ID)

	# Get the data of these players from Steam
	for MEMBER in range(0, MEMBERS):
		# Get the member's Steam ID
		var MEMBER_STEAM_ID: int = Steam.getLobbyMemberByIndex(Global.LOBBY_ID, MEMBER)

		# Get the member's Steam name
		var MEMBER_STEAM_NAME: String = Steam.getFriendPersonaName(MEMBER_STEAM_ID)

		# Add them to the list
		Global.LOBBY_MEMBERS.append({"steam_id":MEMBER_STEAM_ID, "steam_name":MEMBER_STEAM_NAME})

func _join_Lobby(lobby_id: int) -> void:
	print("Attempting to join lobby "+str(lobby_id)+"...")

	# Clear any previous lobby members lists, if you were in a previous lobby
	Global.LOBBY_MEMBERS.clear()

	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)
	
func _on_Lobby_Created(connect: int, lobby_id: int) -> void:
	if connect == 1:
		# Set the lobby ID
		Global.LOBBY_ID = lobby_id
		print("Created a lobby: "+str(Global.LOBBY_ID))

		# Set this lobby as joinable, just in case, though this should be done by default
		Steam.setLobbyJoinable(Global.LOBBY_ID, true)

		# Set some lobby data
		Steam.setLobbyData(lobby_id, "name", "Gramps' Lobby")
		Steam.setLobbyData(lobby_id, "mode", "GodotSteam test")

		# Allow P2P connections to fallback to being relayed through Steam if needed
		var RELAY: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: "+str(RELAY))
