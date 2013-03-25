----------------------------------------------------------------
--  DECK THE HALLS
----------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2011-2013 Andrew Apted
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2
--  of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
----------------------------------------------------------------

--[[ *** CLASS INFORMATION ***

class HALLWAY
{
  kind : keyword  -- "hallway"  (differentiates from a ROOM object)

  id : number (for debugging)

  conns : list(CONN)  -- connections with neighbor rooms / hallways
  entry_conn

  sections : list(SECTION)

  big_junc  : SECTION
  crossover : ROOM
  is_cycle  : boolean

  joiner : boolean  -- a joiner is a single section hallway going
                    -- straight ahead (two rooms, no turning).

  double_fork : SECTION    -- only present for double hallways.
  double_dir  : direction  -- dir at the single end (into hallway)

  cross_limit : { low, high }  -- a limitation of crossover heights

  wall_mat, floor_mat, ceil_mat 
}

--------------------------------------------------------------]]

--
-- Cross-Over Notes:
-- ================
--
-- (1) if hallway is visited first, can give it (including bridges)
--     any heights, and give the room a height limitation.  Mark the
--     chunk leading into the room as a "height adjuster".
-- 
--     [Note: cycle lead-in chunks are automatically adjusters]
-- 
--     When room is visited, it will get its first height from
--     the lead-in chunk and will have a height limitation in
--     place for all areas.
-- 
-- (2) if room is visited first, flesh out normally and give
--     crossover chunks a height limitation.
-- 
--     When hallway is visited, the exit chunk(s) which lead
--     to a crossover chunk will be the "height adjusters".
--     The hallway is free to choose the bridge heights here
--     so long as the limitation is satisfied.
-- 


HALLWAY_CLASS = {}

function HALLWAY_CLASS.new()
  local H =
  {
    kind     = "hallway"
    id       = Plan_alloc_id("hallway")
    conns    = {}
    sections = {}

    mon_spots  = {}
    item_spots = {}
    cage_spots = {}
    trap_spots = {}
  }
  table.set_class(H, HALLWAY_CLASS)

  return H
end


function HALLWAY_CLASS.tostr(H)
  return string.format("HALL_%d", H.id)
end


function HALLWAY_CLASS.OLD__dump_pieces(H)
  gui.debugf("%s pieces:\n{\n", H:tostr())

  each P in H.pieces do
    gui.debugf("  %s\n", P:tostr())
  end

  gui.debugf("}\n")
end


