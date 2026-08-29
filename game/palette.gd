extends RefCounted
class_name Palette
## Single source of truth for colour. Everything visual should pull from here so
## a retheme is one file. Cozy cottage palette: warm creams, honeyed wood, soft
## berry/sage/sky accents.

const BG          := Color("f4ead8")  # page background
const BG_DEEP     := Color("e7d6b8")  # bottom of the page gradient
const INK         := Color("5b4636")  # primary text
const INK_DARK    := Color("3a2f27")
const INK_FAINT   := Color("a8977f")

const CARD        := Color("fbf3e2")  # panel / card fill
const CARD_BORDER := Color("d8c3a0")

const BTN         := Color("efe0c6")
const BTN_HOVER   := Color("f8eed9")
const BTN_PRESSED := Color("e2cda8")
const BTN_DISABLED := Color("e6ddcd")
const BTN_BORDER  := Color("cdb891")

const ACCENT      := Color("f2c14e")  # gold highlight / stars
const ACCENT_WARM := Color("b5654a")  # terracotta

const SHELF       := Color("c79a68")  # wood plank the jars sit on
const SHELF_DARK  := Color("9c7345")
const GLASS       := Color(1, 1, 1, 0.30)
const GLASS_TOP   := Color(1, 1, 1, 0.16)
const GLASS_RIM   := Color("b79b74")

const DIM         := Color(0.20, 0.15, 0.12, 0.74)  # overlay scrim

# Bead / jar-content colours (index-aligned). Authored stages use up to 8;
# endless mode reaches for the 9th once it steps past the palette's first tier.
const BEADS: Array[Color] = [
	Color("d97a6c"), # berry
	Color("e6b45e"), # honey
	Color("8fae7d"), # sage
	Color("9b7bab"), # plum
	Color("7fa8c9"), # sky
	Color("c98f6b"), # clay
	Color("d99abf"), # rose
	Color("6fb0a6"), # teal
	Color("8f8fce"), # iris — periwinkle, endless tier 2
]
