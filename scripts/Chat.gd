extends Control

var keyboardoffset = 0

var username = "Username"
var msg_num = 0

# Our WebSocketClient instance
var _client = WebSocketClient.new()

func _ready():
	# Android seems to start the keyboard offset at a negative number
	pass

func setup_websocket(url):
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	# This signal is emitted when not using the Multiplayer API every time
	# a full packet is received.
	# Alternatively, you could check get_peer(1).get_available_packets() in a loop.
	_client.connect("data_received", self, "_on_data")

	# Initiate connection to the given URL.
	var err = _client.connect_to_url(url)
	print(err)
	if err != OK:
		return false
	else:
		return true

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the pocket.
	print("Closed, clean: ", was_clean)
	$MainMenu.show()
	$ChatScreen.hide()
	if not was_clean:
		$MainMenu/disconnected.show()

func _connected(proto = ""):
	print("Connected with protocol: ", proto)
	_client.get_peer(1).put_packet((username + " has entered the chat!").to_utf8())

func _on_data():
	var msg = _client.get_peer(1).get_packet().get_string_from_utf8()
	print(msg)
	
	var msgbox: Panel = load("res://MessageBox.tscn").instance()
	msgbox.rect_min_size.y = OS.window_size.y / 10
	var textbox: Label = msgbox.get_children()[0]
	textbox.text = msg
	textbox.get_font("font").size = int(OS.window_size.y / 60)
	msgbox.set_name("msg" + str(msg_num))
	$ChatScreen/ScrollContainer/Messages.add_child(msgbox)
	
	msg_num += 1

func send_message(msg):
	_client.get_peer(1).put_packet(JSON.print({"name": username, "message": msg}).to_utf8())

func _process(delta):
	# moves bottom bar if the onscreen keyboard is active
	if OS.get_virtual_keyboard_height() < 0:
		keyboardoffset = OS.get_virtual_keyboard_height()
	if OS.has_virtual_keyboard():
		var size = OS.get_virtual_keyboard_height()
		$ChatScreen/BottomBar.margin_bottom = -size + keyboardoffset
		$ChatScreen/BottomBar.margin_top = -size + keyboardoffset
		$ChatScreen/ScrollContainer.margin_bottom = -size + keyboardoffset
	else:
		$ChatScreen/BottomBar.margin_bottom = 0
		$ChatScreen/BottomBar.margin_top = 0
	# sets font size to correspond with the resoulution
	$TopBar/Title.get_font("font").size = int(OS.window_size.y / 17)
	$ChatScreen/BottomBar/MessageField.get_font("font").size = int(OS.window_size.y / 62)
	$MainMenu/Username.get_font("font").size = int(OS.window_size.y / 62)
	$MainMenu/JoinButton.get_font("font").size = int(OS.window_size.y / 62)
	_client.poll()
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		escape()

func escape():
	if $ChatScreen.visible:
		_client.disconnect_from_host()
		$MainMenu.show()
		$ChatScreen.hide()
	else:
		get_tree().quit()

func _on_SendButton_pressed():
	send_message($ChatScreen/BottomBar/MessageField.text)

func _on_JoinButton_pressed():
	if setup_websocket($MainMenu/Hostname.text):
		$MainMenu/error.hide()
		$ChatScreen.show()
		$MainMenu.hide()
		username = $MainMenu/Username.text
	else:
		$MainMenu/error.show()
	
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		escape()
