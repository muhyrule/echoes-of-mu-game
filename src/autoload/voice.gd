extends RefCounted
## Old-gothic diction plus regional dialect, applied to dialogue text at display time.

const BASE := [
	["okay", "very well"], ["ok", "very well"], ["yeah", "aye"], ["hello", "good even"], ["hi", "well met"],
	["goodbye", "fare thee well"], ["bye", "fare thee well"], ["maybe", "perchance"], ["really", "in sooth"],
	["thanks", "my thanks"], ["thank you", "I thank thee"], ["hurry", "make haste"], ["come on", "come, now"],
	["stop", "hold"], ["i don't know", "I know not"], ["i can't", "I cannot"], ["i won't", "I will not"],
	["right now", "this very hour"], ["kill", "slay"], ["scared", "affrighted"], ["afraid", "affrighted"],
	["weird", "uncanny"], ["strange", "uncanny"], ["monster", "abomination"], ["monsters", "abominations"],
	["ghost", "spectre"], ["ghosts", "spectres"], ["so many", "so great a multitude of"], ["nobody", "no soul"],
	["everyone", "every soul"], ["listen", "hark"], ["look", "behold"], ["there is", "there is"],
	["a lot of", "a great many"], ["i think", "I trow"], ["perhaps", "perchance"], ["now", "now"],
	["tonight", "this night"], ["tomorrow", "on the morrow"], ["yes", "yea"], ["no,", "nay,"],
]
const SCOTS := [
	["you're", "ye're"], ["you'll", "ye'll"], ["you've", "ye've"], ["you", "ye"], ["your", "yer"], ["my", "ma"],
	["don't", "dinnae"], ["doesn't", "disnae"], ["can't", "cannae"], ["won't", "willnae"], ["didn't", "didnae"],
	["isn't", "isnae"], ["wasn't", "wasnae"], ["couldn't", "couldnae"], ["wouldn't", "wouldnae"],
	["know", "ken"], ["little", "wee"], ["small", "wee"], ["child", "bairn"], ["children", "bairns"],
	["girl", "lass"], ["home", "hame"], ["from", "fae"], ["own", "ain"], ["going to", "gonnae"],
	["good", "guid"], ["about", "aboot"], ["out", "oot"], ["down", "doon"], ["dead", "deid"],
	["old", "auld"], ["cold", "cauld"], ["night", "nicht"], ["right", "richt"], ["yes", "aye"], ["yea", "aye"],
	["no one", "naebody"], ["stone", "stane"], ["whole", "hale"], ["don't know", "dinnae ken"],
]
const BOHEMIAN := [
	["sir", "pane"], ["madam", "paní"], ["good day", "dobrý den"], ["thank you", "děkuji"], ["my thanks", "děkuji"],
	["welcome", "vítejte"], ["yea", "ano"], ["aye", "ano"], ["well,", "ach,"], ["oh,", "ach,"],
	["friend", "přítel"], ["friends", "přátelé"], ["God", "Bůh"], ["heaven", "nebesa"], ["devil", "čert"],
	["the devil", "the čert"], ["by my soul", "by duše mé"], ["nay,", "ne,"],
]
const EDIN_SPEAKERS := ["Hamish", "Peggy", "Rab", "Alasdair", "Marta", "Duncan", "Kirsty", "Morag", "Fergus", "Euphemia", "Ruaridh"]
const PRA_SPEAKERS := ["Captain Jan", "Eliska", "Vaclav", "Anezka", "Tomas", "Karel", "Hana"]

static var _cache: Dictionary = {}


static func _rules(rules: Array, key: String) -> Array:
	if _cache.has(key):
		return _cache[key]
	var out: Array = []
	for r in rules:
		var w: String = r[0]
		var rep: String = r[1]
		var lo := RegEx.new()
		lo.compile("\\b" + w.replace("'", "['’]") + "(?![\\w'])" if w.ends_with(",") == false else "\\b" + w)
		out.append([lo, rep, false])
		var cap := RegEx.new()
		var cw := w.substr(0, 1).to_upper() + w.substr(1)
		cap.compile("\\b" + cw.replace("'", "['’]") + "(?![\\w'])" if w.ends_with(",") == false else "\\b" + cw)
		out.append([cap, rep.substr(0, 1).to_upper() + rep.substr(1), true])
	_cache[key] = out
	return out


static func _apply(text: String, rules: Array, key: String) -> String:
	for r in _rules(rules, key):
		text = r[0].sub(text, r[1], true)
	return text


## region: "" (default), "edin", "pra"
static func speak(text: String, who: String, ctx: String) -> String:
	if who == "" or text == "":
		return text
	var region := ""
	if ctx.begins_with("edin_") or EDIN_SPEAKERS.has(who):
		region = "edin"
	elif ctx.begins_with("pra_") or PRA_SPEAKERS.has(who):
		region = "pra"
	var main := ["Mu", "Father Aldous", "Isolde", "Wren", "Corvin"]
	if main.has(who):
		region = ""
	if main.has(who) or region != "":
		text = _apply(text, BASE, "base")
	if region == "edin":
		text = _apply(text, SCOTS, "scots")
	elif region == "pra":
		text = _apply(text, BOHEMIAN, "boh")
	return text
