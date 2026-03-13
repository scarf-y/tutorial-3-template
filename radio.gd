extends Area2D

@onready var anim = $AnimatedSprite2D
@onready var audio_player = $AudioStreamPlayer2D
@onready var interaction_label = $InteractionLabel
@onready var music_label = $MusicLabel

@export var playlist: Array[AudioStream] = []
var current_track_index := 0
var is_on := false
var player_in_range := false
var music_tween: Tween

func _ready():
	anim.play("off")
	audio_player.stop()
	interaction_label.hide() 
	music_label.modulate.a = 0

func _input(event):
	if player_in_range and event.is_action_pressed("interact"): # Map 'E' to "interact" in Input Map
		if not is_on:
			turn_on()
		else:
			change_track()
	
	if player_in_range and event.is_action_pressed("turn_off"):
		if is_on:
			turn_off()

func turn_off():
	is_on = false
	anim.play("off")
	audio_player.stop()
	update_ui()

func turn_on():
	is_on = true
	anim.play("on") # Or whichever name you gave your 'on' animation
	play_current_track()
	update_ui()

func change_track():
	current_track_index = (current_track_index + 1) % playlist.size()
	anim.play("change_visual") # Play the 'music change' frames briefly
	await get_tree().create_timer(0.5).timeout
	anim.play("on") # Switch to a faster animation for higher energy
	play_current_track()

func play_current_track():
	if playlist.size() > 0:
		var track = playlist[current_track_index]
		audio_player.stream = track
		audio_player.play()
		
		var file_name = track.resource_path.get_file().get_basename()
		show_music_notif(file_name)

func update_ui():
	if not player_in_range:
		interaction_label.hide()
		return
		
	interaction_label.show()
	if not is_on:
		interaction_label.text = "[E] Turn On"
	else:
		interaction_label.text = "[E] Change Music\n[F] Turn Off"

func show_music_notif(title: String):
	
	music_label.text = "Now playing: " + title
	
	music_label.modulate.a = 1.0
	
	if music_tween:
		music_tween.kill()
		
	music_tween = get_tree().create_tween()
	
	music_tween.tween_interval(2.0)
	music_tween.tween_property(music_label, "modulate:a", 0.0, 1.5)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "adventurer":
		player_in_range = true
	
	update_ui()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "adventurer":
		player_in_range = false
		
	update_ui()
