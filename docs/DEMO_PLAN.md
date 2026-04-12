# Demo Development Plan
### Phased Implementation Roadmap

**Target:** Playable Steam Demo (Act I complete, full juice)  
**Engine:** Godot 4, GDScript, Component-Based Architecture  
**Architecture:** Component-based nodes, signal-driven, data-driven card/spread definitions  

---

## Phase Overview

| Phase | Focus | Deliverable |
|-------|-------|------------|
| **Phase 1** | Foundation | Project architecture, card data system, basic card rendering |
| **Phase 2** | Core Mechanics | Spread placement, upright/reversed, scoring engine |
| **Phase 3** | Game Loop | Querent system, shop, run flow, lives |
| **Phase 4** | Chains & Combos | Elemental chains, cross-element combos, numerological combos |
| **Phase 5** | Veil & Talismans | Veil system, talisman framework, 17 talismans |
| **Phase 6** | Juice & Polish | Scoring animations, shaders, particles, screen shake, SFX |
| **Phase 7** | Content & Balance | All 62 demo cards tuned, boss querent, tutorial, Grimoire |
| **Phase 8** | Demo Release Prep | Steam integration, settings, accessibility, bug fixing |

---

## Phase 1 — Foundation

### Goal
Establish project architecture and render cards on screen.

### Tasks

**1.1 Project Structure**
```
res://
├── assets/
│   ├── cards/
│   │   └── original/        # Downloaded RWS images (78 JPGs)
│   ├── data/
│   │   └── card_meanings.json
│   ├── fonts/
│   ├── audio/
│   └── ui/
├── components/               # Reusable components
│   ├── card/
│   ├── spread/
│   ├── scoring/
│   ├── veil/
│   ├── talisman/
│   └── ui/
├── data/                     # Game data definitions
│   ├── cards/                # Card definitions (resource files)
│   ├── spreads/              # Spread layouts
│   ├── talismans/            # Talisman definitions
│   └── querents/             # Querent definitions
├── scenes/                   # Game scenes
│   ├── main_menu/
│   ├── game/
│   ├── shop/
│   └── shared/
├── scripts/                  # Core systems
│   ├── autoload/             # Singletons
│   ├── managers/             # Game state managers
│   └── utils/                # Helpers
├── shaders/                  # Visual effects
└── docs/                     # Design documents
```

**1.2 Autoload Singletons**
- `GameManager` — run state, current act/querent, lives
- `DeckManager` — player deck, draw pile, discard, hand
- `ScoreManager` — scoring engine, combo detection
- `VeilManager` — Veil counter, tier tracking
- `DataLoader` — loads card/spread/talisman definitions from JSON/resources
- `AudioManager` — SFX and music bus management
- `EventBus` — global signal bus for cross-component communication

**1.3 Card Data System**
- Parse `card_meanings.json` into CardData resources
- CardData resource: name, number, suit, type (major/minor/court), base_insight, upright_effect, reversed_effect, position_affinities, veil_impact, texture_path
- Create CardData for all 62 demo cards
- Card visual: Node2D with sprite, frame overlay (SVG), name label, value label

**1.4 Basic Card Rendering**
- Card scene: displays card image with custom SVG border frame
- Card back design
- Card flip animation (upright ↔ reversed with 3D rotation feel using shader)
- Hand display: fan of cards at bottom of screen
- Basic drag-and-drop from hand

### Deliverable
Cards render on screen, can be dragged, flipped between upright/reversed.

---

## Phase 2 — Core Mechanics

### Goal
Place cards into spreads and calculate basic scores.

### Tasks

**2.1 Spread System**
- SpreadData resource: positions array (each with: name, meaning, suit_affinities, number_affinities, major_arcana_affinities, screen_position)
- SpreadRenderer: draws spread layout with position slots
- Position slot: visual target area with meaning label and affinity indicators
- Define Three-Card Spread and Five-Card Cross

**2.2 Card Placement**
- Drag card from hand → drop onto spread position
- Snap-to-position with satisfying animation
- Before dropping: show match quality preview (glow color)
- After dropping: card locks into position
- Orientation choice: right-click or button to toggle upright/reversed before placing

**2.3 Match Detection**
- Calculate card-position match level: Perfect / Good / Neutral / Mismatch
- Based on: suit affinity, number affinity, specific Major Arcana affinity
- Visual feedback: glow colors on hover

**2.4 Basic Scoring Engine**
- Per-card Insight calculation (base + position bonus)
- Per-card Resonance calculation (match multiplier)
- Spread total: sum of (Insight × Resonance) per card
- Display running score
- "Read" button to trigger scoring sequence

### Deliverable
Place cards into 3-card spread, see match quality, trigger scoring, see final score.

---

## Phase 3 — Game Loop

### Goal
Complete querent-to-querent game flow.

### Tasks

