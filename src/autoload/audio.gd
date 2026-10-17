extends Node
## Original procedural audio: SFX and looping gothic themes synthesized at runtime.

const RATE := 44100
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _pool: Array = []
var _music: AudioStreamPlayer
var _current := ""
var enabled := true

# Music: original compositions in classical styles, synthesized at runtime.
const THEME_ALIAS := {
	"menu": "toccata", "chapel": "moonlight", "crypt": "funeral",
	"clock": "winter", "boss": "fate", "boss2": "dance",
	"edin": "edin", "praha": "praha", "inn": "inn",
	"prologue": "prologue", "road": "road", "vaults": "vaults", "ossuary": "ossuary",
}
const TS := 1024
var _tables: Dictionary = {}
var _thread: Thread
var _building := ""
var _queue: Array = []


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


func _make(samples: PackedFloat32Array, loop := false, right: PackedFloat32Array = PackedFloat32Array()) -> AudioStreamWAV:
	var st := right.size() == samples.size() and right.size() > 0
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * (4 if st else 2))
	for i in samples.size():
		if st:
			bytes.encode_s16(i * 4, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
			bytes.encode_s16(i * 4 + 2, int(clampf(right[i], -1.0, 1.0) * 32000.0))
		else:
			bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = st
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
		_queue.erase(name)
		_queue.push_front(name)
		_try_build()


func stop_music() -> void:
	_current = ""
	_music.stop()


func preload_music(names: Array) -> void:
	for n in names:
		if THEME_ALIAS.has(n) and not _music_cache.has(n) and n != _building and not _queue.has(n):
			_queue.append(n)
	_try_build()


func _try_build() -> void:
	if _thread != null or _queue.is_empty():
		return
	_building = _queue.pop_front()
	if _music_cache.has(_building):
		_try_build()
		return
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
		_tables["organ"] = _make_table([1.0, 0.6, 0.3, 0.2, 0.08, 0.04])
		_tables["piano"] = _make_table([1.0, 0.32, 0.12, 0.04])
		_tables["strings"] = _make_table([1.0, 0.42, 0.2, 0.1, 0.05, 0.03])
		_tables["pluck"] = _make_table([1.0, 0.5, 0.25, 0.12, 0.06])
		_tables["choir"] = _make_table([1.0, 0.12, 0.5, 0.08, 0.3, 0.05, 0.12])
		_tables["harp"] = _make_table([1.0, 0.38, 0.14, 0.06, 0.02])
		_tables["flute"] = _make_table([1.0, 0.1, 0.05])
		_tables["cello"] = _make_table([1.0, 0.7, 0.5, 0.35, 0.22, 0.14, 0.08, 0.04])
		_tables["drone"] = _make_table([1.0, 0.8, 0.55, 0.4, 0.3, 0.2, 0.15, 0.1, 0.06])


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


static func _name(m: int) -> String:
	var pcs := ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	return pcs[m % 12] + str(floori(m / 12.0) - 1)


static func _shift(m: int, semis: int) -> int:
	return m + semis


static func _step(m: int, steps: int, sc: Array) -> int:
	var idx := 0
	for i in sc.size():
		if sc[i] <= m:
			idx = i
	return sc[clampi(idx + steps, 0, sc.size() - 1)]


static func _map_notes(seq: String, f: Callable) -> String:
	var out := PackedStringArray()
	for tok in seq.split(" ", false):
		var parts := tok.split(":")
		if parts[0] == "R":
			out.append(tok)
			continue
		var ns := PackedStringArray()
		for n in parts[0].split("+"):
			ns.append(_name(f.call(_midi(n))))
		out.append("+".join(ns) + ":" + parts[1])
	return " ".join(out)


# chromatic transposition
static func _tr(seq: String, semis: int) -> String:
	return _map_notes(seq, _shift.bind(semis))


# diatonic transposition by scale degrees; pcs = pitch classes of the scale
static func _ds(seq: String, steps: int, pcs: Array) -> String:
	var sc: Array = []
	for m in range(12, 120):
		if pcs.has(m % 12):
			sc.append(m)
	return _map_notes(seq, _step.bind(steps, sc))


# arpeggio over a space-separated note list; pat optionally picks indices
static func _ap(chord: String, beats: float, step: float, pat: Array = []) -> String:
	var ns := chord.split(" ")
	var out := PackedStringArray()
	for i in int(round(beats / step)):
		var idx: int = pat[i % pat.size()] if not pat.is_empty() else i % ns.size()
		out.append("%s:%s" % [ns[idx], step])
	return " ".join(out)


# alternating root / fifth walking bass in single beats
static func _bw(root: String, beats: int) -> String:
	var out := PackedStringArray()
	for i in beats:
		out.append((root if i % 2 == 0 else _name(_midi(root) + 7)) + ":1")
	return " ".join(out)


# cimbalom-style tremolo: split each note into repeated short notes
static func _trem(seq: String, step := 0.25) -> String:
	var out := PackedStringArray()
	for tok in seq.split(" ", false):
		var parts := tok.split(":")
		if parts[0] == "R":
			out.append(tok)
			continue
		for i in maxi(1, int(round(float(parts[1]) / step))):
			out.append("%s:%s" % [parts[0], step])
	return " ".join(out)


static func _r(beats: float) -> String:
	return "R:%s" % beats


static func _cat(parts: Array) -> String:
	return " ".join(PackedStringArray(parts))


static func _len(seq: String) -> float:
	var b := 0.0
	for tok in seq.split(" ", false):
		b += float(tok.split(":")[1])
	return b


# pad every voice with silence up to the same length so loops stay aligned
static func _mk(bpm: float, beats: float, voices: Array) -> Dictionary:
	for v in voices:
		var d := beats - _len(v.seq)
		if d > 0.01:
			v.seq = _cat([v.seq, _r(d)])
	return {"bpm": bpm, "voices": voices}


func _score(name: String) -> Dictionary:
	match name:
		"toccata":
			# "Vigil" - C minor organ fugue (subject, answer at the fifth, pedal entry), sequence episode, block-chord climax
			var s := "G4:1 C5:.5 Bb4:.5 Ab4:.5 G4:.5 F4:.5 Eb4:.5 D4:1 Eb4:.5 F4:.5 G4:2"
			var cs := "Eb5:1 D5:.5 C5:.5 D5:1 Eb5:1 F5:1 G5:1 Ab5:1 G5:.5 F5:.5"
			var free := "C5:1 Bb4:1 Ab4:1 G4:1 F4:1 Eb4:1 D4:1 G3:1"
			var head := "Eb5:.5 D5:.5 C5:.5 Bb4:.5 Ab4:1"
			var episode := ""
			for st in [0, -2, -4, -5, -7, -9, -11, -12]:
				episode += _tr(head, st) + " "
			var blocks := "C3+G3+C4+Eb4+G4:4 Ab2+Eb3+Ab3+C4+Eb4:4 F3+Ab3+C4+F4:4 G2+D3+G3+B3+D4:4 Ab2+Eb3+Ab3+C4:2 G2+D3+G3+B3:2 C3+G3+C4+Eb4+G4:4"
			return _mk(76.0, 96.0, [
				{"inst": "organ", "vol": 0.3, "seq": _cat([s, cs, _tr(cs, -2), free, episode,
					_tr(s, 12), "Ab5:2 G5:2 F5:2 D5:2 Eb5:2 D5:2 C5:4", "G4:1 C5:.5 Bb4:.5 Ab4:2 G4:4"])},
				{"inst": "organ", "vol": 0.28, "seq": _cat([_r(8), _tr(s, 7), _tr(cs, -5), _tr(free, -5),
					"F3+Ab3+C4:6 Bb2+D3+F3:6 Eb3+G3+Bb3:6 Ab2+C3+Eb3:6", blocks, "F3+Ab3+C4:8 G2+D3+G3+B3:8"])},
				{"inst": "organ", "vol": 0.3, "seq": _cat([_r(16), _tr(s, -24), "C2:8", "G1:24",
					"C2:4 Ab1:4 F2:4 G1:4 Ab1:2 G1:2 C2:4", "F2:8 G1:8"])},
				{"inst": "bell", "vol": 0.26, "seq": _cat([_r(32), _rep("G3:4 R:2", 4), _rep("C3:4", 6), "C3:4 R:4 C3:4 R:4"])},
			])
		"moonlight":
			# "Candle Nocturne" - B minor nocturne (A), D major bridge (B), shortened return (A'), arpeggiated left hand
			var pat := [0, 1, 2, 3, 2, 1, 2, 3]
			var ca := ["B2 F#3 B3 D4", "G2 D3 G3 B3", "F#2 D3 A3 D4", "E2 B2 G3 B3", "D3 F#3 B3 D4", "G2 D3 G3 B3", "A2 E3 A3 C#4", "F#2 C#3 A#3 C#4"]
			var cb := ["D3 A3 D4 F#4", "C#3 E3 A3 C#4", "B2 F#3 B3 D4", "F#2 C#3 A3 C#4", "G2 D3 B3 D4", "F#2 D3 A3 F#4", "E2 B2 G3 D4", "A2 E3 G3 C#4"]
			var cc := ["B2 F#3 B3 D4", "G2 D3 G3 B3", "F#2 C#3 A#3 C#4", "B2 F#3 B3 D4"]
			var ma := ["R:1 D5:1 F#5:1.5 E5:.5", "D5:3 B4:1", "A4:1 D5:1 F#5:2", "E5:2 D5:1 B4:1",
				"R:1 D5:1 F#5:1.5 G5:.5", "A5:3 F#5:1", "E5:2 C#5:1 E5:1", "F#5:3 C#5:1"]
			var mb := ["F#5:2 A5:1 F#5:1", "E5:1.5 A5:.5 E5:2", "D5:1 F#5:1 B5:2", "A5:2 F#5:1 C#5:1",
				"B5:2 A5:1 G5:1", "F#5:1.5 A5:.5 D6:2", "B5:1 G5:1 E5:2", "C#5:1 E5:1 G5:2"]
			var mc := [ma[0], ma[1], "C#5:2 A#4:1 C#5:1", "B4:4"]
			var arp := ""
			for c in ca + cb + cc:
				arp += _ap(c, 4, 0.5, pat) + " "
			var mel_a := _cat(ma + mb + mc)
			return _mk(62.0, 80.0, [
				{"inst": "piano", "vol": 0.22, "seq": arp.strip_edges()},
				{"inst": "strings", "vol": 0.22, "seq": mel_a},
				{"inst": "piano", "vol": 0.14, "seq": _cat([_r(64), _tr(_cat(mc), 12)])},
				{"inst": "organ", "vol": 0.07, "seq": _cat([_r(32), "D2+A2:8 A1+E2:8 B1+F#2:8 F#1+C#2:8", "B1+F#2:16"])},
			])
		"funeral":
			# "Ossuary March" - F# minor dirge, A major trio, return in octaves, tolling bell
			var ma := ["A4:1.5 A4:.5 C#5:2", "A4:1.5 F#4:.5 D5:2", "C#5:1.5 B4:.5 A4:1 G#4:1", "F#4:3 R:1",
				"C#5:1.5 C#5:.5 E5:2", "D5:1.5 C#5:.5 B4:2", "A4:1.5 B4:.5 C#5:1 G#4:1", "F#4:4"]
			var ch := ["F#3+A3+C#4", "D3+F#3+A3", "C#3+F3+G#3+B3", "F#3+A3+C#4", "F#3+A3+C#4", "B3+D4+F#4", "C#3+F3+G#3+B3", "F#3+A3+C#4"]
			var bass := ["F#1:4", "D2:4", "C#2:4", "F#1:4", "F#1:4", "B1:4", "C#2:4", "F#1:4"]
			var march := PackedStringArray()
			for c in ch:
				march.append("%s:1 R:1 %s:1 R:1" % [c, c])
			var mt := "C#5:2 E5:1 A5:1 B5:2 G#5:1 E5:1 A5:2 F#5:1 C#5:1 E5:3 R:1"
			var tail_m := _cat(ma.slice(4))
			var tail_b := _cat(bass.slice(4))
			var tail_c := " ".join(march.slice(4))
			return _mk(58.0, 72.0, [
				{"inst": "bell", "vol": 0.3, "seq": _cat(["F#2:4", _rep("F#2:2", 16), _rep("F#2:4", 4), _rep("F#2:2", 8), "F#2:4"])},
				{"inst": "strings", "vol": 0.17, "seq": _cat([_r(4), " ".join(march), "A3+C#4+E4:4 E3+G#3+B3:4 F#3+A3+C#4:4 E3+G#3+B3:4",
					tail_c, "F#3+C#4+F#4:4"])},
				{"inst": "strings", "vol": 0.3, "seq": _cat([_r(4), _cat(ma), mt, tail_m])},
				{"inst": "strings", "vol": 0.16, "seq": _cat([_r(52), _tr(tail_m, 12)])},
				{"inst": "organ", "vol": 0.22, "seq": _cat(["F#1+C#2:4", _cat(bass), "A1:4 E2:4 F#1:4 E2:4", tail_b, "F#1+C#2:4"])},
				{"inst": "timp", "vol": 0.34, "seq": _cat(["F#1:1 F#1:1 F#1:1 F#1:1", _rep("F#1:1 R:1", 16), _r(16), _rep("F#1:1", 16)])},
			])
		"winter":
			# "Clockwork Concerto" - G minor ritornello form with gear-like 16th ostinato, sequential episodes
			var m1 := "G5:.5 F#5:.5 G5:.5 D5:.5 Bb4:.5 D5:.5 G4:.5 Bb4:.5"
			var m2 := "A4:.5 C5:.5 Eb5:.5 D5:.5 C5:.5 Bb4:.5 A4:.5 G4:.5"
			var m3 := "A5:.5 G5:.5 F#5:.5 A5:.5 D5:.5 F#5:.5 A4:.5 C5:.5"
			var m4 := "A4:1 D5:1 Bb4:.5 A4:.5 G4:1"
			var rit := _cat([m1, m2, m3, m4])
			var bmaj := [10, 0, 2, 3, 5, 7, 9]
			var gh := [7, 9, 10, 0, 2, 3, 6]
			var e1 := ""
			var e2 := ""
			for k in 8:
				e1 += _ds("F5:.5 D5:.5 Bb4:.5 D5:.5", -k, bmaj) + " "
				e2 += _ds("G5:.5 Eb5:.5 C5:.5 Eb5:.5", -k, gh) + " "
			var c_r1 := ["G3 Bb3 D4 G4", "C4 Eb4 G4 Eb4", "D4 F#4 A4 F#4", "G3 Bb3 D4 G4"]
			var c_r2 := ["D4 F4 A4 D5", "G4 Bb4 D5 Bb4", "A3 C#4 E4 C#4", "D4 F4 A4 D5"]
			var c_e1 := ["Bb3 D4 F4 D4", "G3 Bb3 D4 Bb3", "Eb4 G4 Bb4 G4", "F4 A4 C5 A4"]
			var c_e2 := ["C4 Eb4 G4 Eb4", "Ab3 C4 Eb4 C4", "B3 D4 F4 D4", "D4 F#4 A4 F#4"]
			var c_co := ["G3 Bb3 D4 G4", "D4 F#4 A4 F#4", "C4 Eb4 G4 Eb4", "G3 Bb3 D4 G4"]
			var osti := ""
			for chs in [c_r1, c_e1, c_r2, c_e2, c_r1, c_co]:
				for c in chs:
					osti += _ap(c, 4, 0.25) + " "
			var bass := ""
			for roots in [["G2", "C3", "D3", "G2"], ["Bb2", "G2", "Eb3", "F3"], ["D3", "G3", "A3", "D3"],
					["C3", "Ab2", "B2", "D3"], ["G2", "C3", "D3", "G2"], ["G2", "D3", "C3", "G2"]]:
				for r in roots:
					bass += _bw(r, 4) + " "
			var run := "G4:.25 A4:.25 Bb4:.25 C5:.25 D5:.25 Eb5:.25 F#5:.25 G5:.25 A5:.25 G5:.25 F#5:.25 Eb5:.25 D5:.25 C5:.25 Bb4:.25 A4:.25"
			var coda := _cat([run, "D5:2 F#5:2 G5:4 D5:1 Bb4:1 G4:2"])
			return _mk(126.0, 96.0, [
				{"inst": "strings", "vol": 0.3, "seq": _cat([rit, e1, _tr(rit, 7), e2, rit, coda])},
				{"inst": "strings", "vol": 0.14, "seq": osti.strip_edges()},
				{"inst": "organ", "vol": 0.16, "seq": bass.strip_edges()},
				{"inst": "strings", "vol": 0.16, "seq": _cat([_r(64), _tr(rit, 12)])},
				{"inst": "bell", "vol": 0.16, "seq": _cat([_r(80), "G4:4 R:4 G4:4 R:4"])},
			])
		"fate":
			# "Ruin" - D minor tragic drama: gasping leap motif, canonic development, bell chorale, return a tone higher
			var mo := "D4:.5 D4:.5 Bb4:1.5 A4:.5 G#4:.5 A4:.5"
			var th := _cat([mo, _tr(mo, -2), _tr(mo, -5), "G#4:1 A4:1 D4:2"])
			var ch := "D2+F3+A3:4 C2+Eb3+G3:4 A1+C3+E3:4 A1+C#3+E3:4"
			var tim := _rep("D2:1 R:.5 D2:.5 D2:1 R:1", 4)
			var counter := "F4:4 Eb4:4 E4:4 E4:4"
			var dm := [2, 4, 5, 7, 9, 10, 1]
			var dev := ""
			var canon := "R:2 "
			var dbass := ""
			for k in 8:
				dev += _ds("D4:.5 D4:.5 Bb4:1", k, dm) + " "
				if k < 7:
					canon += _tr(_ds("D4:.5 D4:.5 Bb4:1", k, dm), -12) + " "
			for r in ["D2", "E2", "F2", "G2", "A2", "Bb2", "C#3", "A2"]:
				dbass += _rep(r + ":.5", 4) + " "
			var chor_m := "F5:2 E5:1 D5:1 D5:3 Bb4:1 C#5:2 E5:2 D5:4"
			var chor_o := "Bb2+F3+Bb3+D4:4 G2+D3+G3+Bb3:4 A2+E3+A3+C#4:4 D2+A2+D3+F3+A3:4"
			return _mk(120.0, 96.0, [
				{"inst": "strings", "vol": 0.3, "seq": _cat([th, th, dev.strip_edges(), chor_m, _tr(th, 2), th])},
				{"inst": "strings", "vol": 0.22, "seq": _cat([_r(16), counter, canon.strip_edges(), _r(16), _tr(counter, 2), _tr(th, -12)])},
				{"inst": "strings", "vol": 0.16, "seq": _cat([_r(64), _tr(th, 14), _tr(th, 12)])},
				{"inst": "organ", "vol": 0.2, "seq": _cat([ch, ch, dbass.strip_edges(), chor_o, _tr(ch, 2), ch])},
				{"inst": "timp", "vol": 0.4, "seq": _cat([tim, tim, _rep("D2:.5", 32), _r(16), _tr(tim, 2), tim])},
				{"inst": "bell", "vol": 0.2, "seq": _cat([_r(48), _rep("A3:4", 4), _r(16), _rep("D3:4", 4)])},
			])
		"dance":
			# "Csardas Macabre" - E Hungarian-minor: slow lassu, then fast friss with oom-pah and cimbalom tremolo
			var lm := "B4:2 C5:1 D#5:1 E5:1.5 D#5:.5 C5:1 B4:1 A#4:2 G4:1 F#4:1 E4:3 R:1 G4:1 A#4:1 B4:1 D#5:1 D#5:2 B4:2"
			var lch := "E3+G3+B3:8 C3+E3+G3:4 E3+G3+B3:4 C3+E3+G3:4 B2+D#3+F#3:4"
			var lped := "E2:8 C2:4 E2:4 C2:4 B1:4"
			var fam := "B4:.5 B4:.5 E5:1 D#5:.5 E5:.5 G5:1 F#5:.5 G5:.5 A#5:1 G5:.5 F#5:.5 E5:1 C5:.5 D#5:.5 G5:1 F#5:.5 E5:.5 D#5:1 E5:1 D#5:.5 C5:.5 B4:2"
			var fbm := "G5:.5 F#5:.5 G5:.5 B5:.5 D6:1 B5:1 C6:.5 B5:.5 A5:.5 G5:.5 F#5:2 G5:.5 A5:.5 B5:.5 C6:.5 D6:.5 C6:.5 B5:.5 A5:.5 B5:1 G5:1 D5:2"
			var a_roots := ["E2", "E2", "C2", "B1"]
			var a_stabs := ["G3+B3+E4", "G3+B3+E4", "E3+G3+C4", "D#3+F#3+B3"]
			var b_roots := ["G2", "D2", "C2", "D2"]
			var b_stabs := ["B3+D4+G4", "A3+D4+F#4", "E3+G3+C4", "A3+D4+F#4"]
			var ba := ""
			var sa := ""
			var bb := ""
			var sb := ""
			var be := ""
			var se := ""
			for i in 4:
				ba += "%s:1 R:1 %s:1 R:1 " % [a_roots[i], a_roots[i]]
				sa += "R:1 %s:1 R:1 %s:1 " % [a_stabs[i], a_stabs[i]]
				bb += "%s:1 R:1 %s:1 R:1 " % [b_roots[i], b_roots[i]]
				sb += "R:1 %s:1 R:1 %s:1 " % [b_stabs[i], b_stabs[i]]
			be = _tr(bb, -3)
			se = _tr(sb, -3)
			var coda := "B5:.5 A#5:.5 G5:.5 F#5:.5 E5:.5 D#5:.5 C5:.5 B4:.5 E5:1 E5:1 E5:2"
			return _mk(120.0, 96.0, [
				{"inst": "strings", "vol": 0.3, "seq": _cat([lm, fam, fbm, fam, _tr(fbm, -3), coda])},
				{"inst": "strings", "vol": 0.18, "seq": _cat([lch, sa, sb, sa, se])},
				{"inst": "organ", "vol": 0.18, "seq": _cat([lped, ba, bb, ba, be, "B2+D#3+F#3:4 E2+B2+E3+G3:4"])},
				{"inst": "timp", "vol": 0.32, "seq": _cat([_rep("E2:4", 6), _rep("E2:1 R:1", 8), _rep("E2:1 R:1", 8), _rep("E2:1", 16), _rep("E2:1 R:1", 8), _rep("E2:1", 8)])},
				{"inst": "piano", "vol": 0.18, "seq": _cat([_r(56), _trem(_tr(fam, 12)), _trem(_tr(fbm, -3)), _trem(_tr(coda, 12))])},
			])
		"edin":
			# "Old Town Snow" - D dorian, 6/8 lilt (beat = dotted quarter), piano arpeggios, strings melody, distant bells
			var t3 := 1.0 / 3.0
			var pat := [0, 1, 2, 3, 2, 1]
			var ca := ["D3 A3 D4 F4", "C3 G3 C4 E4", "Bb2 F3 Bb3 D4", "C3 G3 C4 E4", "D3 A3 D4 F4", "G2 D3 G3 B3", "A2 E3 A3 C4", "C3 G3 C4 E4"]
			var cb := ["F2 C3 F3 A3", "C3 G3 C4 E4", "D3 A3 D4 F4", "Bb2 F3 Bb3 D4", "F2 C3 F3 A3", "C3 G3 C4 E4", "G2 D3 Bb3 D4", "A2 E3 G3 C#4"]
			var co := ["D3 A3 D4 F4", "C3 G3 C4 E4", "Bb2 F3 Bb3 D4", "C3 G3 C4 E4", "D3 A3 D4 F4", "Bb2 F3 Bb3 D4", "C3 G3 C4 E4", "D3 A3 D4 F4"]
			var ma := ["A4:1 F5:.6667 E5:.3333", "G5:1 E5:.6667 C5:.3333", "D5:1.3333 F5:.3333 D5:.3333", "E5:1 C5:.6667 G4:.3333",
				"A4:.6667 D5:.3333 F5:1", "G5:1.3333 B4:.3333 D5:.3333", "E5:1 C5:.3333 A4:.3333 C5:.3333", "D5:2"]
			var mb := ["C5:1 A4:.6667 C5:.3333", "E5:1.3333 D5:.3333 C5:.3333", "F5:1 D5:.6667 A4:.3333", "D5:1.3333 C5:.3333 Bb4:.3333",
				"A4:.6667 C5:.3333 F5:1", "G5:1.3333 E5:.3333 C5:.3333", "Bb4:1 D5:.6667 G5:.3333", "E5:2"]
			var mc := [ma[0], ma[1], ma[2], ma[3], "F5:1 A5:.6667 F5:.3333", "D6:1.3333 B5:.3333 G5:.3333", "E5:1 A5:.6667 C6:.3333", "D5:2"]
			var arp := ""
			for c in ca + cb + ca:
				arp += _ap(c, 2, t3, pat) + " "
			for c in co:
				arp += _ap(c, 2, 0.6667, [0, 2, 3]) + " "
			return _mk(54.0, 64.0, [
				{"inst": "piano", "vol": 0.16, "seq": arp.strip_edges()},
				{"inst": "strings", "vol": 0.24, "seq": _cat(ma + mb + mc + ["D5:4 C5:2 Bb4:2 A4:4 D5:4"])},
				{"inst": "organ", "vol": 0.1, "seq": "D2+A2:16 F2+C3:8 Bb1+F2:4 A1+E2:4 D2+A2:16 D2+A2:8 Bb1+F2:4 D2+A2:4"},
				{"inst": "bell", "vol": 0.14, "seq": _cat([_r(4), "D5:4 R:4 A4:4", "F5:4 R:4 C5:4 R:4", _r(4), "D5:2 F5:2 R:4 A4:4", "D5:4 R:4 A4:4 D4:4"])},
			])
		"praha":
			# "Staromestske Minuet" - A minor minuet (16 bars) and C major trio (16 bars), harpsichord-like pluck, running bass
			var bars_min := [
				["E5:1 A5:.5 G5:.5 F5:.5 E5:.5", "A2 C3 E3", "A3+C4+E4"],
				["C5:1.5 B4:.5 A4:1", "A2 E3 A2", "A3+C4+E4"],
				["D5:1 F5:1 A5:1", "D3 F3 A3", "F3+A3+D4"],
				["E5:1 D5:.5 C5:.5 B4:1", "E3 G#3 B3", "G#3+B3+E4"],
				["A4:.5 C5:.5 E5:.5 A5:.5 G5:1", "A2 C3 E3", "A3+C4+E4"],
				["A5:1 F5:1 C5:1", "F2 A2 C3", "A3+C4+F4"],
				["B4:1 G#4:1 E5:1", "E3 G#3 D4", "G#3+D4+E4"],
				["A4:3", "A2 E2 A2", "A3+C4+E4"],
				["G5:1 E5:1 C5:1", "C3 E3 G3", "E3+G3+C4"],
				["B4:1 D5:1 G5:1", "G2 B2 D3", "B3+D4+G4"],
				["A5:1.5 G5:.5 E5:1", "A2 C3 E3", "A3+C4+E4"],
				["E5:1 G5:1 B5:1", "E2 G2 B2", "G3+B3+E4"],
				["A5:1 G5:.5 F5:.5 E5:1", "F2 A2 C3", "A3+C4+F4"],
				["F5:1 A5:1 D6:1", "D3 A2 F3", "A3+D4+F4"],
				["B5:1 G#5:1 E5:1", "E3 G#3 B3", "G#3+B3+E4"],
				["E5:1 C5:1 A4:1", "A2 E3 A2", "A3+C4+E4"],
			]
			var bars_tri := [
				["E5:1.5 D5:.5 C5:1", "C3 E3 G3", "E3+G3+C4"],
				["B4:1 D5:1 G5:1", "G2 B2 D3", "B3+D4+G4"],
				["E5:1.5 G5:.5 C6:1", "C3 G3 E3", "E3+G3+C4"],
				["A5:1 F5:1 C5:1", "F2 A2 C3", "A3+C4+F4"],
				["G5:1 E5:.5 D5:.5 C5:1", "C3 E3 G3", "E3+G3+C4"],
				["C5:1 E5:1 A5:1", "A2 C3 E3", "A3+C4+E4"],
				["G5:1 F5:.5 E5:.5 D5:1", "G2 B2 D3", "B3+D4+G4"],
				["E5:2 C5:1", "C3 G2 C3", "E3+G3+C4"],
				["F5:1 A5:1 F5:1", "F2 A2 C3", "A3+C4+F4"],
				["E5:1 G5:1 E5:1", "C3 E3 G3", "E3+G3+C4"],
				["D5:1 F5:1 A5:1", "D3 F3 A3", "F3+A3+D4"],
				["B5:1 G5:1 D5:1", "G2 B2 D3", "B3+D4+G4"],
				["G5:1 B5:1 E6:1", "E3 G3 B3", "G3+B3+E4"],
				["C6:1 A5:.5 G5:.5 E5:1", "A2 C3 E3", "A3+C4+E4"],
				["D5:1 F5:1 G5:1", "G2 B2 F3", "B3+D4+F4"],
				["B4:1.5 D5:.5 G4:1", "G2 D3 G2", "B3+D4+G4"],
			]
			var mel := ""
			var bas := ""
			var stab := ""
			for b in bars_min + bars_tri:
				mel += b[0] + " "
				for n in b[1].split(" "):
					bas += n + ":1 "
				stab += "R:1 %s:1 %s:1 " % [b[2], b[2]]
			var trio_mel := ""
			for b in bars_tri:
				trio_mel += b[0] + " "
			var cmaj := [0, 2, 4, 5, 7, 9, 11]
			return _mk(112.0, 96.0, [
				{"inst": "strings", "vol": 0.28, "seq": mel.strip_edges()},
				{"inst": "pluck", "vol": 0.3, "seq": bas.strip_edges()},
				{"inst": "pluck", "vol": 0.2, "seq": stab.strip_edges()},
				{"inst": "strings", "vol": 0.14, "seq": _cat([_r(48), _ds(trio_mel, -2, cmaj)])},
			])
		"inn":
			# "Hearthside" - G major / E minor, soft piano arpeggios, organ pad, tender strings, very quiet
			var pat := [0, 1, 2, 3]
			var sections := [
				[["G2 D3 B3 D4", "E2 B2 G3 B3", "C3 G3 E4 G3", "D3 A3 F#4 A3"],
					["D5:1.5 B4:.5 G4:2", "B4:2 E5:1 D5:1", "E5:1 G5:1 E5:1 C5:1", "F#5:1 D5:1 A4:2"],
					["G2+D3+G3", "E2+B2+E3", "C3+G3+C4", "D3+A3+D4"]],
				[["E2 B2 G3 B3", "A2 E3 C4 A3", "B2 F#3 B3 D#4", "E2 B2 G3 B3"],
					["B4:2 G5:1 F#5:1", "A4:2 C5:1 E5:1", "D#5:2 F#5:1 B4:1", "E5:3 R:1"],
					["E2+B2+E3", "A2+E3+A3", "B2+F#3+B3", "E2+B2+E3"]],
				[["G2 D3 B3 D4", "B2 F#3 B3 D4", "C3 G3 E4 G3", "D3 A3 F#4 A3"],
					["G5:2 D5:1 B4:1", "D5:1.5 F#5:.5 D5:2", "E5:1 G5:1 C6:2", "A5:1 F#5:1 D5:2"],
					["G2+D3+G3", "B2+F#3+B3", "C3+G3+C4", "D3+A3+D4"]],
				[["C3 G3 E4 G3", "A2 E3 C4 E4", "D3 A3 F#4 A3", "G2 D3 B3 G4"],
					["E5:2 G5:1 E5:1", "C5:1 E5:1 A4:2", "F#5:2 A5:1 F#5:1", "B4:2 G4:2"],
					["C3+G3+C4", "A2+E3+A3", "D3+A3+D4", "G2+D3+G3"]],
			]
			var arp := ""
			var mel := ""
			var pad := ""
			for sec in sections:
				for i in 4:
					arp += _ap(sec[0][i], 4, 0.5, pat) + " "
					mel += sec[1][i] + " "
					pad += sec[2][i] + ":4 "
			return _mk(62.0, 64.0, [
				{"inst": "piano", "vol": 0.16, "seq": arp.strip_edges()},
				{"inst": "organ", "vol": 0.07, "seq": pad.strip_edges()},
				{"inst": "strings", "vol": 0.14, "seq": mel.strip_edges()},
			])
		"prologue":
			# "Candle and Plague" - D minor choir, cello and harp beneath a lone flute; the great bell tolls
			var chords := ["D4+F4+A4:8", "Bb3+D4+F4:8", "G3+Bb3+D4:8", "A3+C#4+E4:8", "D4+F4+A4:8", "C4+F4+A4:8", "G3+Bb3+D4:8", "A3+C#4+E4:8"]
			var roots := ["D2:8", "Bb1:8", "G1:8", "A1:8", "D2:8", "F2:8", "G1:8", "A1:8"]
			var harp_n := ["D3 A3 F4 A4", "Bb2 F3 D4 F4", "G2 D3 Bb3 D4", "A2 E3 C#4 E4", "D3 A3 F4 A4", "F2 C3 A3 C4", "G2 D3 Bb3 D4", "A2 E3 C#4 E4"]
			var fl := ["D5:3 F5:1 A5:2 G5:1 F5:1", "F5:3 D5:1 Bb4:2 C5:1 D5:1", "G5:3 Bb5:1 A5:2 G5:1 F5:1", "E5:2 G5:1 A5:1 C#6:3 R:1",
				"D6:3 C6:1 A5:2 F5:2", "A5:3 C6:1 F6:2 E6:1 D6:1", "Bb5:2 A5:2 G5:2 D5:2", "C#5:2 E5:2 A5:2 E5:1 C#5:1"]
			var hp := ""
			for h in harp_n:
				hp += _ap(h, 8, 1, [0, 1, 2, 3, 2, 1, 3, 2]) + " "
			return _mk(58.0, 64.0, [
				{"inst": "choir", "vol": 0.22, "pan": -0.25, "seq": _cat(chords)},
				{"inst": "cello", "vol": 0.26, "pan": -0.5, "seq": _cat(roots)},
				{"inst": "harp", "vol": 0.2, "pan": 0.4, "seq": hp.strip_edges()},
				{"inst": "flute", "vol": 0.22, "pan": 0.2, "seq": _cat([_r(16), _cat(fl.slice(2))])},
				{"inst": "strings", "vol": 0.12, "pan": 0.0, "seq": _cat([_r(32), _tr(_cat(chords.slice(4)), 12)])},
				{"inst": "bell", "vol": 0.22, "pan": 0.0, "seq": _rep("D3:2 R:14", 4)},
			])
		"road":
			# "Lantern Miles" - E minor travelling air: walking harp ostinato, flute tune, open-fifth drone
			var chs := ["E3 B3 G4 B3", "G3 D4 B4 D4", "D3 A3 F#4 A3", "A2 E3 C4 E3", "E3 B3 G4 B3", "C3 G3 E4 G3", "D3 A3 F#4 A3", "E3 B3 G4 B3"]
			var tune := ["B4:1 E5:1 G5:1 F#5:1", "G5:1 B5:1 A5:1 G5:1", "F#5:1 A5:1 D6:1 A5:1", "E5:1 A5:1 C6:1 B5:1",
				"B5:1.5 G5:.5 E5:1 B4:1", "G5:1 E5:1 C5:1 E5:1", "F#5:1 A5:.5 F#5:.5 D5:2", "E5:3 R:1"]
			var bass := ["E2:2 B2:2", "G2:2 D3:2", "D2:2 A2:2", "A1:2 E2:2", "E2:2 B2:2", "C2:2 G2:2", "D2:2 A2:2", "E2:4"]
			var ar := ""
			for c in chs:
				ar += _ap(c, 4, 0.5, [0, 1, 2, 3]) + " "
			var tn := _cat(tune)
			return _mk(92.0, 64.0, [
				{"inst": "harp", "vol": 0.18, "pan": 0.35, "seq": _cat([ar.strip_edges(), ar.strip_edges()])},
				{"inst": "flute", "vol": 0.24, "pan": -0.2, "seq": _cat([_r(4), tn, _tr(tn, 12)])},
				{"inst": "cello", "vol": 0.22, "pan": -0.45, "seq": _cat([_cat(bass), _cat(bass)])},
				{"inst": "drone", "vol": 0.07, "pan": 0.0, "seq": "E2+B2:64"},
				{"inst": "pluck", "vol": 0.1, "pan": -0.55, "seq": _cat([_r(32), _rep("B3:1 R:1", 16)])},
			])
		"vaults":
			# "Beneath the Old Town" - Edinburgh vaults: pibroch-like lament over a D drone, slow bell and drum
			var vm := ["D5:4 F5:2 E5:1 D5:1", "A4:4 C5:2 D5:2", "F5:3 G5:1 A5:2 G5:1 F5:1", "E5:4 D5:2 A4:2",
				"D5:2 F5:2 A5:3 G5:1", "Bb5:4 A5:2 G5:2", "F5:2 E5:2 D5:2 C5:2", "D5:8"]
			return _mk(52.0, 64.0, [
				{"inst": "drone", "vol": 0.16, "pan": 0.0, "seq": "D2+A2:64"},
				{"inst": "flute", "vol": 0.24, "pan": 0.25, "seq": _cat(vm)},
				{"inst": "choir", "vol": 0.18, "pan": -0.3, "seq": "D3+A3+D4:16 Bb2+F3+Bb3:8 G2+D3+G3:8 A2+E3+A3:8 D3+A3+D4:24"},
				{"inst": "cello", "vol": 0.18, "pan": -0.5, "seq": _cat([_r(16), _tr(_cat(vm.slice(0, 4)), -24)])},
				{"inst": "bell", "vol": 0.2, "pan": 0.0, "seq": _rep("D3:2 R:14", 4)},
				{"inst": "timp", "vol": 0.3, "pan": 0.0, "seq": _rep("D2:1 R:7", 8)},
			])
		"ossuary":
			# "The Counted Hours" - Praha ossuary: phrygian cimbalom tremolo over a ticking clock and cello
			var om := ["A4:2 Bb4:1 A4:1 G#4:2 A4:2", "C5:2 B4:1 A4:1 E4:4", "A4:2 Bb4:1 A4:1 G#4:2 E4:2", "F4:2 E4:2 D4:2 E4:2",
				"E5:2 F5:1 E5:1 D#5:2 E5:2", "C5:2 D5:1 E5:1 A5:4", "G#5:2 F5:2 E5:2 D5:2", "A4:6 R:2"]
			var oc := ["A3+C4+E4:8", "A3+C4+E4:8", "A3+C4+E4:8", "D3+F3+A3:8", "E3+G#3+B3:8", "A3+C4+E4:8", "E3+G#3+B3:8", "A3+C4+E4:8"]
			var ob := ["A1:4 E2:4", "A1:4 E2:4", "A1:4 E2:4", "D2:4 A1:4", "E2:4 B1:4", "A1:4 E2:4", "E2:4 G#2:4", "A1:8"]
			return _mk(84.0, 64.0, [
				{"inst": "pluck", "vol": 0.22, "pan": 0.3, "seq": _trem(_cat(om), 0.25)},
				{"inst": "choir", "vol": 0.14, "pan": -0.3, "seq": _cat(oc)},
				{"inst": "cello", "vol": 0.24, "pan": -0.5, "seq": _cat(ob)},
				{"inst": "pluck", "vol": 0.07, "pan": 0.6, "seq": _rep("E6:.5 R:.5", 64)},
				{"inst": "timp", "vol": 0.28, "pan": 0.0, "seq": _rep("A1:1 R:3", 16)},
			])
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
	var bl := PackedFloat32Array()
	var br := PackedFloat32Array()
	bl.resize(n_total)
	br.resize(n_total)
	for vi in sc.voices.size():
		var v: Dictionary = sc.voices[vi]
		var pan: float = v.get("pan", 0.0)
		var ang := (pan + 1.0) * PI * 0.25
		var gl := cos(ang) * 1.414
		var gr := sin(ang) * 1.414
		var pos := 0.0
		for n in parsed[vi]:
			var dur: float = n[1] * spb
			for m in n[0]:
				_render_note(bl, br, gl, gr, int(pos * spb * RATE), m, dur, v.inst, v.vol)
			pos += n[1]
	_smooth_and_verb(bl, br)
	return _make(bl, true, br)


# circular one-pole low-pass: two laps so the filter state at the loop seam is consistent
static func _lowpass(buf: PackedFloat32Array, a0: float) -> void:
	var a := 1.0 - sqrt(1.0 - a0)
	var n := buf.size()
	var y := buf[n - 1]
	for lap in 2:
		for i in n:
			y += a * (buf[i] - y)
			if lap == 1:
				buf[i] = y


static func _comb_bank(src: PackedFloat32Array, cfgs: Array, damp: float, level: float, wet: PackedFloat32Array) -> void:
	var n := src.size()
	var da := 1.0 - sqrt(1.0 - damp)
	for cfg in cfgs:
		var d: int = cfg[0]
		var g: float = cfg[1]
		var y := PackedFloat32Array()
		y.resize(n)
		var lp := 0.0
		for lap in 3:
			for i in n:
				var j := i - d
				if j < 0:
					j += n
				lp += da * (y[j] - lp)
				y[i] = src[i] + g * lp
		for i in n:
			wet[i] += y[i] * level


# tone smoothing, stereo comb room tails wrapped around the loop, then soft limiting
func _smooth_and_verb(bl: PackedFloat32Array, br: PackedFloat32Array) -> void:
	var n := bl.size()
	for b in [bl, br]:
		_lowpass(b, 0.38)
		_lowpass(b, 0.5)
	var mid := PackedFloat32Array()
	mid.resize(n)
	for i in n:
		mid[i] = (bl[i] + br[i]) * 0.5
	var wl := PackedFloat32Array()
	var wr := PackedFloat32Array()
	wl.resize(n)
	wr.resize(n)
	var short_l := [[int(0.0297 * RATE), 0.66], [int(0.0371 * RATE), 0.64], [int(0.0411 * RATE), 0.62], [int(0.0437 * RATE), 0.6]]
	var short_r := [[int(0.0313 * RATE), 0.66], [int(0.0353 * RATE), 0.64], [int(0.0427 * RATE), 0.62], [int(0.0461 * RATE), 0.6]]
	var long_l := [[int(0.113 * RATE), 0.58], [int(0.167 * RATE), 0.54], [int(0.211 * RATE), 0.5]]
	var long_r := [[int(0.127 * RATE), 0.58], [int(0.181 * RATE), 0.54], [int(0.233 * RATE), 0.5]]
	_comb_bank(mid, short_l, 0.45, 0.16, wl)
	_comb_bank(mid, long_l, 0.26, 0.13, wl)
	_comb_bank(mid, short_r, 0.45, 0.16, wr)
	_comb_bank(mid, long_r, 0.26, 0.13, wr)
	_lowpass(wl, 0.3)
	_lowpass(wr, 0.3)
	var pre := int(0.022 * RATE)
	var dl := bl.duplicate()
	var dr := br.duplicate()
	for i in n:
		var j := i - pre
		if j < 0:
			j += n
		bl[i] = dl[i] * 0.78 + wl[j] * 1.1
		br[i] = dr[i] * 0.78 + wr[j] * 1.1
	var peak := 0.001
	for i in n:
		peak = maxf(peak, maxf(absf(bl[i]), absf(br[i])))
	var k := 0.8 / peak
	for i in n:
		bl[i] = tanh(bl[i] * k * 1.25) * 0.78
		br[i] = tanh(br[i] * k * 1.25) * 0.78


func _render_note(bl: PackedFloat32Array, br: PackedFloat32Array, gl: float, gr: float, start: int, midi: int, dur: float, inst: String, vol: float) -> void:
	var f := 440.0 * pow(2.0, float(midi - 69) / 12.0)
	var rel := 0.2
	match inst:
		"organ": rel = 0.16
		"strings": rel = 0.3
		"piano": rel = 0.18
		"pluck": rel = 0.1
		"choir": rel = 0.5
		"harp": rel = 0.25
		"flute": rel = 0.12
		"cello": rel = 0.25
		"drone": rel = 0.6
	var n := int((dur + rel) * RATE)
	if inst == "bell" or inst == "timp":
		n = int(2.2 * RATE) if inst == "bell" else int(0.7 * RATE)
	var total := bl.size()
	var phase := 0.0
	var tb: PackedFloat32Array = _tables.get(inst, _tables["organ"])
	var att := 0.02
	match inst:
		"strings": att = 0.16
		"organ": att = 0.05
		"piano": att = 0.012
		"pluck": att = 0.008
		"choir": att = 0.3
		"harp": att = 0.006
		"flute": att = 0.07
		"cello": att = 0.09
		"drone": att = 0.5
	# lower voices sit rounder and quieter, bright ones stay clear
	var gain := vol
	if f < 140.0:
		gain *= 0.8
	var vphase := fmod(float(start) * 0.37, TAU)
	gain *= 1.0 + 0.05 * sin(TAU * float(start) / RATE / 7.0)
	var chorus := inst == "strings" or inst == "organ" or inst == "choir" or inst == "cello" or inst == "drone"
	var detune := 1.0 + (0.0017 if inst == "strings" else 0.0021)
	var phase2 := 0.25
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		match inst:
			"bell":
				var ba := minf(t / 0.015, 1.0)
				ba = ba * ba * (3.0 - 2.0 * ba)
				v = (sin(TAU * f * t) + 0.25 * sin(TAU * f * 2.0 * t) * exp(-t * 2.0) + 0.12 * sin(TAU * f * 2.76 * t) * exp(-t * 3.0)) * exp(-t * 1.5) * ba * 0.8
			"timp":
				var ta := minf(t / 0.006, 1.0)
				v = sin(TAU * f * 1.6 * t * (1.0 + 0.3 * exp(-t * 18.0))) * exp(-t * 6.0) * ta * 0.8
			_:
				var vib := 1.0
				if inst == "strings" or inst == "cello":
					vib += 0.003 * sin(TAU * 5.0 * t + vphase) * minf(t / 0.5, 1.0)
				elif inst == "choir" or inst == "flute":
					vib += 0.005 * sin(TAU * 5.4 * t + vphase) * minf(t / 0.7, 1.0)
				phase += f * vib / RATE
				var ph := (phase - floorf(phase)) * TS
				var i0 := int(ph) % TS
				var fr := ph - floorf(ph)
				v = lerpf(tb[i0], tb[(i0 + 1) % TS], fr)
				if chorus:
					phase2 += f * vib * detune / RATE
					var q := (phase2 - floorf(phase2)) * TS
					var k0 := int(q) % TS
					v = 0.62 * v + 0.38 * lerpf(tb[k0], tb[(k0 + 1) % TS], q - floorf(q))
				var env := minf(t / att, 1.0)
				env = env * env * (3.0 - 2.0 * env)
				if inst == "piano":
					env *= 0.55 * exp(-t * 4.5) + 0.45 * exp(-t * 1.4)
				elif inst == "pluck":
					env *= exp(-t * 6.0)
				elif inst == "harp":
					env *= 0.6 * exp(-t * 3.2) + 0.4 * exp(-t * 0.9)
				elif inst == "flute":
					v += (randf() - 0.5) * 0.06 * minf(t / 0.1, 1.0)
				elif inst == "choir":
					v *= 1.0 + 0.1 * sin(TAU * 0.35 * t + vphase)
				elif inst == "strings":
					v *= 1.0 + 0.04 * sin(TAU * 4.3 * t + vphase)
				if t > dur:
					var rk := clampf((t - dur) / rel, 0.0, 1.0)
					env *= 0.5 + 0.5 * cos(PI * rk)
				v *= env
		var o := (start + i) % total
		bl[o] += v * gain * gl
		br[o] += v * gain * gr
