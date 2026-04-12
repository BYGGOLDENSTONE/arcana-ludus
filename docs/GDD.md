# Arcana Ludus — Game Design Document
### Tarot Roguelike Deckbuilder

**Version:** 1.0  
**Date:** 2026-04-12  
**Target:** Steam Demo → Full Release  
**Engine:** Godot 4 (GDScript)  
**Price:** $12.99–$14.99  

---

## Table of Contents

1. [Game Overview](#1-game-overview)
2. [Core Loop](#2-core-loop)
3. [The 78-Card System](#3-the-78-card-system)
4. [Spread System](#4-spread-system)
5. [Scoring System](#5-scoring-system)
6. [Combo & Chain System](#6-combo--chain-system)
7. [Veil System](#7-veil-system)
8. [Querent (Client) System](#8-querent-client-system)
9. [Talisman System](#9-talisman-system)
10. [Shop & Economy](#10-shop--economy)
11. [Run Structure](#11-run-structure)
12. [Meta-Progression](#12-meta-progression)
13. [Readability & Onboarding](#13-readability--onboarding)
14. [Visual Design & Juice](#14-visual-design--juice)
15. [Audio Design](#15-audio-design)
16. [Target Audience](#16-target-audience)
17. [Competitive Positioning](#17-competitive-positioning)
18. [Demo Scope](#18-demo-scope)

---

## 1. Game Overview

### Elevator Pitch
A tarot-reading roguelike deckbuilder where you place cards into spread positions, choose upright or reversed orientation, and chain elemental combos for explosive scores — but peer too deep into the darkness and the Veil consumes you.

### Core Fantasy
You are a tarot reader receiving clients (querents) through the night. Each reading is a puzzle: match the right cards to the right positions, build elemental chains, manage the Veil, and chase ever-higher scores. Tarot knowledge gives intuitive advantage; mechanical mastery rewards everyone.

### Design Pillars

| Pillar | Description |
|--------|-------------|
| **Authentic Tarot** | Real tarot rules are the foundation. Card meanings, suit associations, spread positions, reversed interpretations — all authentic. Gamification layers on top, never contradicts. |
| **Score-Chase Dopamine** | Balatro-level visual feedback. Numbers cascade, multipliers explode, chains light up the screen. Non-tarot players stay hooked through pure game feel. |
| **Meaningful Choices** | Every card placement is a decision: which position, which orientation, which chain to build, how much Veil to risk. No autopilot turns. |
| **Dual Audience** | Tarot enthusiasts feel intuitive mastery. Deckbuilder fans feel strategic depth. Both audiences are first-class citizens. |
| **Run Variety** | Every run feels different through querent variety, talisman combinations, deck evolution, and Veil management style. |

### Key Differentiators (vs. Tarogue, Balatro, etc.)
- Card-position meaning matching as core scoring mechanic
- Active upright/reversed choice every hand (not static draft)
- Querent system shapes each reading's rules
- Veil as player-controlled push-your-luck resource
- Teaches real tarot through play
- Classic Rider-Waite-Smith art (authentic tarot aesthetic)

---

## 2. Core Loop — The Night System

The player is a tarot reader working through the night. Each night, clients arrive seeking readings. The night ends when the deck runs out.

```
              ☽ NIGHT BEGINS ☾
         Deck ready (~30 cards to start)
                    │
    ┌───────────────▼────────────────┐
    │        CLIENT ARRIVES          │◄─────────────┐
    │  Question theme → suit bonuses │              │
    │  Target score → must beat      │              │
    │  Reward → gold on success      │              │
    └───────────────┬────────────────┘              │
                    ▼                               │
    ┌────────────────────────────────┐              │
    │  ACCEPT or REJECT client       │              │
    │  Reject → no cards spent,      │              │
    │  but reputation drops          │              │
    └───────────────┬────────────────┘              │
                    ▼                               │
    ┌────────────────────────────────┐              │
    │  DRAW HAND (10-12 cards)       │              │
    └───────────────┬────────────────┘              │
                    ▼                               │
    ┌────────────────────────────────┐              │
    │  PLACE CARDS — 3×3 SPREAD      │              │
    │  ┌──────┬──────┬──────┐       │              │
    │  │ PAST │ PAST │ PAST │       │              │
    │  ├──────┼──────┼──────┤       │              │
    │  │ PRES │ PRES │ PRES │       │              │
    │  ├──────┼──────┼──────┤       │              │
    │  │ FUT  │ FUT  │ FUT  │       │              │
    │  └──────┴──────┴──────┘       │              │
    │  9 cards placed, rest return   │              │
    │  to deck. For each card:       │              │
    │    • Choose position (match?)  │              │
    │    • Choose orientation         │              │
    │    • Consider suit chains       │              │
    │    • Watch Veil accumulation    │              │
    └───────────────┬────────────────┘              │
                    ▼                               │
    ┌────────────────────────────────┐              │
    │  THE READING (Scoring)         │              │
    │  Cards resolve left→right,     │              │
    │  top→bottom:                   │              │
    │    1. Base Insight              │              │
    │    2. Position match bonus      │              │
    │    3. Suit chain multipliers    │              │
    │    4. Elemental combos          │              │
    │    5. Talisman effects          │              │
    │    6. Veil modifiers            │              │
    │    7. Final score revealed      │              │
    │  ★ FULL VISUAL SPECTACLE ★     │              │
    └───────────────┬────────────────┘              │
                    ▼                               │
    ┌────────────────────────────────┐              │
    │  CLIENT RESULT                 │              │
    │  Beat target? → Gold earned    │              │
    │  Failed? → Reputation drops    │              │
    └───────────────┬────────────────┘              │
                    ▼                               │
    Enough cards for another reading? ──Yes──►──────┘
                    │
                   No
                    ▼
              ☽ NIGHT ENDS ☾
                    ▼
    ┌────────────────────────────────┐
    │  SHOP PHASE                    │
    │  Buy cards (deck grows)        │
    │  Buy talismans                 │
    │  Remove cards (deck tightens)  │
    └───────────────┬────────────────┘
                    ▼
             Next Night...
        (Harder clients, higher targets)
```

### Night Economy
- **Starting deck:** ~30 cards (22 Major Arcana + 8-10 random Minor Arcana)
- **Cards per reading:** 9 placed (from hand of 10-12)
- **Unused hand cards:** Return to deck
- **Deck growth:** Buy Minor Arcana in shop → more clients per night
- **Strategic tradeoff:** Big deck = more clients but weaker hands. Small deck = fewer clients but stronger combos.

### Reputation System
- **Reputation** affects gold earned per successful reading
- **Dropping reputation:** Rejecting clients, failing readings (not meeting target score)
- **Low reputation → clients pay less gold** — harder to afford shop upgrades
- **Design intent:** Prevents players from freely skipping hard clients without consequence

### Session Length
- Target: 25–45 minutes per run (multiple nights)
- Each reading: 2–4 minutes
- Night 1: ~3 clients | Night 3: ~4-5 clients | Late game: 5-6 clients

### Session Length
- Target: 25–45 minutes per run
- Each querent reading: 2–5 minutes
- 8–12 querents per run (including 2–3 bosses)

---

## 3. The 78-Card System

### 3.1 Major Arcana (22 Cards)

The most powerful cards in the deck. High base Insight, unique effects, and strong position affinities. These are the "build-around" cards.

Each Major Arcana has:
- **Base Insight:** 30–50 (vs. Minor Arcana 5–25)
- **Upright Effect:** Aligned with traditional meaning
- **Reversed Effect:** Aligned with traditional reversed meaning
- **Position Affinity:** Which spread positions give bonus Resonance
- **Veil Impact:** Some add Veil (dark cards), some reduce it (light cards)

#### Complete Major Arcana Table

| # | Card | Base Insight | Upright Effect | Reversed Effect | Position Affinity | Veil |
|---|------|-------------|----------------|-----------------|-------------------|------|
| 0 | **The Fool** | 30 | Wild card: counts as any suit for chains. +5 Insight to all cards in spread | Recklessness: shuffles your hand, but gives ×2 Resonance to next card placed | Beginning, Self | 0 |
| I | **The Magician** | 35 | All 4 elements count as present (enables cross-element combos) | Manipulation: choose any card from draw pile, but +2 Veil | Self, Action | 0/+2 |
| II | **The High Priestess** | 35 | Reveal all cards in draw pile for this reading. +10 Insight if Cups present | Hidden knowledge remains hidden: Resonance doubled but you cannot see combo previews | Subconscious, Hidden | 0 |
| III | **The Empress** | 35 | All Cups and Pentacles cards gain +5 Insight. Nurture chain: adjacent cards gain +3 Insight | Stifled growth: one random suit loses -3 Insight, but Major Arcana gain +10 | Foundation, Nurture | 0 |
| IV | **The Emperor** | 35 | All Wands and Swords cards gain +5 Resonance. Structure: position match bonuses ×1.5 | Rigidity: position matches give no bonus, but base Insight of all cards ×1.5 | Authority, Structure | 0 |
| V | **The Hierophant** | 35 | Tradition: same-suit chains need 1 fewer card for bonus tier. +5 to Court cards | Rebellion: chains broken, but each unique suit in spread gives ×1.5 Resonance | Guidance, Tradition | 0 |
| VI | **The Lovers** | 40 | Union: two adjacent cards combine their Resonance. Highest combo potential | Separation: two cards score independently at ×2 each, but cannot chain | Relationship, Choice | 0 |
| VII | **The Chariot** | 35 | Momentum: each card placed after this one gets cumulative +3 Insight | Loss of control: cards score in reverse order, but final card gets ×3 | Action, Willpower | 0 |
| VIII | **Strength** | 35 | Courage: reversed cards give no Veil this reading. +5 Resonance to all | Inner weakness: +3 Veil, but all Resonance ×1.5 | Courage, Inner | -all/+3 |
| IX | **The Hermit** | 30 | Solitude: if this is the only Major Arcana in spread, ×3 Resonance | Isolation: -5 Insight to adjacent cards, but this card's Insight ×3 | Reflection, Solitude | 0 |
| X | **Wheel of Fortune** | 40 | Fate: trigger a random bonus effect (pool of 10 positive effects) | Bad luck: trigger a random penalty, but guaranteed +20 Resonance | Destiny, Change | 0 |
| XI | **Justice** | 35 | Balance: if spread has equal upright and reversed cards, all Resonance ×2 | Imbalance: the dominant orientation (more upright or more reversed) gets ×2, minority gets ×0.5 | Balance, Truth | 0 |
| XII | **The Hanged Man** | 35 | Sacrifice: remove this card from spread, give its Insight to all others | New perspective: all reversed cards count as upright AND reversed (both effects trigger) | Sacrifice, Patience | 0 |
| XIII | **Death** | 40 | Transformation: destroy one card in spread, gain ×3 its Insight as Resonance | Stagnation: nothing is destroyed, all multipliers reduced to ×1, but +30 flat Insight | Transformation, End | +1 |
| XIV | **Temperance** | 35 | Balance: Veil reduced by 2. All cards gain +3 Insight. Smooth scoring | Impatience: Veil +1, but one card of choice gets ×3 Resonance | Healing, Moderation | -2/+1 |
| XV | **The Devil** | 45 | Temptation: ×2 Resonance to entire spread, but +3 Veil | Breaking free: Veil -2, but spread Resonance reduced by 25% | Temptation, Shadow | +3/-2 |
| XVI | **The Tower** | 45 | Destruction: clear all cards and rescore them with ×2 Resonance. High variance, high ceiling | Avoidance: spread is protected from all negative effects this reading, +10 flat Insight | Upheaval, Crisis | +2 |
| XVII | **The Star** | 35 | Hope: Veil -3. All cards gain +5 Insight. Heal 1 life if below max | Despair: no Veil reduction, but +15 Resonance to all reversed cards | Hope, Renewal | -3 |
| XVIII | **The Moon** | 40 | Illusion: all cards gain a random second suit (enables surprise chains) | Clarity: no random effects this reading, all scores are exact (no variance), +10 Insight | Illusion, Fear | +2 |
| XIX | **The Sun** | 40 | Joy: Veil -2, all Insight ×1.3, all cards visible in draw pile | Eclipse: Veil unchanged, but Resonance ×2 for this reading only | Joy, Success | -2 |
| XX | **Judgement** | 40 | Rebirth: retrieve up to 2 cards from discard pile into hand | Avoidance: no retrieval, but all current hand cards gain +10 Insight | Judgement, Rebirth | 0 |
| XXI | **The World** | 50 | Completion: if all 4 suits present in spread → ×5 Resonance | Incomplete: each missing suit reduces Resonance by 25%, but present suits get ×2 | Completion, Wholeness | 0 |

#### Light vs. Dark Arcana

**Light Cards** (reduce Veil): The Star, The Sun, Temperance, Strength (upright)  
**Dark Cards** (increase Veil): Death, The Devil, The Tower, The Moon  
**Neutral Cards**: All others (Veil impact depends on orientation)

### 3.2 Minor Arcana — Suits (4 × 14 = 56 Cards)

#### Suit Identity

| Suit | Element | Theme | Playstyle | Querent Affinity |
|------|---------|-------|-----------|------------------|
| **Wands** | Fire 🔥 | Passion, creativity, action, ambition | Aggressive multipliers — burst scoring, chain explosions | Creativity, career passion, new ventures |
| **Cups** | Water 💧 | Emotion, relationships, intuition, flow | Synergy/connection — cards boost each other, healing | Love, relationships, emotional questions |
| **Swords** | Air 💨 | Intellect, conflict, truth, decisions | Manipulation — card draw, swap, transform, strategic control | Decisions, conflicts, mental clarity |
| **Pentacles** | Earth 🌍 | Material, wealth, stability, health | Economy/accumulation — gold generation, persistent upgrades | Money, career, health, material security |

#### Number Cards (Ace–10) — Numerological Mechanics

Each number has a consistent mechanical identity across all suits, rooted in real tarot numerology:

| Number | Tarot Meaning | Base Insight | Mechanic | Detail |
|--------|--------------|-------------|----------|--------|
| **Ace** | New beginning, potential | 8 | **Chain Starter** | Begins any chain. If placed first in a suit sequence, the entire chain gets +2 Resonance per card |
| **2** | Balance, duality, partnership | 6 | **Pair Bonus** | If another 2 is in the spread (any suit), both gain +5 Insight. Scales: three 2s = +10 each, four 2s = +20 each |
| **3** | Growth, creativity, expansion | 7 | **Growth Trigger** | +1 Insight to all cards placed after this one in the spread |
| **4** | Stability, structure, foundation | 8 | **Foundation Lock** | This position becomes immune to Veil effects and card manipulation. Adjacent cards gain +2 Insight |
| **5** | Conflict, challenge, instability | 10 | **Risk Card** | High base Insight BUT +1 Veil when played. In real tarot, 5s represent difficulty — risk/reward |
| **6** | Harmony, cooperation, balance | 9 | **Harmonizer** | -1 Veil. Adjacent cards gain +3 Insight. The "healing" number |
| **7** | Reflection, assessment, wisdom | 8 | **Scry** | Reveal the next 3 cards in draw pile. Choose 1 to add to hand |
| **8** | Mastery, movement, progress | 10 | **Multiplier** | ×1.5 Resonance to this card's chain. The number of power and flow |
| **9** | Near-completion, wisdom, peak | 12 | **Peak Value** | Highest base Insight among number cards. If in last position of a chain: +10 bonus Insight |
| **10** | Completion, fulfillment, cycle end | 11 | **Chain Closer** | Completes any chain with a bonus: chain Resonance ×1.5. The "capstone" card |

#### Suit-Specific Number Flavoring

While all Ace-through-10 cards share the numerological base mechanic, each suit adds its own flavor:

**Wands (Fire) Specific:**
- Wands chains give ×Resonance bonuses (multiplicative — numbers go up fast)
- Ace of Wands: chain starter + ignites: next Wands card gets ×2
- 10 of Wands: chain closer + burnout: high score but this card cannot be used next reading

**Cups (Water) Specific:**
- Cups chains give +Insight to adjacent non-Cups cards (spreading/flowing)
- Ace of Cups: chain starter + overflow: +3 Insight to ALL cards in spread
- 10 of Cups: chain closer + emotional fulfillment: if querent theme is love/emotion, ×3 Resonance

**Swords (Air) Specific:**
- Swords chains allow card manipulation (draw, swap, peek)
- Ace of Swords: chain starter + clarity: reveal all remaining draw pile cards
- 10 of Swords: chain closer + painful truth: +2 Veil but ×2 Resonance to entire spread

**Pentacles (Earth) Specific:**
- Pentacles chains generate gold and permanent card upgrades
- Ace of Pentacles: chain starter + investment: gain gold equal to chain length × 5
- 10 of Pentacles: chain closer + legacy: permanently upgrade one card in deck (+2 base Insight forever)

#### Court Cards (Page, Knight, Queen, King)

| Court | Tarot Role | Base Insight | Mechanic |
|-------|-----------|-------------|----------|
| **Page** | Youth, message, curiosity | 14 | **Messenger**: Draw 1 extra card to hand. If suit matches querent theme: draw 2 |
| **Knight** | Action, movement, quest | 16 | **Rider**: After placement, may swap positions with one adjacent card. Triggers position-match recalculation |
| **Queen** | Maturity, nurture, inner mastery | 18 | **Matriarch**: All cards of the same suit in spread gain +3 Resonance passively |
| **King** | Authority, control, mastery | 20 | **Sovereign**: All cards of the same suit trigger their effects twice |

**Royal Chain Bonus:** Page → Knight → Queen → King of same suit in one spread = **Royal Court** combo: ×4 Resonance to entire suit chain.

### 3.3 Upright vs. Reversed — The Core Choice

Every card placement requires an orientation decision. This is the game's signature mechanic.

**Upright (Düz):**
- Standard effect activates
- No Veil generated
- Predictable, safe scoring
- Position match bonuses apply normally

**Reversed (Ters):**
- Reversed effect activates (often more powerful but with a cost)
- +1 Veil (base; some cards add more)
- Often higher Resonance potential
- Different position affinities may apply
- Enables "Dark" combos and Veil-tier bonuses

**Design Rule:** Reversed is never strictly better or worse. It's a different path. Some cards are stronger reversed in certain positions; others are stronger upright. Tarot knowledge helps players intuit which is which.

**Example Decision:**
- The Tower Upright in Challenge position: destroys and rescores at ×2 (huge ceiling, risky)
- The Tower Reversed in Challenge position: protects spread + flat bonus (safe, moderate score)
- A tarot reader knows The Tower reversed means "avoiding disaster" — this maps directly to the safe-play mechanic

---

## 4. Spread System — The 3×3 Grid

All readings use the same 3×3 spread: **Past, Present, Future** — each with 3 card slots. This creates a consistent, learnable board while offering deep strategic variety through card placement choices.

### 4.1 The Standard Spread (3×3)

```
┌───────────┬───────────┬───────────┐
│  PAST 1   │  PAST 2   │  PAST 3   │
│ Pentacles+│ Swords+   │ Major+    │
│ High #s   │ Mid #s    │ Any       │
├───────────┼───────────┼───────────┤
│ PRESENT 1 │ PRESENT 2 │ PRESENT 3 │
│ Wands+    │ Any       │ Cups+     │
│ Mid #s    │ Pairs+    │ Mid #s    │
├───────────┼───────────┼───────────┤
│ FUTURE 1  │ FUTURE 2  │ FUTURE 3  │
│ Cups+     │ Major+    │ Wands+    │
│ Aces-3    │ Any       │ High #s   │
└───────────┴───────────┴───────────┘
```

- **Positions:** 9 (3 rows × 3 columns)
- **Cards per reading:** 9 placed from hand of 10-12
- **Scoring order:** Left→right, top→bottom (positions 1-9)

### 4.2 Row Meanings (Time Axis)

| Row | Theme | Suit Affinity | Number Affinity | Tarot Connection |
|-----|-------|---------------|-----------------|------------------|
| **Past** | What has been | Pentacles (stability, roots) | 7-10 (maturity, completion) | The foundation of the reading |
| **Present** | What is now | Wands (action, energy) | 4-7 (structure, challenge) | The heart of the reading |
| **Future** | What will come | Cups (flow, potential) | Aces-3 (beginnings, growth) | The outcome of the reading |

### 4.3 Row Bonuses

When all 3 cards in a row share the row's affinity suit:
- **Row Chain:** ×1.5 Resonance to all 3 cards in that row

When all 3 cards in a column form a suit chain (same suit top to bottom):
- **Column Chain:** ×1.5 Resonance to all 3 cards in that column

When both a row chain AND column chain intersect at a card:
- **Cross Bonus:** That card gets an additional ×2 Resonance

### 4.4 Position-Specific Affinities

Each of the 9 positions has its own affinity that rewards specific cards:

| Position | Name | Suit Affinity | Number Affinity | Special |
|----------|------|---------------|-----------------|---------|
| 1 | Past-Root | Pentacles | 7-10 | Foundation cards (4s) get ×1.5 |
| 2 | Past-Event | Swords | 5-8 | Conflict cards score higher |
| 3 | Past-Lesson | Major Arcana | Any | Major Arcana get ×1.5 |
| 4 | Present-Self | Wands | 4-7 | Court cards get bonus |
| 5 | Present-Center | Any | Pairs | Center of the spread — pairs bonus ×2 |
| 6 | Present-Other | Cups | 4-7 | Relationship cards |
| 7 | Future-Hope | Cups | Aces-3 | Aces get ×2 here |
| 8 | Future-Path | Major Arcana | Any | Major Arcana get ×1.5 |
| 9 | Future-Destiny | Wands | 8-10 | Chain closers (10s) get ×2 |

### 4.5 Future Spread Variants (Post-Demo)

The 3×3 grid is the core spread for the demo. Future updates may introduce variant spreads that modify position affinities or add special rules, while keeping the 9-card structure:
- **Relationship Reading:** All Cups positions, harmony bonuses
- **Career Reading:** All Pentacles/Wands positions, gold bonuses
- **Shadow Reading:** Veil bonuses, reversed cards score double

#### Horseshoe Spread (Risk/Reward)
```
┌──────┐                          ┌──────┐
│1:PAST│                          │7:OUT │
└──┬───┘                          └───┬──┘
   │  ┌──────┐              ┌──────┐  │
   │  │2:PRES│              │6:ACT │  │
   │  └──┬───┘              └───┬──┘  │
   │     │  ┌──────┐  ┌──────┐ │     │
   │     │  │3:HIDE│  │5:ATTD│ │     │
   │     │  └──┬───┘  └───┬──┘ │     │
   │     │     │ ┌──────┐ │    │     │
   │     │     │ │4:SELF│ │    │     │
   │     │     │ └──────┘ │    │     │
```
- **Positions:** 7
- **Difficulty:** ★★★★☆
- **Score Ceiling:** High
- **Special:** Position 3 (Hidden Influences) — card MUST be placed reversed. Guaranteed Veil, but this position has ×2 Resonance. Forces Veil interaction.

### 4.2 Spread Unlocking
- **Three-Card:** Available from start
- **Five-Card Cross:** Unlocked after 3rd querent in first run
- **Relationship:** Unlocked when receiving a love-themed querent
- **Horseshoe:** Unlocked after first Veil Gaze threshold
- **Celtic Cross:** Unlocked after completing first full run (meta-progression)

### 4.3 Position Match Scoring

When a card is placed in a position with matching affinity:

| Match Level | Condition | Bonus |
|-------------|-----------|-------|
| **Perfect Match** | Card meaning directly aligns with position (Death → Transformation) | ×2 Resonance |
| **Good Match** | Suit aligns with position affinity (Cups in emotion position) | +50% Resonance |
| **Neutral** | No particular affinity | No bonus |
| **Mismatch** | Card contradicts position meaning | -10% Resonance (soft penalty, never zero) |

The game displays match quality via color-coded glow when hovering a card over a position:
- 🟡 Gold glow = Perfect Match
- 🟢 Green glow = Good Match  
- ⚪ No glow = Neutral
- 🔴 Faint red = Mismatch

---

## 5. Scoring System

### 5.1 Core Formula

```
Final Score = Σ (Card Insight × Card Resonance) × Spread Multiplier × Veil Modifier
```

**Per-Card Scoring (resolved left-to-right, top-to-bottom):**
1. **Base Insight** = card's inherent value
2. **Position Bonus** = if match: Insight × match modifier
3. **Chain Bonus** = suit chain Resonance multiplier
4. **Effect Triggers** = card-specific upright/reversed effects
5. **Talisman Modifiers** = passive talisman effects apply
6. **Veil Tier Bonus** = if in Glimpse/Gaze/Abyss: additional Resonance

**Spread-Level Modifiers (applied after all cards resolve):**
- Elemental combo bonuses
- Complete Journey / Royal Court / etc. special combos
- Querent theme alignment bonus

### 5.2 Score Scale

| Context | Score Range |
|---------|------------|
| Weak 3-card reading | 50–200 |
| Good 3-card reading | 200–800 |
| Great 5-card reading | 500–3,000 |
| Strong Celtic Cross | 2,000–15,000 |
| God-tier combo run | 15,000–100,000+ |

Target scores escalate per querent, creating Balatro's "can I keep up?" tension.

### 5.3 Visual Scoring Sequence

This is critical for the dopamine loop. Each card resolves with:
1. Card flips face-up with flourish animation
2. Base Insight appears as rising number
3. Position match triggers → glow effect + bonus number pops
4. Chain detection → connecting line between chained cards lights up
5. Resonance multiplier applied → number EXPLODES larger, screen shake
6. Card-specific effect triggers → unique visual per Major Arcana
7. Running total updates with satisfying tick-up animation
8. Final score reveal → if target beaten: celebration particles; if not: tension effect

---

## 6. Combo & Chain System

### 6.1 Elemental Chains (Same Suit Consecutive)

Cards of the same suit placed in adjacent/consecutive positions form chains:

| Chain Length | Resonance Multiplier |
|-------------|---------------------|
| 2 cards | ×1.5 |
| 3 cards | ×2.5 |
| 4 cards | ×4.0 |
| 5+ cards | ×7.0 |

Chains are the primary score amplifier. Building long chains requires deck construction (removing off-suit cards) and careful placement.

**Chain Starters & Closers:**
- Aces begin chains with a +2 Resonance/card bonus
- 10s end chains with a ×1.5 chain Resonance bonus
- Ace → ... → 10 of same suit = **Perfect Chain**: additional ×2

### 6.2 Cross-Element Combos

When two specific suits are adjacent in a spread, elemental reactions occur:

| Combo | Suits | Effect |
|-------|-------|--------|
| **Steam** | Wands + Cups (Fire + Water) | Next card placed gets ×2 Insight |
| **Wildfire** | Wands + Swords (Fire + Air) | All cards gain +3 base Insight |
| **Growth** | Cups + Pentacles (Water + Earth) | Gold earned this reading ×2 |
| **Erosion** | Swords + Pentacles (Air + Earth) | Destroy one card, convert its Insight to Resonance |
| **Forge** | Wands + Pentacles (Fire + Earth) | Permanently upgrade target card +2 Insight |
| **Storm** | Cups + Swords (Water + Air) | +2 Veil but ×2 Resonance to both cards |

### 6.3 Numerological Combos

| Combo | Condition | Effect |
|-------|-----------|--------|
| **Ascending Run** | 3+ consecutive numbers (e.g., 3-4-5) | +5 Insight per card in run |
| **Descending Run** | 3+ descending (e.g., 8-7-6) | +5 Resonance per card in run |
| **Triple** | Same number, 3 different suits | ×2 Resonance to all three |
| **Quad** | Same number, all 4 suits | **Perfect Harmony**: ×5 Resonance to all four |
| **Pairs** | Two of same number | +5 Insight each |

### 6.4 Arcana Combos (Major Arcana Pairs)

| Combo Name | Cards | Effect |
|------------|-------|--------|
| **Eclipse** | Sun + Moon | All Resonance ×3 |
| **Divine Union** | Empress + Emperor | All Court cards ×2 Resonance |
| **Cataclysm** | Death + Tower | +5 Veil but score ×5 |
| **Cosmic Alignment** | Star + World | Veil resets to 0 + ×2 Resonance |
| **The Complete Journey** | Fool + World (0+21) | Run's highest single reading score ×2 |
| **Divine Judgement** | Justice + Judgement | All position mismatches become neutral |
| **Sacred Balance** | Temperance + Justice | Veil locked at current value for rest of run |
| **The Gatekeepers** | High Priestess + Hierophant | All hidden information revealed, +10 Resonance |
| **Dark Pact** | Devil + Moon | Veil effects doubled (bonuses AND penalties) |
| **Liberation** | Strength + Chariot | All cards ignore negative effects this reading |

---

## 7. Veil System

The Veil represents how deep you peer into the occult unknown. It's a run-spanning resource that creates risk/reward tension.

### 7.1 Accumulation

| Source | Veil Gained |
|--------|------------|
| Playing a reversed Minor Arcana | +1 |
| Playing a reversed Court card | +1 |
| Playing a reversed Major Arcana | +2 |
| Dark Major Arcana upright (Death, Devil, Tower, Moon) | +1 |
| Storm combo (Cups + Swords) | +2 |
| Cataclysm combo (Death + Tower) | +5 |
| Certain talismans (Ouija Board, etc.) | Varies |

### 7.2 Tiers & Effects

| Tier | Veil Range | Player Bonus | Cost |
|------|-----------|-------------|------|
| **Clear** | 0–2 | None | None |
| **Glimpse** | 3–5 | Reversed cards gain +50% Resonance | Querent target score +10% |
| **Gaze** | 6–8 | Reversed cards gain ×2 Resonance. Dark combos available | Target score +25%. One card per reading has a "shadow mark" (must be placed reversed) |
| **Abyss** | 9–10 | ALL Resonance ×2. Most powerful Deep Reading bonuses | Target score +50%. If Veil reaches 11 → **The Void**: run ends immediately |

### 7.3 Reduction

| Method | Veil Reduced |
|--------|-------------|
| Playing The Star (upright) | -3 |
| Playing The Sun (upright) | -2 |
| Playing Temperance (upright) | -2 |
| Playing Strength (upright) | Sets to 0 |
| Playing any 6 (Harmony number) | -1 |
| Sage Bundle talisman | -1 per reading |
| All-upright reading (no reversed cards played) | -1 at end of reading |
| Cleanse ritual (skip a querent) | Reset to 0 (lose querent reward) |

### 7.4 Build Archetypes

| Build | Strategy | Risk | Reward |
|-------|----------|------|--------|
| **Light Reader** | All upright, Veil stays 0-2. Use Sun/Star/Temperance | Very low | Consistent but moderate scores |
| **Edge Walker** | Maintain Glimpse/Gaze range. Selective reversals | Medium | Strong scores with controllable risk |
| **Dark Seer** | Push to Abyss. Obsidian Mirror + Ouija Board + all reversed | Extreme (one mistake = run death) | Astronomical scores if managed |
| **Balanced** | Oscillate between Clear and Glimpse. Mix of upright/reversed | Low-Medium | Reliable, flexible |

---

## 8. Querent (Client) System

### 8.1 Querent Structure

Each querent represents a client seeking a tarot reading. They provide the context that shapes each encounter.

**Querent Properties:**
- **Name & Portrait:** Procedurally combined from pools
- **Question Theme:** Determines suit bonuses
- **Personality Type:** Modifies rules
- **Target Score:** Must beat to succeed
- **Reward:** What you earn on success
- **Special Condition (optional):** Unique rule modifier

### 8.2 Question Themes

| Theme | Description | Primary Suit Bonus | Secondary Suit Bonus |
|-------|-------------|-------------------|---------------------|
| **Love & Relationships** | "Will I find love?" "Is this relationship right?" | Cups ×1.5 Resonance | Wands ×1.2 (passion) |
| **Career & Ambition** | "Should I take this job?" "Will my project succeed?" | Wands ×1.5 Resonance | Pentacles ×1.2 (material) |
| **Money & Security** | "Will I be financially stable?" "Should I invest?" | Pentacles ×1.5 Resonance | Cups ×1.2 (contentment) |
| **Conflict & Decisions** | "How do I handle this conflict?" "What should I choose?" | Swords ×1.5 Resonance | Wands ×1.2 (action) |
| **Spiritual & Growth** | "What is my purpose?" "How do I grow?" | Major Arcana ×1.5 | All suits ×1.1 |
| **Health & Wellness** | "Will I recover?" "How to improve my health?" | Pentacles ×1.5 | Cups ×1.2 |
| **Creative & Expression** | "Should I pursue my art?" "How to unlock creativity?" | Wands ×1.5 | Cups ×1.2 |

### 8.3 Personality Types

| Type | Rule Modifier | Player Implication |
|------|--------------|-------------------|
| **Curious** | Target score -15%. Bonus reward if all 4 suits used in reading | Encourages variety. Forgiving. Good for early run |
| **Believer** | Veil bonuses amplified ×1.5. Willing to hear dark truths | Rewards Veil management. Dark builds love this querent |
| **Skeptic** | Target score +20%. Veil bonuses completely disabled | Pure skill test. Must score without Veil shortcuts. Light builds excel |
| **Desperate** | Target score +40%. Reward ×3 | High-risk, high-reward encounter. Boss-like difficulty for a normal querent |
| **Shadowed** | Start reading at Veil +3. Reward: guaranteed rare talisman | Forces Veil interaction. Must manage carefully or risk Abyss |
| **Serene** | Reversed cards give no Veil this reading. Target score standard | Rare positive encounter. Free to experiment with reversals |
| **Secretive** | 2 spread positions are hidden (revealed only during scoring) | Information denied. Must rely on intuition. Tarot experts have edge |

### 8.4 Boss Querents

Appear at the end of each act. Unique rules, higher stakes, better rewards.

| Boss | Theme | Special Rule | Reward |
|------|-------|-------------|--------|
| **The Heartbroken Poet** | Cups | All non-Cups cards have -50% Insight. Must build around Water element | Legendary Cups talisman |
| **The Fallen General** | Swords | Each turn, one card in spread is "cut" (destroyed before scoring). Must plan around losses | Legendary Swords talisman |
| **The Bankrupt Merchant** | Pentacles | Shop locked before AND after this reading. No buying/selling | Legendary Pentacles talisman + bonus gold |
| **The Mad Artist** | Wands | Spread position meanings shuffle randomly each reading. Position matching becomes unpredictable | Legendary Wands talisman |
| **The Void Seeker** | All | Veil starts at 5 (Gaze tier). Must use all 4 suits. Target score is highest in the run | Choice of any legendary talisman + rare Major Arcana card |

---

## 9. Talisman System

Talismans are persistent modifiers that sit outside the spread, similar to Balatro's Jokers. Players carry up to **5 talismans** during a run.

### 9.1 Talisman Tiers

#### Common Talismans (Frequently appear in shop)

| Talisman | Effect | Cost |
|----------|--------|------|
| **Sage Bundle** | -1 Veil after each reading | 30g |
| **Rose Quartz** | Cups cards +3 Insight | 25g |
| **Iron Nail** | Swords cards +3 Insight when swapping positions | 25g |
| **Beeswax Candle** | Wands chains count as 1 longer than actual | 30g |
| **Copper Coin** | Pentacles cards generate +2 gold each | 25g |
| **Dried Lavender** | All 6-numbered cards give -2 Veil instead of -1 | 30g |
| **Quartz Point** | +2 Insight to all cards in first position of any spread | 20g |
| **Bone Dice** | +5 Resonance on a random card each reading | 20g |
| **Red Thread** | Adjacent same-suit cards gain +2 Insight each | 25g |
| **Wooden Rune** | Court cards gain +3 Insight | 25g |

#### Uncommon Talismans

| Talisman | Effect | Cost |
|----------|--------|------|
| **Obsidian Mirror** | Reversed cards gain ×2 Resonance (stacks with Veil bonus) | 60g |
| **Moonstone** | Night querents (every other querent): all Insight ×1.3 | 55g |
| **Pendulum** | Once per reading: swap two cards' positions after placement | 50g |
| **Book of Shadows** | Major Arcana cards +8 Resonance | 55g |
| **Silver Bell** | When a chain of 3+ completes, draw 1 extra card | 50g |
| **Amber Resin** | Cards retain +1 Insight permanently after each reading they're used in | 65g |
| **Mirror Shard** | First reversed card each reading gives no Veil | 55g |
| **Spirit Board Letter** | Reveals querent's special condition before choosing spread | 45g |
| **Hex Bag** | 5-numbered cards (risk cards) give +1 Veil but ×2 Resonance | 50g |
| **Chalice** | If all Cups cards in spread, Cups chain Resonance ×2 | 55g |

#### Rare Talismans

| Talisman | Effect | Cost |
|----------|--------|------|
| **Crystal Ball** | Always see next 5 cards in draw pile | 100g |
| **Athame** | Once per reading: remove one placed card and draw replacement | 90g |
| **Black Mirror** | Veil 7+: all Resonance ×3. Veil 4-6: ×1.5 | 110g |
| **Philosopher's Stone** | Once per reading: change one card's suit to any other | 100g |
| **Ankh** | Prevent one run death. Consumed on use | 120g |
| **Tarot Cloth** | All position match bonuses upgraded by one tier | 90g |
| **Witch's Familiar** | Start each reading with 1 extra card in hand | 95g |
| **Runic Circle** | Numerological combos (pairs, triples, runs) give ×2 bonus | 100g |

#### Legendary Talismans (Boss rewards, very rare shop appearance)

| Talisman | Effect | Cost |
|----------|--------|------|
| **The Holy Grail** | Cups synergies produce no Veil whatsoever | Boss/200g |
| **Solomon's Seal** | All spread positions give Good Match bonus to every suit | Boss/200g |
| **Ouija Board** | All Veil accumulation ×2 AND all Resonance ×2 | Boss/180g |
| **Astrolabe** | Every spread gains +1 extra position (with random meaning) | Boss/200g |
| **The World Tree** | All four suit chains count as connected (one mega-chain) | Boss/220g |
| **Eye of Providence** | See all cards in deck. All hidden information revealed permanently | Boss/200g |
| **Phoenix Feather** | When a card is destroyed/removed, it returns upgraded (+5 Insight) | Boss/180g |
| **Void Crystal** | At Abyss tier: Veil cap increased to 13 instead of 11 | Boss/150g |

### 9.2 Talisman Synergies

Talisman combinations create emergent build strategies:

- **Dark Seer Build:** Obsidian Mirror + Black Mirror + Ouija Board + Hex Bag + Void Crystal → Massive Resonance from reversed cards and high Veil, with extended Abyss safety
- **Chain Master Build:** Beeswax Candle + Silver Bell + Red Thread + The World Tree → Extremely long chains with cascading bonuses
- **Economy Build:** Copper Coin + Amber Resin + Philosopher's Stone → Generate gold and permanently upgrade deck
- **Control Build:** Crystal Ball + Pendulum + Athame + Witch's Familiar → Maximum information and manipulation
- **Light Reader Build:** Sage Bundle + Dried Lavender + Tarot Cloth + Holy Grail → Zero Veil with strong position matching

---

## 10. Shop & Economy

### 10.1 Currency: Gold

Earned from:
- Successful querent readings (base: 15-30g, scales with score)
- Pentacles chains generate bonus gold
- Desperate querent bonus (×3 reward)
- Interest on unspent gold (1g per 5g held, max 5g interest)

### 10.2 Shop Contents (Between Querents)

| Category | Options | Notes |
|----------|---------|-------|
| **Card Pack** | 3 random cards, pick 1 to add to deck | 8g per pack. Can buy multiple |
| **Talisman** | 2-3 talismans available | Price varies by tier |
| **Card Removal** | Remove 1 card from deck | 15g (increases by 5g each use) |
| **Card Upgrade** | +3 permanent Insight to one card | 20g |
| **Suit Conversion** | Change one card's suit | 25g |
| **Spread Unlock** | Occasionally offers a new spread | 40g |
| **Reroll** | Refresh shop contents | 5g (increases each use) |

### 10.3 Deck Management

- Starting deck: 22 cards (all Major Arcana? or subset + Minor Arcana mix)
- Recommended deck size: 20-30 cards (smaller = more consistent draws)
- No maximum deck size, but dilution is a real concern
- Card removal is a strategic tool — remove weak cards to see strong ones more often

**Starting Deck (Demo):**
- All 22 Major Arcana (The Fool through The World)
- This gives new players the most thematic, recognizable cards first
- Minor Arcana acquired through shop/rewards during the run
- Creates a natural "learning then expanding" arc

---

## 11. Run Structure

### 11.1 Acts

A full run consists of **3 Acts**, each with escalating difficulty:

**Act I — The Parlor (Querents 1-4)**
- Low target scores (50-400)
- Curious and Serene querents common
- Introduction to mechanics
- Boss: One of the four faction bosses (random)
- Spreads: Three-Card, Five-Card unlocked mid-act

**Act II — The Salon (Querents 5-8)**
- Medium target scores (300-2,000)
- Skeptic and Shadowed querents appear
- More complex querent conditions
- Boss: A different faction boss
- Spreads: Horseshoe and Relationship available

**Act III — The Sanctum (Querents 9-12)**
- High target scores (1,500-10,000+)
- Desperate querents and special conditions common
- Final boss: The Void Seeker
- Celtic Cross available for high-ceiling scoring
- Veil management becomes critical

### 11.2 Between-Act Events

Between acts, a special event occurs (roguelike events):
- **The Wandering Merchant:** Special shop with rare talismans
- **The Dream:** Choose 1 of 3 permanent blessings for the run
- **The Sacrifice:** Give up a talisman for a powerful one-time effect
- **The Vision:** Preview next act's bosses and plan

### 11.3 Lives System

- **3 Lives per run** (represented as candle flames)
- Failing a querent's target score = lose 1 life
- Losing all 3 = run over
- Extra lives cannot be gained (except Ankh talisman prevents 1 death)
- This creates Balatro's "I can afford to lose some, but not many" tension

---

## 12. Meta-Progression

Unlocked across runs. Provides variety without invalidating previous runs.

| Unlock Type | How Earned | What It Adds |
|-------------|-----------|-------------|
| **New Spreads** | Complete runs / specific achievements | More strategic options |
| **Talisman Pool** | Discover during runs → added to future pool | Build variety |
| **Difficulty Tiers** | Beat the game → unlock next tier | Higher stakes, higher scores |
| **Card Variants** | Specific achievements (e.g., "play 50 Cups") | Alternate art / minor stat tweaks |
| **Querent Types** | Meet specific conditions during runs | New personalities, new challenges |
| **Starting Bonuses** | Cumulative achievement milestones | Start with gold, extra card, etc. |

### Difficulty Tiers (Post-completion)

| Tier | Name | Modifier |
|------|------|----------|
| 1 | **Candle Light** | Base difficulty (demo/first playthrough) |
| 2 | **Moonlit** | Target scores +25%, shop prices +20% |
| 3 | **Starless** | Target +50%, Veil accumulates 50% faster |
| 4 | **Eclipse** | Target +75%, start with 2 lives, forced reversed positions |
| 5 | **The Void** | Target ×2, 1 life, Veil starts at 3, shops half stock |

---

## 13. Readability & Onboarding

### 13.1 Core Principle
The game must be immediately playable by someone who has never seen a tarot card. Tarot knowledge is an advantage, never a requirement.

### 13.2 In-Game Systems

**Card Tooltips (Always Visible):**
- Card name and number
- Suit and element icon
- Upright meaning (1 sentence) and effect
- Reversed meaning (1 sentence) and effect
- Base Insight value
- Current chain status

**Position Tooltips:**
- Position name and meaning
- Suit affinities (icons)
- Number affinities
- Current match preview when hovering card

**Match Preview System:**
- Drag card over position → immediate visual feedback
- Gold glow: Perfect Match
- Green glow: Good Match
- No glow: Neutral
- Faint red: Mismatch
- Resonance preview number appears

**The Grimoire (In-Game Encyclopedia):**
- Full reference for all 78 cards
- Upright and reversed meanings
- Position affinity guide
- Combo reference sheet
- Unlocks entries as player encounters cards
- Accessible via hotkey at any time

**Intuition Hints (Toggleable):**
- When enabled: best 2-3 placements are subtly highlighted
- Casual mode feature — helps non-tarot players
- Can be toggled on/off at any time
- Does NOT show during scoring (preserves surprise)

### 13.3 Tutorial Flow

**First Run — Guided Querents:**
1. First querent: forced 3-card spread, game explains placement
2. Second querent: introduces suit matching and chains
3. Third querent: introduces reversed cards and Veil
4. Fourth querent: boss — player is on their own

After first run, tutorial elements become optional tooltips.

---

## 14. Visual Design & Juice

### 14.1 Art Direction

**Style:** Mystical-elegant with Rider-Waite-Smith authenticity  
**Palette:** Deep purples, midnight blues, gold accents, candlelight warmth  
**Card Art:** Public domain 1909 PCS illustrations, upscaled and framed with custom SVG borders  
**UI:** Clean, dark theme with gold typography. Tarot table cloth texture as background.  
**Typography:** Serif for card names (mystical feel), sans-serif for numbers/UI (readability)

### 14.2 Game Feel Requirements (Critical)

Every scoring event must feel explosive. Reference: Balatro's scoring animation.

**Card Placement:**
- Satisfying "thunk" when card lands on position
- Subtle glow based on match quality
- Card slightly "breathes" (idle animation) when placed

**Scoring Sequence:**
- Cards resolve one-by-one with dramatic pause
- Base Insight: number rises from card with particle trail
- Position match: golden burst effect, screen vibrates subtly
- Chain activation: connecting line of elemental energy (fire/water/air/earth) traces between chained cards
- Multiplier application: number GROWS with exponential scaling animation, camera shakes proportional to multiplier size
- Combo trigger: full-screen flash of elemental color, unique sound sting
- Running total: ticker-style count-up with acceleration
- Final score: if beating target: celebration explosion (particles, card dance, gold shower). If close but under: tense red pulse

**Veil Visuals:**
- Veil counter represented as an eye that opens progressively
- Clear: eye closed
- Glimpse: eye slightly open, faint purple mist at screen edges
- Gaze: eye half-open, visible purple tendrils creeping from edges
- Abyss: eye wide open, screen edges dark, pulsing purple energy, particles

**Card Flip Animation:**
- When choosing upright/reversed: card physically rotates in 3D
- Reversed cards have a purple shimmer/aura
- Light cards emit warm glow; dark cards emit cold/purple glow

### 14.3 Shader Effects (Planned)

| Effect | Usage | Priority |
|--------|-------|----------|
| **Card glow shader** | Match quality indication, suit colors | P0 — Core |
| **Screen shake** | Multiplier triggers, big combos | P0 — Core |
| **Particle systems** | Scoring, chains, combos, Veil | P0 — Core |
| **Number scaling animation** | Score display, multiplier growth | P0 — Core |
| **Elemental energy lines** | Chain visualization between cards | P1 — Important |
| **Veil mist/tendrils** | Screen edge atmosphere at Veil tiers | P1 — Important |
| **CRT/mystical post-process** | Optional visual filter (toggleable) | P2 — Polish |
| **Card hover parallax** | Slight 3D tilt when mousing over cards | P2 — Polish |
| **Background animation** | Subtle candle flicker, cloth movement | P2 — Polish |

---

## 15. Audio Design

### 15.1 Music Direction
- **Ambient mystical** — think lo-fi meets occult. Soft, atmospheric, doesn't compete with gameplay
- **Adaptive layers:** intensity builds with Veil level
  - Clear: soft ambient, gentle harp/bells
  - Glimpse: adds subtle bass, echoing tones
  - Gaze: darker pads, heartbeat-like pulse
  - Abyss: full dark ambient, dissonant undertones, tension
- **Boss themes:** unique per faction boss

### 15.2 Sound Effects Priority

| Sound | Trigger | Feel |
|-------|---------|------|
| **Card place** | Card lands on position | Satisfying "thunk" — heavy tarot card on cloth |
| **Card flip** | Choosing upright/reversed | Crisp paper flip |
| **Match glow** | Position match detected | Warm chime (gold match) / soft ping (green) |
| **Chain connect** | Chain detected | Elemental whoosh (fire crackle / water flow / wind gust / earth rumble) |
| **Multiplier hit** | Resonance applied | Rising pitch synth + impact — escalates with multiplier size |
| **Combo trigger** | Special combo fires | Unique sting per combo type + explosion |
| **Score tick** | Running total counting up | Rapid clicking that accelerates |
| **Score burst** | Final score revealed | Cymbal crash + magical chord |
| **Veil increase** | Veil gained | Deep, ominous tone |
| **Veil decrease** | Veil reduced | Relief tone, wind chime |
| **Querent arrive** | New querent appears | Door knock + ambient change |
| **Shop open** | Enter shop | Cash register + mystical atmosphere |

---

## 16. Target Audience

### Primary Audience
1. **Tarot enthusiasts (casual, primarily women, Gen Z/Millennials):** Know tarot, enjoy the authentic representation, feel intuitive mastery. Entry point: "A game that actually understands tarot."
2. **Roguelike deckbuilder fans:** Love Balatro/StS/Inscryption. Entry point: "Balatro but with spatial card placement and tarot's rich card system."

### Secondary Audience
3. **Mystical/witchy aesthetic fans:** TikTok WitchTok community, crystal/astrology enthusiasts. Entry point: visual aesthetic and tarot theme.
4. **Casual puzzle fans:** Enjoy satisfying number games. Entry point: dopamine from score chasing.

### Audience Bridge
The game must serve BOTH primary audiences equally:
- Tarot experts: intuitive card placement, authentic meanings, real spread types → feel like they're "reading" well
- Deckbuilder experts: deep combo system, talisman synergies, Veil management → feel like they're "building" well
- Neither should feel the game is "not for them"

---

## 17. Competitive Positioning

### Direct Competitors
| Game | Our Advantage |
|------|--------------|
| **Balatro** | Spatial placement (vs. hand submission), authentic tarot (vs. poker), dual audience, Veil mechanic |
| **Tarogue** | Deep tarot authenticity (position meanings, active reversed choice, querent system, teaches real tarot) |

### Market Position
**"The tarot game for people who love tarot AND the deckbuilder for people who love deckbuilders."**

Not positioned as: "Balatro clone with tarot skin"  
Positioned as: "What if a tarot reading was a deeply satisfying puzzle game?"

### Price Strategy
- **Launch:** $12.99 (or $14.99 if scope matches Balatro-level depth)
- **20% launch discount** to drive initial sales
- **Steam Next Fest demo** is critical for wishlists
- Post-launch: seasonal sales at 20-30% off

---

## 18. Demo Scope

### What's In the Demo

**Cards:**
- All 22 Major Arcana (fully functional with upright/reversed effects)
- 40 Minor Arcana (10 per suit: Ace-10, no Court cards in demo)
- Total: 62 playable cards

**Spreads:**
- Three-Card Spread
- Five-Card Cross

**Querents:**
- 6 normal querents (all personality types except Secretive)
- 1 boss querent (random from 4 faction bosses)
- Act I only (7 querents per demo run)

**Talismans:**
- 10 Common
- 5 Uncommon
- 2 Rare
- 0 Legendary (boss reward teased but "coming in full game")

**Systems:**
- Full scoring system (Insight × Resonance)
- Chain and combo system (elemental chains, cross-element combos, numerological combos)
- Veil system (all 4 tiers functional)
- Shop (buy cards, talismans, remove cards)
- Grimoire (encyclopedia for encountered cards)
- Match preview (glow system)
- Tutorial (guided first 3 querents)
- Intuition Hints (toggleable)

**Visual/Audio:**
- Card placement + scoring animations (full juice)
- Veil visual effects (all tiers)
- Elemental chain visualizations
- Score cascade animations
- Placeholder audio (key SFX, ambient music)

### What's NOT in the Demo
- Court cards (Page/Knight/Queen/King)
- Celtic Cross, Relationship, and Horseshoe spreads
- Acts II and III
- Meta-progression / unlocks
- Legendary talismans
- Between-act events
- Difficulty tiers
- Arcana combos (Major Arcana pair bonuses)
- Card variants / alternate art
- Full audio (final music, all SFX polished)

### Demo Goal
Player should finish a demo run thinking:
1. "I want to try that again with different talismans"
2. "I wonder what the Celtic Cross spread plays like"
3. "I need to see what Court cards do"
4. → **Wishlist**

---

## Appendix A: Position Affinity Reference (Quick Reference)

### Three-Card Spread
| Position | Best Suits | Best Numbers | Best Major Arcana |
|----------|-----------|-------------|-------------------|
| Past | Pentacles, Swords | 7, 8, 9, 10 | Hermit, Justice, Wheel of Fortune |
| Present | Wands, Cups | 4, 5, 6, 7 | Magician, Strength, Chariot |
| Future | Cups, Wands | Ace, 2, 3 | Star, Sun, World, Fool |

### Five-Card Cross
| Position | Best Suits | Best Numbers | Best Major Arcana |
|----------|-----------|-------------|-------------------|
| Past | Pentacles | 8, 9, 10 | Hermit, Justice |
| Present | All (neutral) | All | Magician, High Priestess |
| Future | Wands | Ace, 2, 3 | Star, Wheel of Fortune |
| Crown | Major Arcana ×2 | All | Any Major (all get ×2 here) |
| Foundation | Pentacles | 4, 10 | Emperor, Hierophant |

---

## Appendix B: Suit Interaction Matrix

| Adjacent Suits | Combo Name | Effect |
|---------------|------------|--------|
| Wands + Cups | Steam | Next card ×2 Insight |
| Wands + Swords | Wildfire | All cards +3 Insight |
| Wands + Pentacles | Forge | Permanent +2 Insight upgrade |
| Cups + Swords | Storm | +2 Veil, both cards ×2 Resonance |
| Cups + Pentacles | Growth | Reading gold ×2 |
| Swords + Pentacles | Erosion | Destroy 1 card → convert to Resonance |
| Same + Same | Chain | See chain multiplier table |

---

*End of GDD v1.0*
