extends Node
## Original procedural audio: SFX and looping gothic themes synthesized at runtime.

const RATE := 22050
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _pool: Array = []
var _music: AudioStreamPlayer
var _current := ""
var enabled := true

# Music: simplified arrangements of public-domain classical themes, synthesized at runtime.
const THEME_ALIAS := {
	"menu": "toccata", "chapel": "moonlight", "crypt": "funeral",
	"clock": "winter", "boss": "fate", "boss2": "dance",
}
const TS := 1024
var _tables: Dictionary = {}
var _thread: Thread
var _building := ""
var _pending := ""


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
	if name == _current or not THEME_ALIAS.has(name):
		return
	_current = name
	if not enabled:
		return
	_music.stop()
	if _music_cache.has(name):
		_music.stream = _music_cache[name]
		_music.play()
	else:
		_pending = name
		_try_build()


func stop_music() -> void:
	_current = ""
	_pending = ""
	_music.stop()


func _try_build() -> void:
	if _thread != null or _pending == "" or _music_cache.has(_pending):
		return
	_building = _pending
	_pending = ""
	_thread = Thread.new()
	_thread.start(_build_theme.bind(THEME_ALIAS[_building]))


func _process(_delta: float) -> void:
	if _thread != null and not _thread.is_alive():
		_music_cache[_building] = _thread.wait_to_finish()
		_thread = null
		if _current == _building:
			_music.stream = _music_cache[_building]
			_music.play()
		_try_build()


func _exit_tree() -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null


func _make_table(harm: Array) -> PackedFloat32Array:
	var tb := PackedFloat32Array()
	tb.resize(TS)
	var peak := 0.0
	for i in TS:
		var v := 0.0
		for h in harm.size():
			v += harm[h] * sin(TAU * float(i) / TS * float(h + 1))
		tb[i] = v
		peak = maxf(peak, absf(v))
	for i in TS:
		tb[i] /= peak
	return tb


func _ensure_tables() -> void:
	if _tables.is_empty():
		_tables["organ"] = _make_table([1.0, 0.8, 0.55, 0.5, 0.3, 0.22, 0.1])
		_tables["piano"] = _make_table([1.0, 0.45, 0.28, 0.14, 0.07])
		_tables["strings"] = _make_table([1.0, 0.5, 0.33, 0.25, 0.2, 0.16, 0.14, 0.12])


static func _midi(tok: String) -> int:
	var names := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
	var v: int = names[tok[0]]
	var i := 1
	while tok[i] == "#" or tok[i] == "b":
		v += 1 if tok[i] == "#" else -1
		i += 1
	return v + 12 * (int(tok.substr(i)) + 1)


# "A4+C5:1.5 R:1" -> [[[midi...], beats], ...]; R is a rest
static func _parse(seq: String) -> Array:
	var out: Array = []
	for tok in seq.split(" ", false):
		var parts := tok.split(":")
		var notes: Array = []
		if parts[0] != "R":
			for n in parts[0].split("+"):
				notes.append(_midi(n))
		out.append([notes, float(parts[1])])
	return out


static func _rep(s: String, n: int) -> String:
	var r := ""
	for i in n:
		r += s + " "
	return r.strip_edges()