**3.1 Querent System**
- QueuentData resource: name, portrait, question_theme, personality_type, target_score, reward, special_condition
- Querent arrival screen: shows name, question, target score
- Generate querents procedurally from theme/personality pools
- Querent result screen: score vs target, success/failure

**3.2 Deck & Hand Management**
- Starting deck (22 Major Arcana)
- Shuffle deck → draw hand (5-7 cards)
- After reading: discard placed cards, unused hand cards return to deck
- Between querents: reshuffle

**3.3 Run Flow**
- Run start → Act I
- Querent sequence: arrival → spread select → placement → scoring → result → shop
- Lives system: 3 candles, lose 1 on failed reading
- Run end: all lives lost OR boss defeated
- Score summary screen

**3.4 Shop**
- Shop scene between querents
- Card pack (pick 1 of 3 random Minor Arcana)
- Card removal
- Talisman purchase (placeholder — just displays, no effects yet)
- Gold tracking

### Deliverable
Full run loop: querents arrive, player reads, scores, shops, repeat. Win/lose conditions.

---

## Phase 4 — Chains & Combos

### Goal
Implement the combo system that makes scores explode.

### Tasks

**4.1 Elemental Chain Detection**
- Scan spread for consecutive same-suit cards
- Calculate chain length → apply Resonance multiplier (×1.5 / ×2.5 / ×4.0 / ×7.0)
- Ace as chain starter bonus (+2 Resonance/card)
- 10 as chain closer bonus (chain ×1.5)
- Visual: draw connecting line between chained cards

**4.2 Cross-Element Combos**
- Detect adjacent different-suit pairs → trigger combo effects
- Steam, Wildfire, Growth, Erosion, Forge, Storm
- Apply effects during scoring resolution

**4.3 Numerological Combos**
- Detect ascending/descending runs, pairs, triples, quads
- Apply bonuses during scoring

**4.4 Scoring Resolution Order**
- Define strict resolution order:
  1. Base Insight per card
  2. Position match bonuses
  3. Card-specific effects (upright/reversed)
  4. Chain multipliers
  5. Cross-element combos
  6. Numerological combos
  7. Talisman effects
  8. Veil tier modifiers
  9. Querent theme bonus

### Deliverable
Chains and combos detected and scored. Scores now can reach exciting multiplied values.

---

## Phase 5 — Veil & Talismans

### Goal
Add risk/reward depth and build variety.

### Tasks

**5.1 Veil System**
- VeilManager: tracks Veil value 0-11
- Accumulation from reversed cards, dark Arcana, Storm combo
- Tier detection (Clear/Glimpse/Gaze/Abyss)
- Tier effects on scoring (reversed card Resonance bonuses)
- Tier costs (target score increases)
- Veil reduction (Sun, Star, Temperance, 6s, all-upright reading)
- Run death at Veil 11 (The Void)
- Cleanse ritual option (skip querent)

**5.2 Talisman Framework**
- TalismanData resource: name, description, tier, effect_type, effect_params, cost
- TalismanSlot UI: displays active talismans (max 5)
- Talisman effect hooks: before_reading, on_card_place, on_score, on_chain, after_reading
- Component-based talisman effects (each talisman = script implementing hooks)

**5.3 Demo Talismans (17 total)**
- Implement 10 Common, 5 Uncommon, 2 Rare talismans
- Connect to shop system (buy/sell talismans)
- Talisman synergy testing

**5.4 Major Arcana Effects**
- Implement all 22 Major Arcana upright/reversed unique effects
- Hook into scoring resolution
- Test each card in various positions

### Deliverable
Veil creates tension, talismans create builds, Major Arcana feel powerful and unique.

---

## Phase 6 — Juice & Polish

### Goal
Make the game FEEL incredible. This is not optional polish — this is core gameplay.

### Tasks

**6.1 Scoring Animation System**
- Sequential card reveal with dramatic timing
- Per-card: Insight number rises → position glow → chain line draws → multiplier EXPLODES
- Screen shake proportional to multiplier magnitude
- Running total ticker with acceleration
- Final score: celebration vs. failure animation

**6.2 Card Shaders**
- Card glow shader (parameterized color: gold/green/red/purple)
- Card hover parallax (subtle 3D tilt)
- Reversed card aura (purple shimmer)
- Card placement "thunk" animation (scale bounce + shadow)
- Card breathing idle animation

**6.3 Elemental VFX**
- Fire particles for Wands chains
- Water flow particles for Cups chains
- Wind/slash particles for Swords chains
- Earth/crystal particles for Pentacles chains
- Cross-element combo: full-screen flash + unique effect

**6.4 Veil Visual Effects**
- Eye icon that progressively opens
- Screen edge mist/tendrils (shader) at Glimpse+
- Purple particle overlay at Gaze+
- Pulsing darkness at Abyss
- Void death sequence animation

