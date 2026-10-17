extends RefCounted
## Magazine state is independent from fire cadence and only advances during play.
const Data=preload("res://scripts/game_data.gd")
const IDLE_RELOAD_DELAY:=0.65
var weapon_id:="revolver"
var capacity:=6
var ammo:=6
var reload_duration:=1.2
var reload_remaining:=0.0
var reloading:=false
var idle_elapsed:=0.0

func reset(id: String) -> void:
	weapon_id=id
	capacity=Data.WEAPONS[id].ammo
	ammo=capacity
	reload_duration=Data.WEAPONS[id].reload_time
	reload_remaining=0.0
	reloading=false
	idle_elapsed=0.0

func set_modifiers(extra_capacity: int,reload_rate: float) -> void:
	var progress_left:=reload_remaining/reload_duration if reloading else 0.0
	var old_capacity:=capacity
	capacity=int(Data.WEAPONS[weapon_id].ammo)+extra_capacity
	ammo=clampi(ammo+maxi(0,capacity-old_capacity),0,capacity)
	reload_duration=float(Data.WEAPONS[weapon_id].reload_time)/maxf(0.1,reload_rate)
	if reloading: reload_remaining=reload_duration*progress_left

func can_fire() -> bool:
	return not reloading and ammo>0

func consume_shot() -> bool:
	if not can_fire(): return false
	ammo-=1
	idle_elapsed=0.0
	return true

func begin_reload() -> bool:
	if reloading or ammo>=capacity: return false
	reloading=true
	reload_remaining=reload_duration
	idle_elapsed=0.0
	return true

func progress() -> float:
	return clampf(1.0-reload_remaining/reload_duration,0,1) if reloading else 1.0

func advance(delta: float,has_target: bool) -> Dictionary:
	var events:={"started":false,"finished":false}
	if reloading:
		reload_remaining=maxf(0,reload_remaining-maxf(0,delta))
		if reload_remaining<=0.000001:
			reload_remaining=0
			reloading=false
			ammo=capacity
			idle_elapsed=0
			events.finished=true
		return events
	if has_target:
		idle_elapsed=0
	elif ammo<capacity:
		idle_elapsed+=maxf(0,delta)
	if ammo==0 or (ammo<capacity and idle_elapsed>=IDLE_RELOAD_DELAY):
		events.started=begin_reload()
	return events
