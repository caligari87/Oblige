--------------------------------------------------------------------
--  DOOM MONSTERS
--------------------------------------------------------------------
--
--  Copyright (C) 2006-2017 Andrew Apted
--  Copyright (C)      2011 Chris Pisarczyk
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2
--  of the License, or (at your option) any later version.
--
--------------------------------------------------------------------

-- Usable keywords
-- ===============
--
-- id      : editor number used to place monster on the map
--
-- rank    : measure of "boss-ness",range is 0 to 99
-- density : maximum quantity to use (per 1000 seeds), 0 for none
-- skip    : chance of skipping this monster in a map
--
-- health : hit points of monster
-- damage : total damage inflicted on player (on average)
-- attack : kind of attack (hitscan | missile | melee)
--
-- float  : true if monster floats (flies)
-- invis  : true if invisible (or partially)
--
-- weap_needed : weapons player must have to fight this monster
-- weap_min_damage : damage (per second) of player weapon required
-- weap_prefs : weapon preferences table (usage by player)
--
-- species    : name of species (default is monster itself)
-- disloyal   : can hurt a member of same species
-- infight_damage : damage inflicted on one (or more) other monsters
--
--
-- NOTES
-- =====
--
-- Some monsters (e.g. IMP) have both a close-range melee
-- attack and a longer range missile attack.  This is not
-- modelled, we just pick the one with the most damage.
--
-- Archvile attack is not a real hitscan, but for modelling
-- purposes that is a reasonable approximation.
--
-- Similarly the Pain Elemental attack is not a real missile
-- but actually a Lost Soul.  It spawns at least three (when
-- killed), and often more, hence the health is much higher.
--