**6.5 UI Polish**
- Smooth transitions between game states
- Button hover/press animations
- Gold counter animation (coins flying)
- Life candle flame animation (flicker, extinguish on death)
- Querent portrait entrance animation

**6.6 Score Number Effects**
- Numbers that grow/shrink with easing
- Color coding (white → yellow → orange → red as value increases)
- Particle trails on big numbers
- Combo name text that pops on screen ("WILDFIRE!" "ECLIPSE!")

### Deliverable
The game feels explosive and satisfying. Non-tarot players are hooked by game feel alone.

---

## Phase 7 — Content & Balance

### Goal
All demo content complete, balanced, and tutorialized.

### Tasks

**7.1 Card Balance Pass**
- Playtest all 62 cards across spreads
- Tune base Insight values
- Tune chain multipliers for satisfying progression
- Ensure no dominant strategy (all suits viable)
- Ensure Veil dark build viable but risky

**7.2 Querent Balance**
- 6 normal querents with escalating target scores
- 1 boss querent with special rules
- Target scores tuned: beatable with average play, high scores for skilled play
- Personality modifiers balanced

**7.3 Talisman Balance**
- Ensure no talisman is must-pick
- Ensure talisman combos feel powerful but not broken
- Price tuning relative to gold economy

**7.4 Tutorial**
- 3 guided readings teaching: placement, suits/chains, reversed/Veil
- Non-intrusive (short prompts, not text walls)
- Skippable on subsequent runs

**7.5 Grimoire**
- In-game encyclopedia UI
- Card entries: art, name, meanings, effects, affinities
- Combo reference page
- Spread reference page
- Entries unlock as encountered

**7.6 Economy Balance**
- Gold earn rate vs. shop prices
- Card acquisition rate (deck building speed)
- Talisman affordability per run
- Interest mechanic testing

### Deliverable
Demo is complete, balanced, educational, and fun from start to finish.

---

## Phase 8 — Demo Release Prep

### Goal
Ready for Steam Next Fest / public demo release.

### Tasks

**8.1 Main Menu**
- Start Run, Grimoire, Settings, Quit
- Atmospheric background (animated tarot table)
- Title card with game logo

**8.2 Settings**
- Resolution / windowed / fullscreen
- Audio volumes (music, SFX)
- Intuition Hints toggle
- Visual effects intensity (for performance)
- Language (English at launch)

**8.3 Accessibility**
- Colorblind mode (match indicators use shapes + colors)
- Text size options
- Screen shake intensity slider
- Reduced motion option (disables particles, simplifies animations)

**8.4 Performance**
- Profile and optimize
- Target: 60fps on integrated graphics
- Particle budget management
- Shader compilation pre-warming

**8.5 Steam Integration**
- Steam App ID setup
- Achievements (demo set: first win, first chain of 5, first Abyss, etc.)
- Wishlist prompt at demo end

**8.6 Bug Fixing & QA**
- Full playthrough testing (all querent types, all personality types)
- Edge case testing (empty hand, max Veil, 0 gold, etc.)
- Crash testing
- Memory leak check

**8.7 Demo End Screen**
- Score summary
- "This is just Act I. The full game has..."
- Wishlist CTA
- Social media links

### Deliverable
Polished, stable demo ready for public release.

---

## Asset Checklist

### Art Assets
| Asset | Source | Status |
|-------|--------|--------|
| 78 card images (RWS) | Downloaded from GitHub (metabismuth/tarot-json) | ✅ Done |
| Card frame SVG | Custom design | ⬜ To create |
| Card back design | Custom design | ⬜ To create |
| Spread backgrounds | Custom / procedural | ⬜ To create |
| Querent portraits | Generated / drawn | ⬜ To create |
| Talisman icons | Custom design | ⬜ To create |
| UI elements | Custom design | ⬜ To create |
| Veil eye icon | Custom design | ⬜ To create |
| Particle textures | Custom / Godot default | ⬜ To create |

### Audio Assets (Placeholder → Final)
| Asset | Source | Status |
|-------|--------|--------|
| Ambient music tracks | Free / commissioned | ⬜ To find |
| Card place SFX | Free / Foley | ⬜ To find |
| Card flip SFX | Free / Foley | ⬜ To find |
| Score tick SFX | Free / synthesized | ⬜ To find |
| Chain activation SFX | Free / synthesized | ⬜ To find |
| Combo trigger SFX | Free / synthesized | ⬜ To find |
| UI click SFX | Free / synthesized | ⬜ To find |
| Veil ambient SFX | Free / synthesized | ⬜ To find |

### Data Files
| File | Status |
|------|--------|
| card_meanings.json | ✅ Downloaded |
| card_definitions (game-specific) | ⬜ To create from GDD |
| spread_definitions | ⬜ To create from GDD |
| talisman_definitions | ⬜ To create from GDD |
| querent_definitions | ⬜ To create from GDD |

---

*Plan v1.0 — Ready for implementation*