func _score(name: String) -> Dictionary:
	match name:
		"toccata":
			return {"bpm": 68.0, "voices": [
				{"inst": "organ", "vol": 0.34, "seq": "A5:.25 G5:.25 A5:1.5 R:.5 G5:.25 F5:.25 E5:.25 D5:.25 C#5:.5 D5:3 R:1 A4:.25 G4:.25 A4:1.5 R:.5 G4:.25 F4:.25 E4:.25 D4:.25 C#4:.5 D4:3 R:1"},
				{"inst": "organ", "vol": 0.3, "seq": "R:16 D3+F3+A3+D4:2 C#3+G3+E4+A4:2 D3+A3+D4+F4:2 Bb2+F3+D4+G4:2 A2+E3+C#4+A4:2 D2+A2+D3+F3+A3+D4:6"},
				{"inst": "organ", "vol": 0.32, "seq": "R:4 D2:12 Bb1:4 A1:4 D2:8"},
			]}
		"moonlight":
			var bars := [
				["G#3 C#4 E4", "C#2+C#3"], ["G#3 C#4 E4", "B1+B2"], ["A3 C#4 E4", "A1+A2"],
				["A3 C#4 F#4", "F#1+F#2"], ["G#3 C4 D#4", "G#1+G#2"], ["G#3 C#4 E4", "C#2+C#3"],
			]
			var arp := ""
			var bass := ""
			for b in bars:
				for g in 4:
					for n in b[0].split(" "):
						arp += n + ":.3333 "
				bass += b[1] + ":4 "
			return {"bpm": 50.0, "voices": [
				{"inst": "piano", "vol": 0.22, "seq": arp.strip_edges()},
				{"inst": "piano", "vol": 0.3, "seq": bass.strip_edges()},
				{"inst": "strings", "vol": 0.2, "seq": "R:8 G#4:3 A4:.5 G#4:.5 E5:3 D#5:.5 E5:.5 C#5:2 B4:2 A4:2 G#4:2 F#4:1 G#4:1 C#5:4"},
			]}
		"funeral":
			return {"bpm": 56.0, "voices": [
				{"inst": "bell", "vol": 0.3, "seq": _rep("Bb2:1 R:1", 16)},
				{"inst": "strings", "vol": 0.17, "seq": _rep("Bb3+Db4+F4:.75 R:.25 Bb3+Db4+F4:.75 R:.25 Bb3+Db4+F4:.75 R:.25 Bb3+Db4+F4:.75 R:.25", 2) + " " + _rep("Gb3+Bb3+Db4:.75 R:.25 F3+Ab3+Db4:.75 R:.25 Bb3+Db4+F4:.75 R:.25 F3+A3+C4:.75 R:.25", 2)},
				{"inst": "strings", "vol": 0.3, "seq": "R:8 Db5:1.5 Eb5:.25 Db5:.25 Db5:1.5 Eb5:.25 Db5:.25 Db5:1 Cb5:1 Bb4:2 R:8 Db5:1.5 Eb5:.25 Db5:.25 F5:1.5 Eb5:.25 Db5:.25 C5:1 Bb4:1 Bb4:2"},
				{"inst": "organ", "vol": 0.2, "seq": "Bb1:8 Bb1:8 Gb1:4 F1:4 Bb1:8"},
			]}
		"winter":
			var pulse := _rep("F3+Ab3+C4:.5", 8)
			var pulse2 := _rep("Db3+F3+Ab3:.5", 4) + " " + _rep("C3+E3+G3:.5", 4)
			return {"bpm": 120.0, "voices": [
				{"inst": "strings", "vol": 0.16, "seq": pulse + " " + pulse2 + " " + pulse + " " + pulse2},
				{"inst": "organ", "vol": 0.14, "seq": _rep("F2:1", 8) + " " + _rep("Db2:1", 4) + " " + _rep("C2:1", 4) + " " + _rep("F2:1", 8) + " " + _rep("Db2:1", 4) + " " + _rep("C2:1", 4)},
				{"inst": "strings", "vol": 0.3, "seq": "F5:.5 F5:.5 F5:.5 F5:.5 C5:.25 Db5:.25 C5:.25 Bb4:.25 Ab4:.25 G4:.25 F4:.25 G4:.25 Ab4:.5 F5:.5 Eb5:.25 Db5:.25 C5:.25 Db5:.25 Eb5:.5 C5:.5 Db5:.25 Eb5:.25 F5:.25 G5:.25 Ab5:.5 F5:.5 Db5:.5 C5:.5 R:2 F5:.5 F5:.5 F5:.5 F5:.5 C5:.25 Db5:.25 C5:.25 Bb4:.25 Ab4:.25 G4:.25 F4:.25 G4:.25 Ab4:.5 F5:.5 Eb5:.25 Db5:.25 C5:.25 Db5:.25 Bb4:1 C5:1 F4:4"},
			]}
		"fate":
			var motif := "R:.5 G4:.5 G4:.5 G4:.5 Eb4:4 R:.5 F4:.5 F4:.5 F4:.5 D4:4"
			return {"bpm": 124.0, "voices": [
				{"inst": "strings", "vol": 0.3, "seq": motif + " R:.5 G4:.5 G4:.5 G4:.5 Eb4:2 R:.5 Bb4:.5 Bb4:.5 Bb4:.5 G4:3 R:1"},
				{"inst": "strings", "vol": 0.24, "seq": motif.replace("4:", "3:") + " R:.5 G3:.5 G3:.5 G3:.5 Eb3:2 R:.5 Bb3:.5 Bb3:.5 Bb3:.5 G3:3 R:1"},
				{"inst": "organ", "vol": 0.18, "seq": "C2+G2:6 G1+D2:6 C2+G2:4 Eb2+Bb2:4 G1+D2:4"},
				{"inst": "timp", "vol": 0.42, "seq": _rep("C2:1 R:1", 12)},
			]}
		"dance":
			return {"bpm": 150.0, "voices": [
				{"inst": "strings", "vol": 0.32, "seq": "D5:1 C5:.5 Bb4:.5 A4:1 G4:.5 A4:.5 Bb4:1 A4:.5 G4:.5 F#4:1.5 R:.5 D5:1 C5:.5 Bb4:.5 A4:1 G4:.5 A4:.5 Bb4:.5 C5:.5 D5:.5 Eb5:.5 D5:2 R:2 G5:1 F5:.5 Eb5:.5 D5:1 C5:.5 D5:.5 Eb5:1 D5:.5 C5:.5 Bb4:1.5 R:.5 G4:.5 A4:.5 Bb4:.5 C5:.5 D5:1 F#4:1 G4:3 R:1"},
				{"inst": "strings", "vol": 0.18, "seq": _rep("G3+Bb3+D4:1 R:1", 8) + " " + _rep("D3+F#3+A3:1 R:1", 4) + " " + _rep("G3+Bb3+D4:1 R:1", 4)},
				{"inst": "organ", "vol": 0.16, "seq": _rep("G2:2", 8) + " " + _rep("D2:2", 4) + " " + _rep("G2:2", 4)},
				{"inst": "timp", "vol": 0.3, "seq": _rep("G1:1 R:1", 16)},
			]}
	return {"bpm": 60.0, "voices": []}


