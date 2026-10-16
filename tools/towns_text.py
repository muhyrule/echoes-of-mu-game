"""Dialogue and secret text for the Edinburgh and Prague towns (original writing).

Used by tools/gen_towns.py, which writes data/dialogue_towns.json.
Each entry is a list of (who, text) or (who, text, flag_to_set) tuples. who == "" is narration.
"""

N = ""  # narration
DIALOGUE: dict[str, list] = {}


def d(key: str, *lines) -> None:
    DIALOGUE[key] = [
        {"who": l[0], "text": l[1], **({"set": l[2]} if len(l) > 2 else {})} for l in lines
    ]


# ---------------------------------------------------------------- EDINBURGH
d("edin_arrive",
  (N, "Edinburgh. The Old Town clings to its crag between castle and kirk, houses stacked nine storeys high, every window lit against the dark."),
  ("Isolde", "Home. Coal smoke and wet wool. I'd forgotten how much I'd missed it."),
  ("Mu", "Where do we start? The vaults?"),
  ("Isolde", "The vaults are chained since the collapse. The Watch won't open them without a writ. So we start where every Edinburgh body starts: asking around. Duncan's masonry, the Archive, the Drowned Candle. Somebody always knows something."),
  ("Mu", "Then let's see the town first."),
  (N, "Explore the Old Town. Press E at doors to go inside; barrels, chests, urns and shelves may hide more than dust."))

d("edin_gate_locked",
  (N, "The vault gate is chained and stamped with the Burgh seal. Only a proper writ will make the Watch cut it."),
  ("Isolde", "Hamish won't budge for a hammer and a good story. We need the Archive's writ."))

d("edin_hamish",
  ("Hamish", "Halt. The South Bridge Vaults are sealed by order of the Burgh. Rats, rot, and a roof that eats stonemasons."),
  ("Isolde", "Evening, Hamish. You carried my father's coffin once. You'll remember."),
  ("Hamish", "Isolde Marsh. Aye. And I'm sorry for Tomas. But a seal is a seal. Bring me a writ from the Archive and I'll cut the chain myself.")
  )
d("edin_hamish_again",
  ("Hamish", "Writ from the Archive. Mistress Blair keeps the seal. Duncan Rae the mason can vouch for you, if you ask him nicely."))
d("edin_hamish_writ",
  ("Hamish", "That's Mistress Blair's seal. Right. The chain is off, the gate is yours. Mind the third arch, it hums."),
  ("Isolde", "I know. I've been listening to it for three months."))
d("edin_hamish_after",
  ("Hamish", "Not a sound from below tonight. First quiet night since Martinmas. The Burgh owes you more than a writ, bell-boy."))

d("edin_peggy",
  ("Peggy", "Candles, two for a farthing! Buy three and I'll tell you why they gutter."),
  ("Peggy", "Every night since Martinmas the flames lean toward the South Bridge. All of them, in every window, same direction. Like they're bowing."),
  ("Mu", "Bowing to what?"),
  ("Peggy", "That's what I'd like to know, love. Wax doesn't lie, but it doesn't explain either."))
d("edin_peggy_again",
  ("Peggy", "Mind how you go. And if you find what's bending my candles, tell it I'd like them straight."))
d("edin_peggy_after",
  ("Peggy", "Straight as soldiers! Best week of the year, and the worst for trade. Nobody's buying spares."))

d("edin_rab",
  ("Wee Rab", "You're the bell-boy! I heard you ring, the whole Cowgate heard. Bet I can find more hidden stuff than you."),
  ("Wee Rab", "There's an urn in the kirkyard, up by the north wall. And Mrs Gilchrist keeps her good tea in the barrels at the Candle."),
  ("Isolde", "Rab, you've been in the barrels again."),
  ("Wee Rab", "...Research."))
d("edin_rab_again",
  ("Wee Rab", "The Fleshmarket Close, north-east, past the lamp. Nobody goes there since the wall cracked. There's a chest. I'm not scared. I just have a bad knee."))
d("edin_rab_after",
  ("Wee Rab", "The candles stand straight and the Wardens' ghosts have gone quiet. Can I ring your bell now?"),
  ("Mu", "Maybe when it's mended. All of it."))

d("edin_alasdair",
  ("Sexton Alasdair", "The dead are quiet here. Too quiet. A few months back they began murmuring at dusk. Names, mostly. Names I couldn't place, though I've dug these rows for forty years."),
  ("Sexton Alasdair", "Read the stones if you like. The old ones remember what the parish has forgotten."))
