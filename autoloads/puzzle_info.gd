extends Node

var p_seed: int
var size_min: int
var size_max: int
var time_to_complete: float

func format_time(time: float, show_hundreths := false) -> String:
	var hours := int(time / 3600)
	time -= hours * 3600
	var minutes := int(time / 60)
	time -= minutes * 60
	var seconds := int(time)
	var hours_s := "%d:" % [hours] if hours > 0 else ""
	var time_f = "%s%02d:%02d" % [hours_s, minutes, seconds]
	if show_hundreths:
		time -= seconds
		var hundreths := int(time * 100)
		time_f = "%s.%02d" % [time_f, hundreths]
	return time_f
