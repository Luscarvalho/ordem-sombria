extends Node
## Music and pooled combat effects; settings are independent of run progress.

const TRACKS := {
	"menu": preload("res://assets/audio/menu_theme.wav"),
	"game": preload("res://assets/audio/game_theme.wav"),
}
const FADE_SECONDS := 1.2
const SFX := {
	"reload_start": preload("res://assets/audio/reload_start.wav"),
	"reload_end": preload("res://assets/audio/reload_end.wav"),
	"revolver": preload("res://assets/audio/revolver.wav"),
	"shotgun": preload("res://assets/audio/shotgun.wav"),
	"wand": preload("res://assets/audio/wand.wav"),
	"return_blade": preload("res://assets/audio/return_blade.wav"),
	"grenade_launcher": preload("res://assets/audio/grenade_launcher.wav"),
	"dual_pistols": preload("res://assets/audio/dual_pistols.wav"),
	"grenade_blast": preload("res://assets/audio/grenade_blast.wav"),
	"enemy_hit": preload("res://assets/audio/enemy_hit.wav"),
	"player_hurt": preload("res://assets/audio/player_hurt.wav"),
	"shield_block": preload("res://assets/audio/shield_block.wav"),
	"level_up": preload("res://assets/audio/level_up.wav"),
}
const SFX_GAINS := {"reload_start": 0.30, "reload_end": 0.28, "revolver": 0.65, "shotgun": 0.85, "wand": 0.45, "return_blade": 0.4, "grenade_launcher": 0.6, "dual_pistols": 0.4, "grenade_blast": 0.6, "enemy_hit": 0.28, "player_hurt": 0.75, "shield_block": 0.55, "level_up": 0.55}
var settings_path := "user://audio_settings.cfg"
var enabled := true
var volumes := {"menu": 0.40, "game": 0.35, "effects": 0.55}
var context := "menu"
var players: Dictionary = {}
var weights := {"menu": 0.0, "game": 0.0}
var sfx_players: Array[AudioStreamPlayer] = []
var last_sfx: Dictionary = {}
var sfx_rng := RandomNumberGenerator.new()

func _ready() -> void:
	sfx_rng.randomize()
	_load_settings()
	for id in TRACKS:
		var player := AudioStreamPlayer.new()
		player.name = id.capitalize() + "Music"
		var stream := TRACKS[id].duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
		player.stream = stream
		player.volume_linear = 0.0
		add_child(player)
		players[id] = player
	for i in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "CombatSfx%d" % i
		player.volume_linear = 0.0
		add_child(player)
		sfx_players.append(player)
	set_context("menu")

func play_sfx(id: String) -> bool:
	if not SFX.has(id) or volumes.effects <= 0.0:
		return false
	var now := Time.get_ticks_msec()
	# Many pellets/status hits can land together; keep impacts from becoming noise.
	var cooldown := 75 if id == "enemy_hit" else 35
	if now - int(last_sfx.get(id, -100000)) < cooldown:
		return false
	last_sfx[id] = now
	var voice: AudioStreamPlayer = sfx_players[0]
	for player in sfx_players:
		if not player.playing:
			voice = player
			break
		if int(player.get_meta("started", 0)) < int(voice.get_meta("started", 0)):
			voice = player
	voice.stop()
	voice.stream = SFX[id]
	voice.pitch_scale = sfx_rng.randf_range(0.96, 1.04)
	voice.set_meta("gain", SFX_GAINS[id])
	voice.set_meta("sound", id)
	voice.set_meta("started", now)
	voice.volume_linear = volumes.effects * SFX_GAINS[id]
	voice.play()
	return true

func set_context(value: String) -> void:
	if not TRACKS.has(value):
		return
	context = value
	var player: AudioStreamPlayer = players[context]
	if not player.playing:
		player.volume_linear = 0.0
		player.play()

func _process(delta: float) -> void:
	for id in players:
		var target := 1.0 if id == context else 0.0
		weights[id] = move_toward(weights[id], target, delta / FADE_SECONDS)
		if weights[id] == 0.0 and id != context:
			players[id].stop()
	_apply_volumes()

func set_enabled(value: bool) -> void:
	enabled = value
	_apply_volumes()
	_save_settings()

func set_volume(id: String, value: float) -> void:
	if not volumes.has(id):
		return
	volumes[id] = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_save_settings()

func _apply_volumes() -> void:
	for id in players:
		players[id].volume_linear = weights[id] * volumes[id] if enabled else 0.0
	for player in sfx_players:
		player.volume_linear = volumes.effects * float(player.get_meta("gain", 1.0))

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var saved_enabled: Variant = config.get_value("music", "enabled", true)
	if saved_enabled is bool:
		enabled = saved_enabled
	for id in volumes:
		var value: Variant = config.get_value("music", id + "_volume", volumes[id])
		if (value is float or value is int) and is_finite(float(value)):
			volumes[id] = clampf(float(value), 0.0, 1.0)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("music", "enabled", enabled)
	for id in volumes:
		config.set_value("music", id + "_volume", volumes[id])
	var error := config.save(settings_path)
	if error != OK:
		push_warning("Não foi possível salvar as configurações de música: %s" % error_string(error))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_RESUMED:
		for player in players.values():
			player.stream_paused = what == NOTIFICATION_APPLICATION_PAUSED
		for player in sfx_players:
			player.stream_paused = what == NOTIFICATION_APPLICATION_PAUSED