d("edin_alasdair_again",
  ("Sexton Alasdair", "Some of the headstones have gone smooth. No names, no dates, as if rubbed out by hand. I don't like it."))
d("edin_alasdair_after",
  ("Sexton Alasdair", "The murmuring has stopped. Not silence: rest. There's a difference. You'd know it, if you'd heard the first."))

d("edin_marta",
  ("Marta", "Isolde! And you've brought the bell-boy Aldous writes of. Sit, sit. Mind the loom, it's older than the roof."),
  ("Isolde", "Mam, we can't stay. The vaults..."),
  ("Marta", "Aye, the vaults. Your brother's blue thread is still on my spool. I keep the lamp lit in the window every night, in case either of you can't find your way home."),
  ("Mu", "We'll find it."),
  ("Marta", "Then go gently, and come back. That's all a mother asks."))
d("edin_marta_again",
  ("Marta", "Mind the road. And mind each other."))
d("edin_marta_after",
  ("Marta", "Tomas stayed to guard it? Aye. Of course he did. Stubborn, like his sister."),
  ("Isolde", "Mam..."),
  ("Marta", "Come here, the pair of you. He's resting now. Go on, and ring the next bell. I've a lamp to trim."))

d("edin_duncan",
  ("Duncan", "Isolde's friend? Then you've come about the vaults. I mended that arch with Tomas the day it fell. It shouldn't have been standing at all."),
  ("Duncan", "The mortar was wrong. Not old: wrong. Mixed with something that hums when you lean on it."),
  ("Duncan", "Tell Mistress Blair at the Archive that Duncan Rae sent you. Give her this mason's mark. She'll know I'd not vouch for just anybody."),
  (N, "You receive Duncan's Mason's Mark."),
  ("Duncan", "And lad? If the third arch sings back to you, don't sing with it.", "edin_duncan"))
d("edin_duncan_again",
  ("Duncan", "Blair's at the Archive, across from the tavern. Tell her Duncan Rae says the third arch is wrong."))
d("edin_duncan_after",
  ("Duncan", "The hum's gone out of the stone. I'll sleep tonight. Tell Isolde the yard's hers whenever she wants it."))

d("edin_kirsty",
  ("Kirsty", "Master Duncan won't let me touch the big chisels. But I found something. The old stones carry marks, little bells, every seventh course."),
  ("Kirsty", "Someone built those vaults knowing. Whoever it was, they wanted the walls to remember."))
d("edin_kirsty_again",
  ("Kirsty", "Seventh course. Every time. I counted."))

d("edin_morag",
  ("Morag", "Welcome to the Drowned Candle. Sit by the fire, it's free for those who ring bells."),
  ("Morag", "Mind Fergus. He has a verse for every occasion, and most of them are rude."))
d("edin_morag_again",
  ("Morag", "Wee Rab's been in my barrels again, hasn't he. I can tell by the missing tea."))

d("edin_fergus",
  ("Fergus", "A song, travellers? A true one. The old verse of the Bells."),
  ("Fergus", "Seven bells, seven keepers: the first a stranger, the last a mourner. Seven bells, seven keys: the seventh door has no one's lease."),
  ("Mu", "Say that again. 'The first a stranger to the bell.'"),
  ("Fergus", "Old verse. Nobody knows who wrote it. My gran sang it to put me down. Why, does it fit?"),
  ("Mu", "...I don't know yet."))
d("edin_fergus_again",
  ("Fergus", "Here's another: the Long Silence comes for names first, then faces, then the ones who held them. Cheerful, isn't it? Drink up."))

d("edin_euphemia",
  ("Euphemia", "The Archive closes at dusk, and it is well past dusk. You want the vault plans? Those are under Burgh seal."),
  ("Euphemia", "Unless a mason of repute will vouch for you. Duncan Rae, perhaps. Come back with his mark."))
d("edin_euphemia_mark",
  ("Euphemia", "Duncan's mark. He hasn't vouched for anyone since the old Provost. Very well, look at this."),
  ("Euphemia", "The parish register of 1631. See how the ink leaves the page from the margin inward? Three parishes now. Names fading, as though nobody ever bore them."),
  ("Mu", "The Long Silence. In a ledger."),
  ("Euphemia", "Then you know more than the Burgh does. Take this Warrant of Descent to Hamish at the vault gate. And Mr Mu: bring the ink back."),
  (N, "You receive the Warrant of Descent. The vault gate will open.", "edin_writ"))
