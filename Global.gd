extends Node
onready var PLAYER = preload("res://NetworkPlayer.tscn")
const PACKET_READ_LIMIT: int = 32
var STEAM_ID: int = 0
var HOST_ID: int = 0
var STEAM_USERNAME: String = ""
var LOBBY_ID: int = 0
var LOBBY_MEMBERS: Dictionary = {}
var DATA
var LOBBY_VOTE_KICK: bool = false
var LOBBY_MAX_MEMBERS: int = 10
enum LOBBY_AVAILABILITY {PRIVATE, FRIENDS, PUBLIC, INVISIBLE}
var IS_ONLINE
var IS_OWNED
var SERVER: bool = false # Are we the host?
var in_session: bool = false

func _ready() -> void:
	_initialize_Steam()
	

func _initialize_Steam() -> void:
	var INIT: Dictionary = Steam.steamInit()
	print("Did Steam initialize?: "+str(INIT))
	IS_ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	IS_OWNED = Steam.isSubscribed()
	if IS_OWNED == false:
		print("User does not own this game")
		get_tree().quit()

func _process(_delta: float) -> void:
	Steam.run_callbacks()
	if LOBBY_ID > 0:
		Networking.read_p2p_messages()
		
func start_game():
	if STEAM_ID == HOST_ID:
		SERVER = true
		in_session = true
		get_tree().change_scene("res://World.tscn")
		var packet = {'type': 'start_game', 'game_started': true}
		Networking.send_p2p_message('', packet)
		spawn_players()
	else:
		in_session = true
		SERVER = false

func spawn_players():
	print(LOBBY_MEMBERS)
	for MEMBER in LOBBY_MEMBERS.keys():
		if MEMBER == STEAM_ID or LOBBY_MEMBERS[MEMBER].get('ply_obj', null):
			continue # skip ourselves or skip if we already have a ply obj
		var fake_player = instance_node_at_location(PLAYER, self, Vector2(0,0))
		print('Instanced player')
		LOBBY_MEMBERS[MEMBER]['ply_obj'] = fake_player
		fake_player.steam_id = MEMBER
		
	
		
		
"""
Instance a node at a specific global position. Used to spawn players.
Returns a reference to the new node. 
"""
func instance_node_at_location(node: Object, parent: Object, location: Vector2) -> Object:
	var node_instance = instance_node(node, parent)
	node_instance.position = location
	
	return node_instance

"""
Instance a node as a child of parent. Return a reference to the new child.
"""
func instance_node(node: Object, parent: Object) -> Object:
	var node_instance = node.instance()
	parent.add_child(node_instance)
	return node_instance