function HALLWAY_CLASS.dump(H)
  gui.debugf("%s =\n", H:tostr())
  gui.debugf("{\n")
  -- FIXME
  gui.debugf("belong = %s\n", (H.belong_room ? H.belong_room:tostr() ; "nil"))
  gui.debugf("sections = %s\n", (H.sections ? tostring(#H.sections) ; "nil"))
  gui.debugf("}\n")
end


function HALLWAY_CLASS.add_section(H, K)
  table.insert(H.sections, K)
end


function HALLWAY_CLASS.dump_path(H)
  gui.debugf("Path in %s:\n", H:tostr())
  gui.debugf("{\n")

  each K in H.sections do
    local line = ""

    for dir = 2,8,2 do
      local N = K.hall_link[dir]

      if N then
        local L = N.room or N.hall

        line = line .. string.format("[%d] --> %s  ", dir, L:tostr())
      end
    end

    gui.debugf("  @ %s : %s\n", K:tostr(), line)
  end

  gui.debugf("}\n\n")
end


function HALLWAY_CLASS.calc_lev_along(H)
  local parent

  each D in H.conns do
    local N = D:neighbor(H)

    if N.visit_id < H.visit_id then
      parent = N
      break
    end
  end

  if parent and parent.lev_along then
    H.lev_along = parent.lev_along
  else
    H.lev_along = rand.pick { 0.3, 0.5, 0.7 }
  end
end


function HALLWAY_CLASS.joiner_sections(H)
  assert(H.joiner)

  local K = H.sections[1]
  local dir = (K.hall_link[2] ? 2 ; 4)

  local K1 = K.hall_link[dir]
  local K2 = K.hall_link[10 - dir]

  assert(K1 and K1.room)
  assert(K2 and K2.room)

  return K1, K2
end


function HALLWAY_CLASS.joiner_rooms(H)
  local K1, K2 = H:joiner_sections()

  return K1.room, K2.room
end


function HALLWAY_CLASS.setup_path(H, path)

  -- the 'path' is a list of sections in visited order, as produced
  -- by the hall_flow() function.
  assert(#path >= 1)

  for i = 1, #path-1 do
    local K1 = path[i]
    local K2 = path[i+1]

    -- reconstruct the direction
    local dir

        if K2.sx1 > K1.sx2 then dir = 6
    elseif K2.sx2 < K1.sx1 then dir = 4
    elseif K2.sy1 > K1.sy2 then dir = 8
    elseif K2.sy2 < K1.sy1 then dir = 2
    else error("weird hallway path")
    end

    K1.hall_link[dir]      = K2
    K2.hall_link[10 - dir] = K1
  end

  -- NOTE: links leading "off" the hallway are handled by CONN:add_it()
end


function HALLWAY_CLASS.mark_sections(H, sections)
  each K in sections do
    -- an already used section can only be a crossover
    if K.used then
      assert(K.room)
      assert(H.crossover)

      K:set_crossover(H)
    else
      K:set_hall(H)
    end
  end
end


function HALLWAY_CLASS.add_it(H)

  table.insert(LEVEL.halls, H)

  H:setup_path(H.sections)

  H:mark_sections(H.sections)

  if H.crossover then
    local over_R = H.crossover

    over_R.crossover_hall = H

-- stderrf("************* CROSSOVER @ %s\n", over_R:tostr())
  end

  if #H.sections > 1 then
    LEVEL.hall_quota = LEVEL.hall_quota - #H.sections
  end
end


function HALLWAY_CLASS.add_to_existing(H, new_H, via_conn)

  -- unlike add_it(), the new hallway is merely used to extend an
  -- existing hallway.

stderrf("MERGING %s into %s\n", new_H:tostr(), H:tostr())

  assert(H != new_H)

  assert(not     H.crossover)
  assert(not new_H.crossover)

  -- transfer the sections and setup the path links
  each K in new_H.sections do
    table.insert(H.sections, K)
  end

  H:setup_path(new_H.sections)

  H:mark_sections(new_H.sections)

  -- create path link for the OLD <--> NEW connection
  local dir = assert(via_conn.dir1)

  via_conn.K1.hall_link[dir]      = via_conn.K2
  via_conn.K2.hall_link[10 - dir] = via_conn.K1

  -- lose the "joiner" status
  H.joiner = false

  if #new_H.sections > 1 then
    LEVEL.hall_quota = LEVEL.hall_quota - #new_H.sections
  end

  -- the new_H object is never used again
  new_H.id       = nil
  new_H.sections = nil
end


--------------------------------------------------------------------


-- FIXME: OLD CRUD
function HALLWAY_CLASS.can_alloc_chunk(H, sx1, sy1, sx2, sy2)
  for sx = sx1,sx2 do for sy = sy1,sy2 do
    local S = SEEDS[sx][sy]
    if S.chunk then return false end
  end end

  return true
end


-- FIXME: OLD CRUD
function HALLWAY_CLASS.alloc_chunk(H, K, sx1, sy1, sx2, sy2)
  assert(K.sx1 <= sx1 and sx1 <= sx2 and sx2 <= K.sx2)
  assert(K.sy1 <= sy1 and sy1 <= sy2 and sy2 <= K.sy2)

  local C = CHUNK_CLASS.new(sx1, sy1, sx2, sy2)

  C.hall = H
  C.section = K
  C.hall_link = {}

---###  table.insert(H.chunks, C)
---###  C:install()
  C:set_coords()

  return C
end


function HALLWAY_CLASS.is_side_connected(H, K, dir)
  -- returns true if the given side of the section connects to another
  -- section in this hallway.

  local N = K.hall_link[dir]

  return N and N.hall == H
end


function HALLWAY_CLASS.try_add_middle_chunk(H, K)
  -- skip crossovers
  if K.room then return end

  local sx1, sy1 = K.sx1, K.sy1
  local sx2, sy2 = K.sx2, K.sy2

  if K.shape == "junction" or K.shape == "big_junc" or
     K.double_peer or rand.odds(20)
  then
    -- use the whole section

  elseif K.shape == "horiz" then

    if K.sw >= 5 then
      sx1 = sx1 + 2
      sx2 = sx2 - 2
    elseif K.sw >= 3 then
      sx1 = sx1 + 1
      sx2 = sx2 - 1
    end

  elseif K.shape == "vert" then

    if K.sh >= 5 then
      sy1 = sy1 + 2
      sy2 = sy2 - 2
    elseif K.sh >= 3 then
      sy1 = sy1 + 1
      sy2 = sy2 - 1
    end

  else
    return
  end

  if not H:can_alloc_chunk(sx1, sy1, sx2, sy2) then
    return
  end

  -- OK --

  local C = H:alloc_chunk(K, sx1, sy1, sx2, sy2)
end


function HALLWAY_CLASS.add_edge_chunk(H, K, side)
  if not H:is_side_connected(K, side) then
    return
  end

  -- determine how much space is on the given side (may be none)
  local seeds

  each C in H.chunks do
    if C.section == K then

      local dist

      if side == 2 then dist = C.sy1 - K.sy1 end
      if side == 8 then dist = K.sy2 - C.sy2 end
      if side == 4 then dist = C.sx1 - K.sx1 end
      if side == 6 then dist = K.sx2 - C.sx2 end

      assert(dist)
      assert(dist >= 0)

      if dist == 0 then
        -- no space, hence no new chunk
        return
      end

      if not seeds or dist < seeds then
         seeds = dist
      end
    end
  end

  if not seeds then
    error("add_edge_chunk failed (no chunks in section?)")
  end

  local sx1, sy1 = K.sx1, K.sy1
  local sx2, sy2 = K.sx2, K.sy2

  if side == 2 then sy2 = sy1 + (seeds - 1) end
  if side == 8 then sy1 = sy2 - (seeds - 1) end
  if side == 4 then sx2 = sx1 + (seeds - 1) end
  if side == 6 then sx1 = sx2 - (seeds - 1) end

  assert(H:can_alloc_chunk(sx1, sy1, sx2, sy2))

  local C = H:alloc_chunk(K, sx1, sy1, sx2, sy2)
end



function HALLWAY_CLASS.create_pieces(H)

--[[

  -- every section will get at least one chunk
  each K in H.sections do
    H:try_add_middle_chunk(K)
  end

  -- at here, the only chunks we need now are ones which fill the gaps
  -- at either edge of a horizontal or vertical section (but only when
  -- that side touches another section in the same hallway).

  each K in H.sections do
    if K.shape == "horiz" then
      H:add_edge_chunk(K, 4)
      H:add_edge_chunk(K, 6)

    elseif K.shape == "vert" then
      H:add_edge_chunk(K, 2)
      H:add_edge_chunk(K, 8)
    end
  end

--]]

end



function HALLWAY_CLASS.categorize_pieces(H)

  -- categorize the hallway pieces, and verify the linkages

  each P in H.sections do
    if table.size(P.hall_link) < 2 then
      gui.debugf("hallway %s has bad linkage @ %s\n", H:tostr(), P:tostr())
      error("bad linkage in hallway")
    end

    if not P.crossover_hall then
      local cat, dir = Trans.categorize_linkage(
          P.hall_link[2], P.hall_link[4],
          P.hall_link[6], P.hall_link[8]);

      assert(cat != "N" and cat != "F")

      P.h_shape = cat
      P.h_dir   = dir
    end
  end
end


function HALLWAY_CLASS.find_double_peer(H, C)
  local is_fork = (C.section == H.double_fork)
  local is_vert = geom.is_vert(H.double_dir)

  each D in H.chunks do

    if D == C then continue end
    if not D.section then continue end
    if D.double_peer then continue end

    if D.section.double_peer and
       D.section.double_peer == C.section and
       not is_fork
    then
      assert(C != D)

      -- check that both chunks are aligned

      if is_vert then
        if C.sy1 == D.sy1 and C.sy2 == D.sy2 then return D end
      else
        if C.sx1 == D.sx1 and C.sx2 == D.sx2 then return D end
      end
    end

    if is_fork then
      -- require same width, one either side of fork section, and not touching

      if is_vert then
        if (C.sx2 - C.sx1) == (D.sx2 - D.sx1) and
           C.sx1 == H.double_fork.sx1 and
           D.sx2 == H.double_fork.sx2 and
           D.sx1 > C.sx2 + 1
        then
          return D
        end
      else -- horiz
        if (C.sy2 - C.sy1) == (D.sy2 - D.sy1) and
           C.sy1 == H.double_fork.sy1 and
           D.sy2 == H.double_fork.sy2 and
           D.sy1 > C.sy2 + 1
        then
          return D
        end
      end
    end

  end
end


function HALLWAY_CLASS.peer_double_chunks(H)
  if not H.double_fork then return end

  gui.debugf("peer_double_chunks @ %s\n", H:tostr())

  each C in H.chunks do
    if not C.section then continue end
    if C.double_peer then continue end

    if C.section.double_peer or C.section == H.double_fork then
      local D = H:find_double_peer(C)

      if D then
gui.debugf("   found %s <--> %s\n", C:tostr(), D:tostr())
        C.double_peer = D
        D.double_peer = C
      end
    end
  end
end



function HALLWAY_CLASS.stair_flow(H, P, from_dir, floor_h, z_dir, seen)
  --
  -- recursively flow through the hallway, adding stairs (etc) 
  --

--stderrf("stair_flow @ %s | %s\n", H:tostr(), P:tostr())
--stderrf("from_dir: %d\n", from_dir)

  seen[P] = true

  local floor_diffs = { }  -- indexed by [dir]

  floor_diffs[2] = 0 ; floor_diffs[8] = 0
  floor_diffs[4] = 0 ; floor_diffs[6] = 0

  if P.shape == "big_junc" or H.joiner then
    local skin

    if H.joiner then
      skin = H:select_joiner(P)
    else
      skin = H:select_big_junc(P)
    end

    P.skin = skin

    -- determine south / north / east / west directions
    local s_dir = P.h_dir
    local n_dir = 10 - s_dir
    local e_dir = geom.LEFT [s_dir]
    local w_dir = geom.RIGHT[s_dir]

    -- allow height changes at big junctions (specified by the skin)

    if skin.south then floor_diffs[s_dir] = skin.south.h end
    if skin.north then floor_diffs[n_dir] = skin.north.h end
    if skin.east  then floor_diffs[e_dir] = skin.east.h  end
    if skin.west  then floor_diffs[w_dir] = skin.west.h  end

    -- we may enter the junction from a direction other than south
    -- (relative to the prefab).  So adjust the current floor_h
    -- (which moves the whole prefab up or down) to ensure the
    -- floor heights at the entry position match.
    local diff_h = floor_diffs[from_dir] or 0

    floor_h = floor_h + floor_diffs[s_dir] - diff_h
  end


  -- only the "I" pieces can become stairs or lifts
  -- (everything else must have no height changes)

  P.floor_h = floor_h

  if P.h_shape == "I" and not (H.big_junc or H.joiner) and
     not P.crossover_hall and
     (rand.odds(H.stair_prob) or P.double_peer) and
     (not H.double_fork or P.double_peer)
  then
    -- reverse Z direction in a double hallway when hit the fork section,
    -- which means the other side mirrors the first side
    if P.double_peer and P.double_peer.floor_h and H.need_flip and not H.flipped_double then
      z_dir = -z_dir
      H.flipped_double = true
    end

    P.h_extra = "stair"
    P.h_dir   = (z_dir < 0 ? 10 - from_dir ; from_dir)

    -- FIXME: pick stair kind ("short" / "medium" / "tall")
    --        (only one kind per hallway)

    P.h_stair_kind = "lift"
    P.h_stair_h = rand.pick { 104, 128, 166 }

    floor_h = floor_h + P.h_stair_h * z_dir

    -- stairs and lifts require chunk has the lowest height
    if z_dir < 0 then
      P.floor_h = floor_h
    end
  end

  if (P.h_shape == "C" or P.h_shape == "P") and rand.odds(15) and not H.double_fork then
    z_dir = -z_dir
  end

  -- recursively handle branches

  local did_a_branch = false

  each dir in rand.dir_list() do
    local f_h = floor_h + (floor_diffs[dir] or 0)

    if dir == from_dir then continue end

    local P2 = P.hall_link[dir]

    if P2 and P2.hall == H and not seen[P2] then
      H:stair_flow(P2, 10 - dir, f_h, z_dir, seen)
      did_a_branch = true
    end

    -- transmit floor height into a destination room

    local LINK = P.link[dir]

    if LINK and not (LINK.conn and LINK.conn.kind == "double_R") then
-- stderrf("stair_flow: LINK = \n%s\n\n", table.tostr(LINK, 2))
      local C3 = LINK.C1

      if P:contains_chunk(C3) then C3 = LINK.C2 end

      assert(not P:contains_chunk(C3))

      C3.floor_h = f_h
    end

    if did_a_branch and rand.odds(50) and not H.double_fork then
      z_dir = -z_dir
    end
  end
end



function HALLWAY_CLASS.cycle_flow(H, C, from_dir, z, i_deltas, seen)
  -- Note: this code will only work on a simple (non-forked) hallway

  seen[C] = true

  C.floor_h = z

  local climb_h = math.min(PARAM.jump_height, 32)

  if C.h_shape == "I" and C.section.shape != "big_junc" and
     not C.crossover_hall
  then
    local dz = table.remove(i_deltas, 1)
    local abs_dz = math.abs(dz)
    local z_dir = (dz < 0 ? -1 ; 1)

    -- only need a stair if distance is too big for player to climb
    if abs_dz > climb_h then

      C.h_dir = (dz < 0 ? 10 - from_dir ; from_dir)
      
      -- need a lift?
      if abs_dz > 80 + PARAM.step_height then
        C.h_extra = "lift"
        C.h_stair_h = abs_dz
      else
        C.h_extra = "stair"
        C.h_stair_h = math.min(abs_dz, 80)
      end

      z = z + dz

      -- stairs and lifts require chunk has the lowest height
      if z_dir < 0 then
        C.floor_h = z
      end
    else

      -- accumulate unused delta into next one
      if dz != 0 and #i_deltas > 0 then
        i_deltas[1] = i_deltas[1] + dz
      end
    end

  end


  -- handle rest of hallway

  each dir in rand.dir_list() do
    if dir == from_dir then continue end

    local C2 = C.hall_link[dir]

    if C2 and not seen[C2] then
      H:cycle_flow(C2, 10 - dir, z, i_deltas, seen)
    end
  end
end



function HALLWAY_CLASS.handle_cycle(H, start_C, from_dir, start_z)
  -- find exit chunk
  local exit_C
  local exit_dir

  each C in H.chunks do
    for dir = 2,8,2 do
      if C.link[dir] and not (C == start_C and dir == from_dir) then
        exit_C   = C
        exit_dir = dir
        break
      end
    end
  end

  if not exit_C then
    error("cannot find exit from cycle hallway")
  end

  -- determine the target height
  local LINK = exit_C.link[exit_dir]

  local room_C = (LINK.C1 == exit_C ? LINK.C2 ; LINK.C1)

  local exit_z = assert(room_C.floor_h)

  local z_diff = exit_z - start_z


  -- stairs can only be placed in the "I" pieces -- collect them
  local i_pieces = {}

  each C2 in H.chunks do
    if not C2.crossover_hall then
      if C2.h_shape == "I" then table.insert(i_pieces, C2) end
    end
  end

  
  -- the delta we want for each i_piece (can be zero)
  local i_deltas = {}

  if #i_pieces > 0 then
    for n = 1,#i_pieces do
      i_deltas[n] = z_diff / #i_pieces
    end
  end

gui.debugf("Bicycle @ %s : %d --> %d  (%d i_pieces)\n",
           H:tostr(), start_z, exit_z, #i_pieces);

  H:cycle_flow(start_C, from_dir, start_z, i_deltas, {})
end



function HALLWAY_CLASS.update_seeds_for_chunks(H)
  -- TODO: bbox of hallway

  for sx = 1,SEED_W do for sy = 1,SEED_TOP do
    local S = SEEDS[sx][sy]

    if S.hall == H and not S.chunk then
      S.hall = nil
    end
  end end
end



function HALLWAY_CLASS.set_cross_mode(H)
  assert(H.quest)
  assert(H.crossover)
  assert(H.crossover.quest)

  local id1 = H.quest.id
  local id2 = H.crossover.quest.id

  if id1 < id2 then
    -- the crossover bridge is part of a earlier quest, so
    -- we must not let the player fall down into this room
    -- (and subvert the quest structure).
    --
    -- Hence the crossover becomes a "cross under" :)

    H.cross_mode = "channel"
  else
    H.cross_mode = "bridge"
  end

-- stderrf("CROSSOVER %s : %s (id %d over %d)\n", H:tostr(), H.cross_mode, id1, id2)
end



function HALLWAY_CLASS.cross_diff(H)
  assert(H.cross_mode)

  if H.cross_mode == "bridge" then
    return rand.pick { 96, 96, 128, 128, 128, 128, 160, 192, 256 }
  else
    return (PARAM.jump_height or 24) + rand.pick { 40, 40, 64, 64, 96, 128 }
  end
end



function HALLWAY_CLASS.limit_crossed_room(H)
  local R = H.crossover

  if R.done_heights then return end

  local min_h = H.min_floor_h
  local max_h = H.max_floor_h

  local diff = H:cross_diff()

  if H.cross_mode == "bridge" then
    R.floor_limit = { -9999, min_h - diff }
  else
    R.floor_limit = { max_h + diff, 9999 }
  end
end



function HALLWAY_CLASS.floor_stuff(H, entry_conn)
  ---- if H.done_heights then return end

stderrf("hallway floor_stuff for %s\n", H:tostr())

if H.joiner then stderrf("   JOINER !!!!\n") end

  assert(not H.done_heights)

  H.done_heights = true

  assert(entry_conn)
  assert(entry_conn.K1)

  local entry_K = assert(entry_conn.K2)
  local entry_h = assert(entry_conn.C1.floor_h)
  local entry_dir = entry_conn.dir1

  if entry_conn.kind == "double_L" or entry_conn.kind == "double_R" then
    H.need_flip = true
  end

  if H.cross_limit then
    if entry_h < H.cross_limit[1] then entry_h = H.cross_limit[1] end
    if entry_h > H.cross_limit[2] then entry_h = H.cross_limit[2] end
-- stderrf("applied cross_limit: entry_h --> %d\n", entry_h)
  end

--[[
  if #H.sections == 1 and not H.is_cycle then
    H.mini_hall = true
  end
--]]

  H:create_pieces()
  H:categorize_pieces()

----???  H:update_seeds_for_chunks()

  H:peer_double_chunks()

  H.stair_prob = 35 + 65  --!!!!! FIXME

  -- general vertical direction
  local z_dir = rand.sel(50, 1, -1)

  if H.is_cycle then
    H:handle_cycle(entry_K, 10 - entry_dir, entry_h)

  else
    H:stair_flow(entry_K, 10 - entry_dir, entry_h, z_dir, {})
  end

  H.min_floor_h = entry_h
  H.max_floor_h = entry_h

  each P in H.sections do
    assert(P.floor_h)

    if not P.crossover_hall then
      H.min_floor_h = math.min(H.min_floor_h, P.floor_h)
      H.max_floor_h = math.max(H.max_floor_h, P.floor_h)
    end
  end

  if H.crossover then
    H:limit_crossed_room()
  end
end


--------------------------------------------------------------------


function HALLWAY_CLASS.check_sky_hall(H)
  local info = {}

  local sky_count = 0
  local total     = 0

  each C in H.chunks do
    if not C.crossover_hall and not (C.h_shape == "P" or C.h_shape == "T") then

      local touches_sky

      for dir = 2,8,2 do
        if not C.link[dir] and C:neighbor_info(dir, info, "sky_only") then
          touches_sky = true
        end
      end -- dir

      if touches_sky then sky_count = sky_count + 1 end
      total = total + 1
    end
  end

--[[ DEBUG
stderrf("check_sky_hall @ %s : %d/%d\nfloor range (%d..%d)\n%s\n\n",
        H:tostr(), sky_count, total,
        H.min_floor_h, H.max_floor_h,
        table.tostr(info))
--]]

  -- Requirements:
  if sky_count >= math.max(1, total / 3) and
     info.f_max and H.min_floor_h >= info.f_max and
     info.c_min and H.max_floor_h + 80 <= info.c_min
  then
    return info.c_min
  end

  return nil  -- not possible
end



function HALLWAY_CLASS.select_piece(H, P)
  local shape = P.h_shape

  if P.h_extra == "stair" then shape = assert(P.h_stair_kind) end
  if P.h_extra == "lift"  then shape = "lift" end

  local long, deep = P:long_deep(P.h_dir)

  local env =
  {
    seed_w = 1
    seed_h = 1
  }

  local reqs =
  {
    kind  = "hall"
    group = LEVEL.hall_group
    shape = shape
  }

--[[
  -- find all skins which match this mode (etc)
  local source_tab = H.group and H.group.parts

  if H.mini_hall and H.is_secret then
    return "Secret_Mini"  -- FIXME: THEME.secret_halls
  end

  if H.mini_hall or H.big_junc then
    source_tab = assert(THEME.mini_halls)

    -- don't put a doorish mini-hall next to a locked door
---FIXME    if C:has_locked_door() then
---FIXME      reqs.door = 0
---FIXME    end
  end
--]]

  -- FIXME: handle pieces that should only occur in-between other pieces
--[[
  each name in table.keys(tab) do
    local skin = GAME.SKINS[name]

    if skin._in_between and (not H.last_piece or H.last_piece == name) then
      tab[name] = nil
    end
  end
--]]

  return Room_pick_skin(env, reqs)
end



function HALLWAY_CLASS.select_big_junc(H, P)
  local env =
  {
    seed_w = 3
    seed_h = 3
  }

  local reqs =
  {
    kind  = "junction"
    shape = P.h_shape
  }

  -- alternate requirements : match the hallway group

  local reqs2 = table.copy(reqs)

  reqs2.group = LEVEL.hall_group

  return Room_pick_skin(env, reqs, reqs2)
end



function HALLWAY_CLASS.select_joiner(H, P)
  local R1, R2 = H:joiner_rooms()

  local long, deep = P:long_deep(P.h_dir)

  local env =
  {
--!!!!    seed_w = long
--!!!!    seed_h = deep

    room_kind = R1.kind
    neighbor  = R2.kind
  }

  -- only allow outdoor joiners if the skies are the same height
  if R1.kind == "outdoor" and R2.kind == "outdoor" and not H.sky_group then
    env.neighbor = "building"
  end

  local reqs =
  {
    kind = "joiner"
  }

  -- alternatively, use a normal hallway piece
  local reqs2 =
  {
    kind  = "hall"
    group = LEVEL.hall_group
    shape = "X"

    prob_mul = 0.01  -- a bit boring
  }

  local reqs3 =  -- or maybe a stair
  {
    kind  = "hall"
    group = LEVEL.hall_group
    shape = "SM"
  }

  return Room_pick_skin(env, reqs, reqs2, reqs3)
end



function HALLWAY_CLASS.build_hall_piece(H, P)
  if not P.skin then
    P.skin = H:select_piece(P)
  end

  local skin1 = P.skin
 
  local skin0 =
  {
    wall  = H.wall_mat,
    floor = H.floor_mat,
    ceil  = H.ceil_mat,
    outer = H.zone.facade_mat
  }

  if H.joiner then
    skin0.wall = skin0.outer
  end

  -- hack for secret exits -- need hallway piece to blend in
  if H.is_secret then
    if H.off_room.kind != "outdoor" then
      skin0.wall = H.off_room.wall_mat
    end
  end

  local T = Trans.section_transform(P, P.h_dir or 2)

  if P.h_stair_kind == "lift" then
    Trans.set_fitted_z(T, P.floor_h, P.floor_h + P.h_stair_h)
  end

  Fabricate_at(H, skin1, T, { skin0, skin1 })

  H.last_piece = skin1.name
end



function HALLWAY_CLASS.build(H)
  each P in H.sections do
    if not P.crossover_hall then
      H:build_hall_piece(P)
    end
  end
end


--------------------------------------------------------------------


function Hallway_prepare()
  local quota = 0

  if STYLE.hallways != "none" then
    local perc = style_sel("hallways", 0, 20, 50, 120)

    quota = (MAP_W * MAP_H * rand.range(1, 2)) * perc / 100 - 1
    
    quota = int(quota)  -- round down
  end

  gui.printf("Hallway quota: %d sections\n", quota)

  LEVEL.hall_quota = quota

  -- choose hallway group now
  LEVEL.hall_group = Room_pick_group({ kind = "hall" })

  gui.printf("Hallway group: %s\n", LEVEL.hall_group)
end



function Hallway_scan(start_K, start_dir, mode)

  -- traces out all possible hallways (upto a certain length) from the
  -- starting section and dir.  Each possible hallway is given a score,
  -- and LEVEL.best_conn will remember the best hallway (over multiple
  -- calls to this function).


  local function eval_final_hallway(end_K, end_dir, path, stats)
    local L1 = start_K.room or start_K.hall
    local L2 =   end_K.room or   end_K.hall

    if not L2 then return end

    if not Connect_is_possible(L1, L2, mode) then return end

    -- currently we only connect to secret rooms via a mini-hall
    -- TODO: relax this
    if mode == "secret_exit" and #path != 1 then return end

    -- only connect to a big junction straight off a room
    if end_K.shape == "big_junc" and #path != 1 then return end

    -- never connect to the hallway "spokes" off a big junction
    if end_K.shape != "big_junc" and end_K.hall and end_K.hall.big_junc then return end

    -- never connect to secret halls or crossovers
    if end_K.hall and end_K.hall.is_secret then return end
    if end_K.hall and end_K.hall.crossover then return end

    -- crossovers must be distinct (not same as start or end)
    if stats.crossover and end_K.room == stats.crossover then return end

    -- cycles must connect two rooms, not hallways
    -- (that's because we don't want to merge and forget the cycle-ness)
    -- TODO: relax this to allow connecting onto a big junction
    if mode == "cycle" and end_K.hall then return end
    
    local merge = false

    -- Note: currently _REQUIRE_ all hallways to merge, since there's no
    --       logic for placing locked doors between two hallway prefabs
    if end_K.hall and not end_K.hall.crossover then -- and rand.odds(95) then
      merge = true
    end

    local score1 = start_K:eval_exit(start_dir)
    local score2 =   end_K:eval_exit(  end_dir)
    assert(score1 >= 0 and score2 >= 0)

    local score = (score1 + score2) * 10

    -- bonus for connecting to a central hub room
    if L1.central_hub or (end_K.room and end_K.room.central_hub) then
      score = score + 155
    -- big bonus for using a big junction
    elseif end_K.shape == "big_junc" then
      score = score + 120
      merge = true
    elseif stats.big_junc then
      score = score + (LEVEL.ignore_big_junctions ? -300 ; 80)
      merge = false

      if end_K.hall then return end
    end

    -- prefer secret exits DO NOT connect to the start room
    if mode == "secret_exit" then
      if L2.purpose == "START" then
        score = score - 300
      end
      if L2.kind == "outdoor" then
        score = score - 50
      end
    end

    if stats.crossover then
      local factor = style_sel("crossovers", 0, -10, 0, 300)
      local len = 0
      each K in path do if K.used then len = len + 1 end end
      score = score + (len ^ 0.25) * factor
      merge = false
      if end_K.hall then return end
    end

    -- prefer cycles between the same quest
    local need_lock

    if mode == "cycle" and
       (L1.quest != L2.quest or
        L1.purpose == "SOLUTION" or
        L2.purpose == "SOLUTION")
    then                    

      if L1.quest != L2.quest then
        local next_quest = L1.quest

        if L2.quest.id > next_quest.id then
          next_quest = L2.quest
        end

        assert(next_quest.entry_conn)

        need_lock = assert(next_quest.entry_conn.lock)

      else
        -- shortcut out of a key room
        assert(not (L1.purpose == "SOLUTION" and L2.purpose == "SOLUTION"))

        if L1.purpose == "SOLUTION" then
          need_lock = assert(L1.purpose_lock)
        else
          assert(L2.purpose == "SOLUTION")
          need_lock = assert(L2.purpose_lock)
        end
      end

      -- never make them if it would need a keyed door, but the game
      -- uses up keys (since key is needed for original door).
      if need_lock.kind == "KEY" and PARAM.lose_keys then
        return
      end

      score = score - 40
    end


    -- score is now computed : test it

    if score < LEVEL.best_conn.score then return end


    --- OK ---

    local H = HALLWAY_CLASS.new()

    H.sections = path
    H.conn_group = L1.conn_group

    if end_K.shape == "big_junc" then
      H.big_junc = end_K
    else
      H.big_junc = stats.big_junc
    end

    if not H.big_junc and #H.sections == 1 and end_K.room and
       (end_K.kx == start_K.kx or end_K.ky == start_K.ky)
    then
      H.joiner = true
    end

    if mode == "secret_exit" then
      H.is_secret = true
      H.off_room  = L2
    end

    if stats.crossover then
      H.crossover = stats.crossover
    end


    local D1 = CONN_CLASS.new("normal", L1, H, start_dir)

    D1.K1 = start_K
    D1.K2 = H.sections[1]


    -- Note: some code assumes that D2.L2 is the destination room/hall

    local D2 = CONN_CLASS.new("normal", H, L2, 10 - end_dir)

    D2.K1 = table.last(H.sections)
    D2.K2 = end_K

    -- need a secret door?
    if mode == "secret_exit" then
      D2.kind = "secret"
    end


    -- handle quest difference : need to lock door (cycles only)

    if need_lock then
      D2.lock = need_lock
    end


    LEVEL.best_conn =
    {
      score = score
      stats = stats
      D1 = D1
      D2 = D2
      hall  = H
      merge = merge
      onto_hall_K = (end_K.hall ? end_K ; nil)
    }
  end


  local function can_begin_crossover(K, N, stats)
    if not PARAM.bridges then return false end

--!!!!!!!!!! CROSSOVERS CURRENTLY DISABLED
do return false end

    if STYLE.crossovers == "none" then return false end

    -- never do crossovers for cycles (TODO: review this)
    if mode == "cycle" then return false end

    -- FIXME: LEVEL.crossover_quota

    -- only enter the room at a junction (i.e. through a hallway channel)
    if K.shape != "junction" then return false end

    if not N.room then return false end

    -- crossovers must be distinct (not same as start or end)
    if N.room == start_K.room then return false end

    -- limit of one per room
    -- [cannot do more because crossovers limit the floor heights and
    --  two crossovers can lead to an unsatisfiable range]
    if N.room.crossover_hall then return false end

    -- if re-entering a room, must be the same one!
    if stats.crossover and N.room != stats.crossover then return false end

    -- !!!! FIXME: caves are not yet Cross-Over friendly
    if N.room.kind == "cave" then return false end

    return true
  end


  local function hall_flow(K, from_dir, path, stats, quota)
    assert(K)

    -- must be a free section except when crossing over a room
    if not (stats.crossover and stats.crossover == K.room) then
      assert(not K.used)
    end

    -- already part of current hallway?
    if table.has_elem(path, K) then return end

    local crossing_over = K.used

    if not (K.shape == "vert" or K.shape == "horiz" or
            K.shape == "junction" or K.shape == "big_junc")
    then
      return  -- not a hallway section
    end

    -- can only flow through a big junction when coming straight off
    -- a room (e.g. ROOM --> HORIZ --> BIG_JUNC).
    if K.shape == "big_junc" and #path != 1 then return end

    -- no big junctions for cycles
    if K.shape == "big_junc" and mode == "cycle" then return end


    --- OK ---

--stderrf("hall_flow: visited @ %s from:%d\n", K:tostr(), from_dir)
--stderrf("{\n")

    table.insert(path, K)

    if K.shape == "big_junc" then
      stats.big_junc = K
    end

    -- now recursively flow down the other directions

    for dir = 2,8,2 do
      -- cannot go back the way we came
      if dir == from_dir then continue end

      local N = K:neighbor(dir)
      if not N then continue end

      -- reached a room?  if so, evaluate this hallway

      if (K.shape != "big_junc" or N.room) and not crossing_over then
--stderrf("  testing conn @ dir:%d\n", dir)
        eval_final_hallway(N, 10 - dir, path, stats)
      end

      -- can continue this hallway?
      if quota < 1 then continue end

      -- limit length of big junction hallways
      if stats.big_junc and #path >= 3 then continue end

      local do_cross = false

      -- begin crossover? (or continue one)
      if N.used then
        -- don't allow crossover to walk into another room
        if crossing_over and N.room != stats.crossover then continue end

        if not crossing_over and not can_begin_crossover(K, N, stats) then continue end

        do_cross = true
      end

      -- must turn at a junction, except in emergency mode

      if K.shape != "junction" or geom.is_perpendic(dir, from_dir) or
         mode == "emergency" or crossing_over
      then

--stderrf("  recursing @ dir:%d\n", dir)
        local new_stats = table.copy(stats)
        if do_cross then new_stats.crossover = N.room end

        local new_quota = quota - (N.used ? 0 ; 1)

        hall_flow(N, 10 - dir, table.copy(path), new_stats, new_quota)
      end
    end
--stderrf("}\n")
  end


  ---| Hallway_scan |---

  -- always begin from a room
  assert(start_K.room)

  local N = start_K:neighbor(start_dir)

  if not N or N.used then return end

  local quota = 4

  if STYLE.hallways == "none"  then quota = 0 end
  if STYLE.hallways == "heaps" then quota = 6 end

  quota = math.min(quota, LEVEL.hall_quota)

  -- when normal connection logic has failed, allow long hallways
  if mode == "emergency" then quota = 8 end

  hall_flow(N, 10 - start_dir, {}, {}, quota)
end



function Hallway_add_doubles()

  -- looks for places where a "double hallway" can be added.
  -- these are where the hallways comes around two sides of a room
  -- and connects on both sides (instead of straight on).

  -- Note: this is done _after_ all the connections have been made
  -- for two reasons:
  --    (1) don't want these to block normal connections
  --    (2) don't want other connections joining onto these

  local function find_conn_for_double(K, dir)
    each D in LEVEL.conns do
      if D.kind == "normal" then
        if D.K1 == K and D.dir1 == dir then return D end
        if D.K2 == K and D.dir2 == dir then return D end
      end
    end

    return nil
  end


  local function try_add_at_section(H, K, dir)
    -- check if all the pieces we need are free
    local  left_dir = geom.LEFT [dir]
    local right_dir = geom.RIGHT[dir]

    local  left_J = K:neighbor(left_dir)
    local right_J = K:neighbor(right_dir)

    if not  left_J or  left_J.used then return false end
    if not right_J or right_J.used then return false end

    local  left_K =  left_J:neighbor(dir)
    local right_K = right_J:neighbor(dir)

    if not  left_K or  left_K.used then return false end
    if not right_K or right_K.used then return false end

    -- hallway widths on each side must be the same
    if geom.is_vert(dir) then
      if left_K.sw != right_K.sw then return false end
    else
      if left_K.sh != right_K.sh then return false end
    end

    -- size check
    local room_K = K:neighbor(dir)
    if not room_K.room then return false end

    -- rarely connect to caves
    if room_K.room.kind == "cave" and rand.odds(80) then return false end

    assert(room_K ==  left_K:neighbor(right_dir))
    assert(room_K == right_K:neighbor( left_dir))

    local long, deep = room_K.sw, room_K.sh
    if geom.is_horiz(dir) then long, deep = deep, long end

    if deep < 3 then return false end

    -- fixme: this should not fail
    local D1 = find_conn_for_double(K, dir)
    if not D1 then return false end

    -- never from/to secret exits
    if D1.L1.purpose == "SECRET_EXIT" or
       D1.L2.purpose == "SECRET_EXIT"
    then return false end

    -- don't have a pair of keyed doors if the game uses up keys
    if PARAM.lose_keys and D1.lock and D1.lock.kind == "KEY" then
      return false
    end

    -- less chance if entrance was locked 
    local entry_D = find_conn_for_double(K, 10 - dir)

    if entry_D and entry_D.lock then
      if entry_D.lock.kind == "KEY" then return false end
      if rand.odds(65) then return false end
    end


    ---- MAKE IT SO ----

    gui.debugf("Double hallway @ %s dir:%d\n", K:tostr(), dir)

    H.double_fork = K
    H.double_dir  = dir

    room_K.room.double_K   = room_K
    room_K.room.double_dir = left_dir

    -- update existing connection
    D1.kind = "double_L"

    local need_swap

    if D1.K1 != K then need_swap = true ; D1:swap() end

    assert(D1.K1 == K)
    assert(D1.K2 == room_K)

    D1.K1   = left_K
    D1.dir1 = right_dir
    D1.dir2 = 10 - right_dir

    local D2 = CONN_CLASS.new("double_R", H, room_K.room, left_dir)

    D2.K1 = right_K
    D2.K2 = room_K

    -- restore previous connection order
    -- [this is needed now that doubles are done _after_ quests]
    if need_swap then
      D1:swap()
      D2:swap()
    end

    -- make sure new connection has the same lock
    D2.lock = D1.lock
    
    -- peer them up (not needed ATM, might be useful someday)
    D1.double_peer = D2
    D2.double_peer = D1

    D2:add_it()

    -- peer up the sections too
     left_J.double_peer = right_J
    right_J.double_peer =  left_J

     left_K.double_peer = right_K
    right_K.double_peer =  left_K

    -- add new sections to hallway
    H:add_section(left_J) ; H:add_section(right_J)
    H:add_section(left_K) ; H:add_section(right_K)

    left_J:set_hall(H) ; right_J:set_hall(H)
    left_K:set_hall(H) ; right_K:set_hall(H)

    -- update path through the sections
    K.hall_link[dir] = nil
    K.hall_link[left_dir]  = H
    K.hall_link[right_dir] = H

     left_J.hall_link[dir] = H
    right_J.hall_link[dir] = H

     left_J.hall_link[right_dir] = H
    right_J.hall_link[ left_dir] = H

     left_K.hall_link[10-dir] = H
    right_K.hall_link[10-dir] = H

     left_K.hall_link[right_dir] = room_K.room
    right_K.hall_link[ left_dir] = room_K.room

    return true
  end


  local function try_add_double(H)
    if #H.sections != 1 then return end

    -- never create for cycles, it complicates the height adjusting logic too much
    if H.is_cycle then return end

    local SIDES = { 2,4,6,8 }
    rand.shuffle(SIDES)

    each dir in SIDES do
      local K = H.sections[1]

      if try_add_at_section(H, K, dir) then
        return true
      end
    end

    return false
  end


  --| Hallway_add_doubles |--

do return end  --!!!! FIXME: disabled for now

  local quota = MAP_W / 2 + gui.random()

  local visits = table.copy(LEVEL.halls)
  rand.shuffle(visits)  -- score and sort them??

  each H in visits do
    if quota < 1 then break end

    if try_add_double(H) then
      quota = quota - 1
    end
  end
end


function Hallway_add_streets()
  if LEVEL.special != "street" then return end

  local room = ROOM_CLASS.new()

  room.kind = "outdoor"
  room.street  = true
  room.conn_group = 999

  for kx = 1,SECTION_W do for ky = 1,SECTION_H do
    local K = SECTIONS[kx][ky]

    if K and not K.used then
      K:set_room(room)

      room:add_section(K)
      room:fill_section(K)

      room.map_volume = (room.map_volume or 0) + 0.5
    end
  end end

  -- give each room an apparent height
  each R in LEVEL.rooms do
    R.street_inner_h = rand.pick { 160, 192, 224, 256, 288 }
  end
end