d("edin_euphemia_again",
  ("Euphemia", "The warrant is signed. Go, before the ink fades from it too."))
d("edin_euphemia_after",
  ("Euphemia", "The names have stopped fading. I've re-inked what I could. Thank you. I never thought I'd say that to someone with a sword in my reading room."))

d("edin_ruaridh",
  ("Ruaridh", "She's been copying names for three nights. Just names. Whose? Nobody's, now."))

# Secrets (shown after pickup text); keyed by object id
SECRETS = {
    "e_grave1": "Here lies Agnes Thorn, bell-founder's widow. 'She rang once and the town remembered.' Moss has crept over the last word.",
    "e_grave2": "Hugh Lennox, 1590-1644. 'He mended what others only measured.' A tiny bell is carved at the foot of the stone.",
    "e_grave3": "The stone is smooth. No name, no date. A fresh posy lies at its foot, though nobody remembers whose it is.",
    "e_statue": "A bronze founder, a bell cradled in her arms. 'MARGARET THE CASTER: She taught the town to speak with one voice.' The bell's lip is worn bright by a thousand hands.",
    "e_urn": "Behind the urn, wrapped in oilcloth: a Silver Bell Pin. Rab was right.",
    "e_crate": "A wedge of Duncan's chalk, and a lead Mason's Level, lighter than it looks. The bubble inside has stopped, forever, dead centre.",
    "e_chest": "The chest is crammed into a crack of the Close. Inside, wrapped in a child's mitten: a small red stone that beats like a heart. Your vitality grows.",
    "e_barrel": "The second barrel really does hold tea. It also holds a very small boy's footprint.",
    "c_trunk": "Tomas's sketchbook. Page after page of vault arches, each with a tiny bell pencilled in every seventh course. Isolde would want this.",
    "c_shelf": "Marta's spool of blue thread, half used. The tail is knotted to a note: 'For T. and I., so you can always find the door.'",
    "c_urn": "A chipped blue mug marked 'ISOLDE'. Still faintly smelling of tea.",
    "m_crate": "Tomas's chisel, wrapped in a rag. The handle is bound in blue thread.",
    "m_barrel": "Slaked lime and old nails. Someone has chalked a bell on the lid.",
    "m_stone": "A half-dressed block. Faint marks across it: small bells, every seventh course.",
    "i_barrel": "Peat whisky, strong enough to strip a boot. Fergus's Lost Whistle rattles at the bottom.",
    "i_chest": "The innkeeper's strongbox, open. A single page inside: 'Ring the bells of the dead, and the dead will wait. Silence the bells, and the dead will walk.'",
    "i_crate": "Tallow ends and rushlight stubs. A candle stub leans, stubbornly, toward the south.",
    "a_tomes1": "The register of 1631, a single leaf torn out and kept: ink fading from the margin inward. Names, drifting away.",
    "a_tomes2": "'A History of the Seven Founders.' The chapter on the First Bell has been neatly razored out. The binding still smells of lamp-oil and iron.",
    "a_urn": "A dusty jar of sealing wax and a Seal of the Burgh. Evidently the clerk has never been tempted. Evidently.",
}

# ---------------------------------------------------------------- PRAGUE
d("pra_arrive",
  (N, "Prague. The portal leaves you at the edge of the Old Town Square, where an astronomical clock tells the hour, the month, and the position of the dead."),
  ("Isolde", "I've never seen a city with so many towers."),
  ("Mu", "Or so few people in the streets."),
  ("Isolde", "Shutters closed, doors barred. This city is afraid of its own clock."),
  (N, "Explore the Old Town. The Ossuary gate will not open for strangers; someone here must vouch for you."))

d("pra_gate_locked",
  (N, "The great iron door under the Clock Tower is barred. A brass plate reads: 'ONLY BY THE KEEPER'S PASS.'"),
  ("Isolde", "Then we find someone who can give us one."))

d("pra_jan",
  ("Captain Jan", "Halt. The Ossuary beneath the Clock Tower is sealed since the Revenant began counting. Four of my men went down. Their hourglasses came out empty."),
  ("Captain Jan", "No one passes without the Keeper's pass. Not the Emperor himself, if he came."))