DOOM.MONSTERS =
{
  zombie =
  {
    id = 3004
    r = 20
    h = 56 
    rank = 1
    density = 50
    skip = 8
    health = 20
    damage = 1.2
    attack = "hitscan"
    give = { {ammo="bullet",count=5} }
    room_size = "small"
    disloyal = true
    trap_factor = 0.01
    infight_damage = 1.9
  }

  shooter =
  {
    id = 9
    r = 20
    h = 56 
    rank = 6
    density = 80
    skip = 3
    health = 30
    damage = 3.0
    attack = "hitscan"
    give = { {weapon="shotty"}, {ammo="shell",count=4} }
    weap_needed = { shotty=true }
    species = "zombie"
    room_size = "small"
    disloyal = true
    trap_factor = 2.0
    infight_damage = 6.1
  }

  imp =
  {
    id = 3001
    r = 20
    h = 56 
    rank = 3
    skip = 3
    density = 150
    health = 60
    damage = 1.3
    attack = "missile"
    room_size = "small"
    trap_factor = 0.3
    infight_damage = 4.0
  }

  skull =
  {
    id = 3006
    r = 16
    h = 56 
    rank = 5
    density = 20
    skip = 40
    health = 100
    damage = 1.7
    attack = "melee"
    float = true
    weap_prefs = { launch=0.3 }
    room_size = "small"
    disloyal = true
    trap_factor = 0.2
    infight_damage = 2.1
  }

  demon =
  {
    id = 3002
    r = 30
    h = 56 
    rank = 5
    density = 37
    skip = 7
    health = 150
    damage = 0.4
    attack = "melee"
    weap_min_damage = 40
    weap_prefs = { launch=0.3 }
    room_size = "any"
    infight_damage = 3.5
  }

  spectre =
  {
    id = 58
    r = 30
    h = 56 
    rank = 7
    density = 23
    skip = 30
    health = 150
    damage = 1.0
    attack = "melee"
    invis = true
    outdoor_factor = 3.0
    weap_min_damage = 40
    weap_prefs = { launch=0.1 }
    species = "demon"
    room_size = "any"
    trap_factor = 0.3
    infight_damage = 2.5
  }

  caco =
  {
    id = 3005
    r = 31
    h = 56 
    rank = 10
    density = 22
    skip = 10
    health = 400
    damage = 4.0
    attack = "missile"
    weap_min_damage = 40
    float = true
    room_size = "large"
    trap_factor = 0.5
    infight_damage = 21
  }


  ---| BOSSES |---

  baron =
  {
    id = 3003
    r = 24
    h = 64 
    rank = 36
    density = 10
    skip = 20
    health = 1000
    damage = 7.5
    attack = "missile"
    weap_min_damage = 88
    room_size = "medium"
    infight_damage = 40
  }

  Cyberdemon =
  {
    id = 16
    r = 40
    h = 110
    rank = 95
    density = 3.4
    skip = 40
    health = 4000
    damage = 125
    attack = "missile"
    weap_min_damage = 150
    weap_prefs = { bfg=10.0 }
    room_size = "medium"
    infight_damage = 1600
  }

  Spiderdemon =
  {
    id = 7
    r = 128
    h = 100
    rank = 87
    density = 6.5
    skip = 60
    boss_limit = 1 -- because they infight
    health = 3000
    damage = 100
    attack = "hitscan"
    weap_min_damage = 200
    weap_prefs = { bfg=10.0 }
    room_size = "large"
    infight_damage = 700
    boss_replacement = "Cyberdemon"
  }


  ---== Doom II only ==---

  gunner =
  {
    id = 65
    r = 20
    h = 56 
    rank = 9
    density = 47
    skip = 5
    health = 70
    damage = 5.5
    attack = "hitscan"
    give = { {weapon="chain"}, {ammo="bullet",count=10} }
    weap_needed = { chain=true }
    weap_min_damage = 50
    species = "zombie"
    room_size = "large"
    disloyal = true
    trap_factor = 2.4
    infight_damage = 25
  }

  revenant =
  {
    id = 66
    r = 20
    h = 64 
    rank = 13
    density = 29
    skip = 8
    health = 300
    damage = 8.5
    attack = "missile"
    weap_min_damage = 60
    room_size = "any"
    trap_factor = 3.6
    infight_damage = 20
  }

  knight =
  {
    id = 69
    r = 24
    h = 64 
    rank = 12
    density = 24
    skip = 12
    health = 500
    damage = 4.0
    attack = "missile"
    weap_min_damage = 50
    species = "baron"
    room_size = "medium"
    infight_damage = 36
  }

  mancubus =
  {
    id = 67
    r = 48
    h = 64 
    rank = 25
    density = 16
    skip = 14
    health = 600
    damage = 8.0
    attack = "missile"
    weap_min_damage = 88
    room_size = "large"
    infight_damage = 70
  }

  arach =
  {
    id = 68
    r = 64
    h = 64 
    rank = 28
    density = 12
    skip = 30
    health = 500
    damage = 10.7
    attack = "missile"
    weap_min_damage = 60
    room_size = "medium"
    infight_damage = 62
    boss_replacement = "revenant"
  }

  vile =
  {
    id = 64
    r = 20
    h = 56 
    rank = 47
    skip = 27
    density = 6.4
    health = 700
    damage = 25
    attack = "hitscan"
    room_size = "medium"
    weap_min_damage = 120
    nasty = true
    infight_damage = 18
  }

  pain =
  {
    id = 71
    r = 31
    h = 56 
    rank = 42
    density = 6.7
    skip = 50
    health = 900  -- 400 + 5 skulls
    damage = 14.5 -- about 5 skulls
    attack = "missile"
    float = true
    weap_min_damage = 100
    weap_prefs = { launch=0.1 }
    room_size = "large"
    cage_factor = 0  -- never put in cages
    infight_damage = 4.5 -- guess
  }

  -- NOTE: this is not normally added to levels
  ss_nazi =
  {
    id = 84
    r = 20
    h = 56 
    rank = 3
    density = 0
    skip = 99
    health = 50
    damage = 2.8
    attack = "hitscan"
    give = { {ammo="bullet",count=5} }
    infight_damage = 6.0
  }
}

