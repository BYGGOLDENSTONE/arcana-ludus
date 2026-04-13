# Arcana Ludus — Project CLAUDE.md

## Project Overview
- **Engine:** Godot 4 (GDScript)
- **Genre:** 2D Roguelike Deckbuilder (score-chasing, Balatro-inspired)
- **Theme:** Real tarot mechanics gamified — spreads, reversed cards, elemental chains, Veil mechanic
- **Architecture:** Component-based, signal-driven, data-driven definitions
- **Native Language:** English (code, assets, UI)
- **Target Price:** $12.99–$14.99
- **Art:** Classic Rider-Waite-Smith public domain tarot (1909)
- **Repo:** github.com/BYGGOLDENSTONE/arcana-ludus

## Current Phase
- **Phase:** Phase 5 (Veil & Talismans) — IN PROGRESS
- **Target:** Playable Steam Demo (Act I, full juice)
- **Completed:** 5.1 Veil System, 5.2 Talisman Framework, 5.3 Demo Talismans (17), 5.4 Major Arcana Effects (22 cards)
- **Next Step:** Phase 6 — Juice & Polish
- **Upcoming:** Phase 7 — Content & Balance

## Development Rules

### Code Rules
- **Language:** GDScript only (no C#, no GDExtension)
- **Architecture:** Component-based nodes. Each system is a reusable component
- **Signals:** Use EventBus (autoload) for cross-system communication. Direct signals for parent-child
- **Data-driven:** Cards, spreads, talismans, querents defined as Resource files or JSON. No hardcoded game data
- **Naming:** snake_case for files/variables/functions, PascalCase for classes/nodes, UPPER_CASE for constants
- **Comments:** English only. Only where logic isn't self-evident

### Art Rules
- **Card images:** Use downloaded RWS JPGs from `assets/cards/original/` (public domain 1909 art)
- **All other visuals:** Generate as SVG — card frames, card backs, UI elements, icons, talisman icons, spread backgrounds, Veil eye, particles
- **Do NOT use the name "Rider-Waite"** — it's trademarked. Use "classic tarot" or the game's own deck name
- **Color palette:** Deep midnight blues/navy, gold/amber accents, candlelight warmth (no purple)
- **Typography:** Serif for card names (mystical), sans-serif for numbers/UI (readability)

### Design Rules
- **Tarot authenticity first:** Never break real tarot rules. Gamification layers ON TOP
- **Tarot knowledge = intuitive advantage:** Card-position meaning matches, suit associations, reversed logic — all mirror real tarot
- **Balatro-level juice:** Every scoring event needs visual weight — screen shake, particles, number animations, sound
- **Dual audience:** Tarot enthusiasts AND deckbuilder fans are both first-class citizens
- **Teach through play:** Non-tarot players learn tarot by playing. Grimoire, tooltips, match preview glow

### Git Rules
- Commit and push after completing each phase
- Meaningful commit messages in English
- No force push to main

## Key Design Pillars
1. **Authentic Tarot** — Real tarot rules are foundation. Gamification on top, never contradicts
2. **Score-Chase Dopamine** — Balatro-level visual feedback. Numbers cascade, multipliers explode
3. **Meaningful Choices** — Every card placement is a strategic decision
4. **Dual Audience** — Tarot enthusiasts feel intuitive mastery + deckbuilder fans feel strategic depth
5. **Run Variety** — Every run feels different through querents, talismans, deck evolution, Veil

## Documents
- `docs/GDD.md` — Full Game Design Document (all mechanics, cards, systems)
- `docs/DEMO_PLAN.md` — 8-phase demo development roadmap

## Architecture

### Autoload Singletons (9)
- `GameManager` — run state, current act/querent, lives, gold, reputation, night tracking
- `DeckManager` — player deck, draw pile, discard, hand, sideboard (removed cards still owned)
- `ScoreManager` — scoring engine with per-row partial scoring + full resolution (arcana effects, chains, combos, Veil tier bonuses, talisman hooks)
- `VeilManager` — Veil value 0-11, tier tracking (Clear/Glimpse/Gaze/Abyss/Void), card-based accumulation/reduction, target score adjustment, The Void death
- `TalismanEffects` — defines all talisman effect hook callables (17 talismans implemented)
- `TalismanManager` — active talismans (max 5), hook system (before_reading, on_card_place, on_score, on_chain, after_reading)
- `DataLoader` — loads card/spread/talisman/querent definitions from JSON
- `AudioManager` — SFX and music bus management
- `EventBus` — global signal bus for cross-component communication

### Key Managers
- `NightManager` (scripts/managers/) — orchestrates night flow: querent generation → reading → result → next querent or night end

### Key Resources
- `CardData` (scripts/resources/) — card properties, from_dict()
- `SpreadData` / `SpreadPositionData` — spread layout definitions
- `QuerentData` (scripts/resources/) — client properties, from_dict()
- `QuerentGenerator` (scripts/utils/) — procedural querent generation with night-scaled difficulty
- `ChainDetector` (scripts/utils/) — elemental chain detection (same-suit adjacency groups)
- `ComboDetector` (scripts/utils/) — cross-element combos and numerological combos
- `ArcanaEffects` (scripts/utils/) — all 22 Major Arcana upright/reversed scoring effects

### Project Structure
```
res://
├── assets/
│   ├── cards/original/     # 78 RWS JPGs (public domain)
│   ├── data/               # JSON data (card meanings, metadata)
│   ├── fonts/
│   ├── audio/
│   ├── svg/                # All generated SVG assets
│   └── ui/
├── components/             # Reusable game components
│   ├── card/
│   ├── spread/
│   ├── scoring/
│   ├── veil/
│   ├── talisman/
│   └── ui/
├── data/                   # Game-specific resource definitions
│   ├── cards/
│   ├── spreads/
│   ├── talismans/
│   └── querents/
├── scenes/
│   ├── main_menu/
│   ├── game/
│   ├── shop/
│   └── shared/
├── scripts/
│   ├── autoload/           # 7 singleton scripts
│   ├── managers/
│   └── utils/
├── shaders/
└── docs/
```

## Assets
- `assets/cards/original/` — 78 RWS card images (350×600 JPG, public domain)
  - Major Arcana: `m00.jpg` (The Fool) through `m21.jpg` (The World)
  - Cups: `c01.jpg`–`c14.jpg` | Pentacles: `p01.jpg`–`p14.jpg`
  - Swords: `s01.jpg`–`s14.jpg` | Wands: `w01.jpg`–`w14.jpg`
- `assets/data/card_meanings.json` — Upright/reversed meanings for all 78 cards
- `assets/data/tarot-images.json` — Card name → image filename mapping
- `assets/data/tarot.json` — Basic card metadata (name, number, suit)

## Core Loop — Night System (Implemented)
- **1 Night = 1 Round** — Player serves clients; night ends by player choice (after min clients) or when deck runs out
- **Row-by-Row Placement (Phase 4.5):** No drag-and-drop. Player clicks cards to select (max 3), presses Space to confirm. Rows resolve in order: Past → Present → Future
  - **Past:** Select 3 cards from 12-card hand → Space to place → row scores immediately
  - **Present:** Select 3 from remaining 9 → Space to place → scores + combos with Past
  - **Future:** Select 3 from remaining 6 → Space to place → FULL scoring (combos with Past + Present). 3 unused cards return to deck
  - **Card position within row doesn't matter** — auto-assigned left to right
  - **Right-click to reverse** a selected card before confirming
- **Hand:** Draw 12 cards per client, place 9 (3 per row), 3 unused return to deck
- **Starting deck:** 22 Major Arcana. Minor Arcana acquired through shop
- **Reputation:** Rejecting/failing clients lowers reputation → less gold earned (0.5x–1.5x multiplier)
- **Escalation:** Target scores scale by night number (~120 + night×100), small variance within a night
- **Gold scaling:** Base reward + 10% of score exceeding target as bonus gold
- **Night end:** After min querents (3+night), Reject becomes "End the Night". Player can continue or stop
- **Shop between nights:** Card packs (buy Minor Arcana), deck management (remove/return via sideboard)
- **Scenes:** GameScene (main entry) → ReadingScene (card placement) → ShopScene (between nights)

## Demo Scope
- 62 cards (22 Major Arcana + 40 Minor Arcana Ace-10, no Court cards)
- 1 spread (3×3 Past/Present/Future grid)
- Multiple clients per night, night ends when deck runs out
- 17 talismans (10 Common, 5 Uncommon, 2 Rare)
- Full scoring, chains, combos, Veil, shop, tutorial, Grimoire

## Completed Work
- [x] Market research
- [x] Competitive analysis (Tarogue, others)
- [x] Gameplay design discussions
- [x] GDD v1.0 written
- [x] Demo development plan written
- [x] Tarot card images downloaded (78 cards)
- [x] Card meanings data downloaded
- [x] Git repo created, initial commit pushed
- [x] Phase 1: Foundation
- [x] Phase 2: Core Mechanics
- [x] Phase 3: Game Loop
- [x] Phase 4: Chains & Combos
- [x] Phase 4.5: Placement Refactor (row-by-row click-select, row reveal + 3-card batch placement)
- [x] Phase 5: Veil & Talismans (5.1 Veil, 5.2 Framework, 5.3 Talismans, 5.4 Major Arcana Effects)
- [ ] Phase 6: Juice & Polish
- [ ] Phase 7: Content & Balance
- [ ] Phase 8: Demo Release Prep