d("pra_jan_again",
  ("Captain Jan", "The Clock-Keeper's lodge issues the passes. The girl there, Lucie, but she'll not speak to strangers. Try the Raven first."))
d("pra_jan_pass",
  ("Captain Jan", "Lucie's hand and the Keeper's seal. Then go. May God count your hours kindly."))
d("pra_jan_after",
  ("Captain Jan", "The clock has stopped counting. My men are dust, but the Revenant can't take any more of ours. I'll light a candle for each of them. And for you."))

d("pra_eliska",
  ("Eliska", "Black roses, white roses! Only roses that keep. Everything else wilts when the Clock strikes. Even the bread goes stale between the chimes."),
  ("Eliska", "A girl named Wren steals my firewood. She leaves a coin when she can. She said her brother works the Clock."))
d("pra_eliska_again",
  ("Eliska", "Pavel, her brother. Quiet boy, good with gears. He used to wind the small clock for pennies. Haven't seen him since the Clock began to count."))
d("pra_eliska_after",
  ("Eliska", "The clock strikes true again. I'll sell the white roses to the families of the missing. They've earned a few days' petals."))

d("pra_marketa",
  ("Sister Marketa", "These statues were set by the old masons who raised the gargoyles. If a gargoyle's stone is warm, it's listening."),
  ("Sister Marketa", "A tower-warden once told me they lend their weight to anyone brave enough to ask. I've never been brave enough."))
d("pra_marketa_again",
  ("Sister Marketa", "Heavy things break light walls. Light things slip through bars. The masons built the tower to answer to both."))
d("pra_marketa_after",
  ("Sister Marketa", "Warm stones, silent clock. I think the gargoyles are sleeping. Let them."))

d("pra_zdenek",
  ("Zdenek", "Mind the vapours. I am trying to distil silence. Failing: it comes out as merely less noise."),
  ("Zdenek", "Corvin was my student before he was a Clock-Keeper. The Clock must be wound by a living hand, you see. Something has found a way to wind it with a dead one."),
  ("Mu", "Then how do we stop it?"),
  ("Zdenek", "Find the heart of the works. Brass doors with gear-shaped locks want the Clockmaker's key. Walls that ring hollow want something heavy. Narrow bars want something light."))
d("pra_zdenek_again",
  ("Zdenek", "Heavy for walls, light for bars. Write it down. I forget everything but the formulae."))

d("pra_lucie",
  ("Lucie", "The lodge is closed. Master Corvin went down to the Clock three weeks ago and did not come up."),
  ("Lucie", "If you want the Keeper's pass, ask at the Raven. Old Jiri watched the tower longer than anyone. If he trusts you, so will I."))
d("pra_lucie_pass",
  ("Lucie", "Jiri sent you? Then he's finally talking. Here: the Keeper's pass, stamped with Master Corvin's seal."),
  ("Lucie", "And please. If you find Pavel, the boy who slept in the attic, tell him his sister waits with a candle. Her name is Wren. She is the only one who ever visited."),
  (N, "You receive the Keeper's Pass. The Ossuary gate will open.", "pra_pass"))
d("pra_lucie_again",
  ("Lucie", "Go carefully. The pass opens the gate, not the Revenant."))
d("pra_lucie_after",
  ("Lucie", "You found them? The Revenant is down? Then the lodge reopens at dawn. Thank you, bell-ringer. Thank you."))

d("pra_jiri",
  ("Old Jiri", "...Eh? Don't speak so loud. The Clock listens. I watched that tower fifty years, and when it began counting backward I knew."),
  ("Old Jiri", "The Revenant isn't hunting. It's keeping. Whatever it winds, it holds for something older underneath."),
  ("Old Jiri", "Tell Lucie old Jiri says it's time. She'll know.", "pra_rumour"))
d("pra_jiri_again",
  ("Old Jiri", "Everything it winds, it winds on purpose. Be wary of kindness down there. It baits things."))

d("pra_anezka",
  ("Anezka", "Welcome to the Sleeping Raven. Beer, bread and bad dreams. The bread is included."),
  ("Anezka", "Old Jiri's by the fire. He hasn't slept since the Clock started. Be kind to him, he knows more than he says."))
d("pra_anezka_again",
  ("Anezka", "The Raven's never been so quiet. I'd give a week's takings for a brawl."))

