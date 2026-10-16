extends Node
## Original procedural audio: SFX and looping gothic themes synthesized at runtime.

const RATE := 22050
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _pool: Array = []
var _music: AudioStreamPlayer
var _current := ""
var enabled := true

const THEMES := {
	# chords as root semitone offsets from A2 (110 Hz); arpeggio over minor/major triads
	"chapel": {"chords": [[0, 3, 7], [-4, 0, 3], [-2, 2, 5], [-5, -1, 2]], "step": 0.45, "gain": 0.5},
	"crypt": {"chords": [[0, 3, 7], [0, 3, 6], [-2, 1, 5], [-1, 3, 6]], "step": 0.28, "gain": 0.55},
	"clock": {"chords": [[0, 3, 7], [2, 5, 9], [-3, 0, 4], [-5, -2, 2]], "step": 0.34, "gain": 0.5},
	"boss": {"chords": [[0, 3, 6], [-1, 2, 6], [-4, -1, 2], [-5, -2, 1]], "step": 0.16, "gain": 0.6},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = -8.0
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -14.0
	add_child(_music)


func _make(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s


# segments: [[freq_start, freq_end, seconds]], wave: sine|square|noise
func _synth(segments: Array, wave: String, vol: float) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var phase := 0.0
	for seg in segments:
		var n := int(seg[2] * RATE)
		for i in n:
			var k := float(i) / n
			var f: float = lerpf(seg[0], seg[1], k)
			phase += f / RATE
			var v := 0.0
			match wave:
				"sine": v = sin(phase * TAU)
				"square": v = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
				"noise": v = randf() * 2.0 - 1.0
			out.append(v * vol * (1.0 - k) * 0.9)
	return _make(out)


func sfx(name: String) -> void:
	if not enabled:
		return
	if not _sfx_cache.has(name):
		match name:
			"slash": _sfx_cache[name] = _synth([[900, 300, 0.12]], "noise", 0.35)
			"hit": _sfx_cache[name] = _synth([[220, 80, 0.12]], "square", 0.4)
			"hurt": _sfx_cache[name] = _synth([[300, 90, 0.25]], "square", 0.5)
			"pickup": _sfx_cache[name] = _synth([[660, 660, 0.08], [880, 880, 0.14]], "square", 0.35)
			"door": _sfx_cache[name] = _synth([[90, 60, 0.4]], "noise", 0.5)
			"switch": _sfx_cache[name] = _synth([[330, 330, 0.1], [495, 495, 0.2]], "sine", 0.6)
			"form": _sfx_cache[name] = _synth([[200, 900, 0.35]], "sine", 0.6)
			"roar": _sfx_cache[name] = _synth([[90, 50, 0.7]], "square", 0.5)
			"push": _sfx_cache[name] = _synth([[70, 55, 0.2]], "noise", 0.4)
			"menu": _sfx_cache[name] = _synth([[520, 520, 0.06]], "square", 0.3)
			"bell": _sfx_cache[name] = _synth([[196, 190, 1.2]], "sine", 0.7)
			_: return
	for p in _pool:
		if not p.playing:
			p.stream = _sfx_cache[name]
			p.play()
			return


func play_music(name: String) -> void:
	if name == _current or not THEMES.has(name):
		return
	_current = name
	if not enabled:
		return
	if not _music_cache.has(name):
		_music_cache[name] = _build_theme(THEMES[name])
	_music.stream = _music_cache[name]
	_music.play()


func stop_music() -> void:
	_current = ""
	_music.stop()


func _build_theme(t: Dictionary) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var step_samples := int(t.step * RATE)
	var chords: Array = t.chords
	for chord in chords:
		for beat in 8:
			var arp: int = chord[[0, 1, 2, 1, 2, 1, 0, 2][beat]]
			var f := 110.0 * pow(2.0, float(arp + 12) / 12.0)
			var bass := 110.0 * pow(2.0, float(chord[0]) / 12.0)
			for i in step_samples:
				var tt := float(i) / RATE
				var env := exp(-tt * 5.0)
				var lead := sin(TAU * f * tt) * 0.5 + sin(TAU * f * 2.0 * tt) * 0.12
				var pad := sin(TAU * bass * (tt + beat * t.step)) * 0.35
				out.append((lead * env + pad * 0.5) * t.gain * 0.6)
	return _make(out, true)