func _build_theme(name: String) -> AudioStreamWAV:
	_ensure_tables()
	var sc := _score(name)
	var spb := 60.0 / float(sc.bpm)
	var total_beats := 0.0
	var parsed: Array = []
	for v in sc.voices:
		var seq := _parse(v.seq)
		var b := 0.0
		for n in seq:
			b += n[1]
		total_beats = maxf(total_beats, b)
		parsed.append(seq)
	var n_total := int(ceilf(total_beats) * spb * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n_total)
	for vi in sc.voices.size():
		var v: Dictionary = sc.voices[vi]
		var pos := 0.0
		for n in parsed[vi]:
			var dur: float = n[1] * spb
			for m in n[0]:
				_render_note(buf, int(pos * spb * RATE), m, dur, v.inst, v.vol)
			pos += n[1]
	for cfg in [[int(0.31 * RATE), 0.42], [int(0.47 * RATE), 0.36]]:
		var d: int = cfg[0]
		var g: float = cfg[1]
		var y := PackedFloat32Array()
		y.resize(n_total)
		for pass_i in 2:
			for i in n_total:
				y[i] = buf[i] + g * y[(i - d + n_total) % n_total]
		for i in n_total:
			buf[i] += y[i] * 0.25
	var peak := 0.001
	for i in n_total:
		peak = maxf(peak, absf(buf[i]))
	var k := 0.8 / peak
	for i in n_total:
		buf[i] *= k
	return _make(buf, true)


func _render_note(buf: PackedFloat32Array, start: int, midi: int, dur: float, inst: String, vol: float) -> void:
	var f := 440.0 * pow(2.0, float(midi - 69) / 12.0)
	var rel := 0.25 if inst != "organ" else 0.12
	var n := int((dur + rel) * RATE)
	if inst == "bell" or inst == "timp":
		n = int(2.2 * RATE) if inst == "bell" else int(0.7 * RATE)
	var total := buf.size()
	var phase := 0.0
	var tb: PackedFloat32Array = _tables.get(inst, _tables["organ"])
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		match inst:
			"bell":
				v = (sin(TAU * f * t) + 0.5 * sin(TAU * f * 2.41 * t) + 0.3 * sin(TAU * f * 3.97 * t)) * exp(-t * 1.8) * (minf(t * 400.0, 1.0))
			"timp":
				v = sin(TAU * f * 1.6 * t * (1.0 + 0.5 * exp(-t * 25.0))) * exp(-t * 7.0)
			_:
				var vib := 1.0 + (0.004 * sin(TAU * 5.4 * t) if inst == "strings" else 0.0)
				phase += f * vib / RATE
				v = tb[int((phase - floorf(phase)) * TS) % TS]
				var env := minf(t / (0.12 if inst == "strings" else (0.02 if inst == "organ" else 0.005)), 1.0)
				if inst == "piano":
					env *= exp(-t * 2.2)
				if t > dur:
					env *= maxf(0.0, 1.0 - (t - dur) / rel)
				v *= env
		buf[(start + i) % total] += v * vol