d("pra_milos",
  ("Milos", "Seven bells, seven towns. See my chart? Edinburgh is already inked over: mended. Prague is next. After that the road goes east."),
  ("Milos", "I haven't drawn the Hollow Keep. Every surveyor I sent returned with the same blank sheet."),
  ("Milos", "The bells lie on a spiral. The farther from Edinburgh, the older the bell. The seventh, under Rome, is the oldest, and it does not ring. It listens."))
d("pra_milos_again",
  ("Milos", "Heed the spiral. The further you go, the quieter it gets."))

d("pra_pavel_note",
  (N, "In the attic, a narrow cot, a tin soldier on the pillow, and a scrap of paper in a child's careful hand: 'Wren, if the Clock takes me, keep my scarf. It's red so you can find me.'"),
  ("Mu", "He knew."))

SECRETS.update({
    "p_statue1": "A weathered saint holding a gear and a lantern. 'Bring light to those who count in the dark.' The base is warm under your hand.",
    "p_statue2": "A stone gargoyle, mid-yawn. Someone has tied a ribbon round its horn. Marketa, probably.",
    "p_urn1": "Under a loose cobble: a Hussite Pilgrim's Badge, the iron worn smooth by prayer.",
    "p_urn2": "A single brass Orrery Cog, still warm. It ticks faintly in your palm.",
    "p_barrel": "Wren's cache: three small coins and a stolen heel of bread, hidden with great care. You decide to leave the coins. The bread is already mostly crumbs.",
    "p_crate": "Packed in straw: a Star Chart Fragment showing the sky over Prague on the night the Clock first struck backward. A pencilled note says 'ENT. TOWER 3 A.M.'",
    "p_chest": "In a crack behind the tavern: a heavy brass box. Inside, a small glass vial of glowing gold. You drink it. Your vitality grows.",
    "z_barrel": "Distilled aqua vitae, marked 'DO NOT TASTE'. Someone has tasted it. A lot.",
    "z_urn": "A vial of Philosopher's Salt. It hums at the same pitch as your bell.",
    "z_tomes": "'On the Distillation of Silence' by Z. Hrad. Every page after the second is blank. The author has noted: 'It works.'",
    "l_trunk": "Corvin's Winding Notes: thirty years of wind-up schedules. The last entry, three weeks old: 'It's learning my tune. Do not let the boy near it.'",
    "l_pavel": "Pavel's tin soldier, painted blue, one arm chipped. You tuck it into your pack for Wren.",
    "l_shelf": "A rack of tiny keys, each labelled with a clock-hand shape. One has a note: 'Key to the heart of the works. Do NOT lose.' It's already gone.",
    "t_barrel": "Small beer, mostly. At the bottom of the barrel a rosary of knucklebone beads: the Ossuary Rosary. Anezka says it came with the cellar.",
    "t_crate": "A fistful of candle ends, each one burned to precisely the same height. Eerie.",
    "t_chest": "Anezka's savings, in a sock. You put it back.",
    "m_chart1": "A copy of the seven-bell spiral, annotated in different inks. The seventh circle is blank except for a single word: 'Listening.'",
    "m_chart2": "Rolled maps of the Clock Tower. The undercroft is marked with the same bell sigil you've seen in Edinburgh.",
    "m_urn": "Cartographer's ink, dried to a black crust. Someone has sketched a tiny bell in the crust.",
})

ITEMS = {
    "e_urn": "Silver Bell Pin", "e_crate": "Mason's Level", "e_chest": "Heart of the Old Town",
    "e_barrel": "Rab's Tea Tin",
    "c_trunk": "Tomas's Sketchbook", "c_shelf": "Marta's Blue Thread", "c_urn": "Isolde's Blue Mug",
    "m_crate": "Tomas's Chisel", "m_stone": "Bell-marked Stone",
    "i_barrel": "Fergus's Whistle", "i_chest": "The Warning Page",
    "a_tomes1": "Register Leaf of 1631", "a_tomes2": "Razored History",
    "p_urn1": "Pilgrim's Badge", "p_urn2": "Orrery Cog", "p_crate": "Star Chart Fragment",
    "p_chest": "Heart of the Golden Lane", "p_barrel": "Wren's Cache",
    "z_urn": "Philosopher's Salt", "z_tomes": "Book of Silence",
    "l_trunk": "Corvin's Winding Notes", "l_pavel": "Pavel's Tin Soldier",
    "t_barrel": "Ossuary Rosary",
    "m_chart1": "Seven-Bell Spiral",
}
