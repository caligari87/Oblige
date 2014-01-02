----------------------------------------------------------------
--  BUILDER
----------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2006-2014 Andrew Apted
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


Trans = {}


DOOM_LINE_FLAGS =
{
  blocked     = 0x01
  block_mon   = 0x02
  sound_block = 0x40

  draw_secret = 0x20
  draw_never  = 0x80
  draw_always = 0x100

  pass_thru   = 0x200  -- Boom
}


HEXEN_ACTIONS =
{
  W1 = 0x0000, WR = 0x0200  -- walk
  S1 = 0x0400, SR = 0x0600  -- switch
  M1 = 0x0800, MR = 0x0A00  -- monster
  G1 = 0x0c00, GR = 0x0E00  -- gun / projectile
  B1 = 0x1000, BR = 0x1200  -- bump
}



function raw_add_brush(brush)
  each C in brush do
    if C.face then
      table.merge(C, C.face)
      C.face = nil

      -- compatibility cruft

      if C.x_offset then C.u1 = C.x_offset ; C.x_offset = nil end
      if C.y_offset then C.v1 = C.y_offset ; C.y_offset = nil end

      if C.line_kind then C.special = C.line_kind ; C.line_kind = nil end
      if C.line_tag  then C.tag     = C.line_tag  ; C.line_tag  = nil end
    end
  end

  gui.add_brush(brush)

  if GAME.add_brush_func then
     GAME.add_brush_func(brush)
  end
end


function raw_add_entity(ent)
  if GAME.format == "quake" then
    ent.mangle = ent.angles ; ent.angles = nil
  end

  gui.add_entity(ent)

  if GAME.add_entity_func then
     GAME.add_entity_func(ent)
  end
end


function raw_add_model(model)
  assert(model.entity)

  model.entity.model = gui.q1_add_mapmodel(model)

  gui.add_entity(model.entity)

  if GAME.add_model_func then
     GAME.add_model_func(model)
  end
end


Trans.TRANSFORM =
{
  -- mirror_x  : flip horizontally (about given X)
  -- mirror_y  : flip vertically (about given Y)
  -- mirror_z

  -- scale_x   : scaling factor
  -- scale_y
  -- scale_z

  -- rotate    : angle in degrees, counter-clockwise,
  --             rotates about the origin

  -- add_x     : translation, i.e. new origin coords
  -- add_y
  -- add_z
}


function Trans.clear()
  Trans.TRANSFORM = {}
end

function Trans.set(T)
  Trans.TRANSFORM = T
end

function Trans.modify(what, value)
  Trans.TRANSFORM[what] = value
end


function Trans.apply_xy(x, y)
  local T = Trans.TRANSFORM

  -- apply mirroring first
  if T.mirror_x then x = T.mirror_x * 2 - x end
  if T.mirror_y then y = T.mirror_y * 2 - y end

  -- apply scaling
  x = x * (T.scale_x or 1)
  y = y * (T.scale_y or 1)

  -- apply rotation
  if T.rotate then
    x, y = geom.rotate_vec(x, y, T.rotate)
  end

  -- apply translation last
  x = x + (T.add_x or 0)
  y = y + (T.add_y or 0)

  return x, y
end


function Trans.apply_z(z, slope)
  local T = Trans.TRANSFORM

  if slope then
    slope = table.copy(slope)

    slope.x1, slope.y1 = Trans.apply_xy(slope.x1, slope.y1)
    slope.x2, slope.y2 = Trans.apply_xy(slope.x2, slope.y2)

    if T.mirror_z then slope.dz = - slope.dz end
  end

  -- apply mirroring first
  if T.mirror_z then z = T.mirror_z * 2 - z end

  -- apply scaling
  z = z * (T.scale_z or 1)

  -- apply translation last
  z = z + (T.add_z or 0)

  return z, slope
end


function Trans.apply_slope(slope)
  if not slope then return nil end

  local T = Trans.TRANSFORM

  slope = table.copy(slope)

  slope.x1, slope.y1 = Trans.apply_xy(slope.x1, slope.y1)
  slope.x2, slope.y2 = Trans.apply_xy(slope.x2, slope.y2)

  if T.mirror_z then slope.dz = - slope.dz end

  slope.dz = slope.dz * (T.scale_z or 1)

  return slope
end


function Trans.apply_angle(ang)
  local T = Trans.TRANSFORM

  if not (T.rotate or T.mirror_x or T.mirror_y) then
    return ang
  end

  if T.mirror_x or T.mirror_y then
    local dx = math.cos(ang * math.pi / 180)
    local dy = math.sin(ang * math.pi / 180)

    if T.mirror_x then dx = -dx end
    if T.mirror_y then dy = -dy end

    ang = math.round(geom.calc_angle(dx, dy))
  end

  if T.rotate then ang = ang + T.rotate end

  if ang >= 360 then ang = ang - 360 end
  if ang <    0 then ang = ang + 360 end

  return ang
end



function Brush_collect_flags(coords)
  each C in coords do
    -- these flags only apply to linedefs
    if not C.x then continue end

    if GAME.format == "doom" then
      local flags = C.flags or 0

      if C.act and PARAM.sub_format == "hexen" then
        local spac = HEXEN_ACTIONS[C.act]
        if not spac then
          error("Unknown act value: " .. tostring(C.act))
        end
        flags = bit.bor(flags, spac)
      end

      each name,value in DOOM_LINE_FLAGS do
        if C[name] and C[name] != 0 then
          flags = bit.bor(flags, value)
          C[name] = nil
        end
      end

      if flags != 0 then
        C.flags = flags

        -- this makes sure the flags get applied
        if not C.special then C.special = 0 end
      end
    end
  end -- C
end


function Trans.brush(kind, coords)
  if not coords then
    kind, coords = "solid", kind
  end

  -- FIXME: mirroring

  -- apply transform
  coords = table.copy(coords)

  each C in coords do
    if C.x then
      C.x, C.y = Trans.apply_xy(C.x, C.y)
    elseif C.b then
      C.b, C.slope = Trans.apply_z(C.b, C.slope)
    else assert(C.t)
      C.t, C.slope = Trans.apply_z(C.t, C.slope)
    end
  end

  table.insert(coords, 1, { m=kind })

  Brush_collect_flags(coords)

  raw_add_brush(coords)
end


function Trans.old_brush(info, coords, z1, z2)
---???  if type(info) != "table" then
---???    info = get_mat(info)
---???  end

  -- check mirroring
  local reverse_it = false

  if Trans.TRANSFORM.mirror_x then reverse_it = not reverse_it end
  if Trans.TRANSFORM.mirror_y then reverse_it = not reverse_it end

  -- apply transform
  coords = table.deep_copy(coords)

  each C in coords do
    C.x, C.y = Trans.apply_xy(C.x, C.y)

    if C.w_face then
      C.face = C.w_face ; C.w_face = nil
    elseif info.w_face then
      C.face = info.w_face
    end
  end

  if reverse_it then
    -- make sure side properties (w_face, line_kind, etc)
    -- are associated with the correct vertex....
    local x1 = coords[1].x
    local y1 = coords[1].y

    for i = 1, #coords-1 do
      coords[i].x = coords[i+1].x
      coords[i].y = coords[i+1].y
    end

    coords[#coords].x = x1
    coords[#coords].y = y1

    table.reverse(coords)
  end

  if z2 < EXTREME_H - 1 then
    table.insert(coords, { t=z2, face=info.t_face })

    coords[#coords].special = info.sec_kind
    coords[#coords].tag     = info.sec_tag
  end

  if z1 > -EXTREME_H + 1 then
    table.insert(coords, { b=z1, face=info.b_face })

    if info.delta_z then
      coords[#coords].delta_z = info.delta_z
    end

    coords[#coords].special = info.sec_kind
    coords[#coords].tag     = info.sec_tag
  end


  -- TODO !!!  transform slope coords (z1 or z2 == table)

-- gui.printf("coords=\n%s\n", table.tostr(coords,4))

  local kind = info.kind or "solid"

  table.insert(coords, 1, { m=kind, peg=info.peg })

  Brush_collect_flags(coords)

  raw_add_brush(coords)
end


function Trans.entity(name, x, y, z, props)
  assert(name)

  if not props then
    props = {}
  end

  local info = GAME.ENTITIES[name] or
               GAME.MONSTERS[name] or
               GAME.WEAPONS[name] or
               GAME.PICKUPS[name]

  if not info then
    gui.printf("\nLACKING ENTITY : %s\n\n", name)
    return
  end
  assert(info.id)

  if info.delta_z then
    z = z + info.delta_z
  elseif PARAM.entity_delta_z then
    z = z + PARAM.entity_delta_z
  end

  x, y = Trans.apply_xy(x, y)

  if info.spawnflags then
    props.spawnflags = (props.spawnflags or 0) + info.spawnflags
  end

  ent = table.copy(props)

  ent.id = info.id
  ent.x  = x
  ent.y  = y
  ent.z  = z

  raw_add_entity(ent)
end


-- COMPAT
function entity_helper(...) return Trans.entity(...) end


function Trans.quad(x1,y1, x2,y2, z1,z2, kind, w_face, p_face)
  if not w_face then
    -- convenient form: only a material name was given
    kind, w_face, p_face = Mat_normal(kind)
  end

  local coords =
  {
    { x=x1, y=y1, face=w_face },
    { x=x2, y=y1, face=w_face },
    { x=x2, y=y2, face=w_face },
    { x=x1, y=y2, face=w_face },
  }

  if z1 then table.insert(coords, { b=z1, face=p_face }) end
  if z2 then table.insert(coords, { t=z2, face=p_face }) end

  Trans.brush(kind, coords)
end


function Trans.rect_coords(x1, y1, x2, y2)
  return
  {
    { x=x2, y=y1 },
    { x=x2, y=y2 },
    { x=x1, y=y2 },
    { x=x1, y=y1 },
  }
end


function Trans.old_quad(info, x1,y1, x2,y2, z1,z2)
  Trans.old_brush(info, Trans.rect_coords(x1,y1, x2,y2), z1,z2)
end


------------------------------------------------------------------------


function Build_prepare_trip()

  -- build the psychedelic mapping
  local m_before = {}
  local m_after  = {}

  for m,def in pairs(GAME.MATERIALS) do
    if not def.sane and
       not (string.sub(m,1,1) == "_") and
       not (string.sub(m,1,2) == "SW") and
       not (string.sub(m,1,3) == "BUT")
    then
      table.insert(m_before, m)
      table.insert(m_after,  m)
    end
  end

  rand.shuffle(m_after)

  LEVEL.psycho_map = {}

  for i = 1,#m_before do
    LEVEL.psycho_map[m_before[i]] = m_after[i]
  end
end


function safe_get_mat(name)
  if OB_CONFIG.theme == "psycho" and LEVEL.psycho_map[name] then
    name = LEVEL.psycho_map[name]
  end

  local mat = GAME.MATERIALS[name]

  -- special handling for DOOM switches
  if not mat and string.sub(name,1,3) == "SW2" then
    mat = GAME.MATERIALS["SW1" .. string.sub(name,4)]
    if mat then
      mat = { t=name, f=mat.f }  -- create new SW2XXX material
      GAME.MATERIALS[name] = mat
    end
  end

  if not mat then
    gui.printf("\nLACKING MATERIAL : %s\n\n", name)
    mat = assert(GAME.MATERIALS["_ERROR"])

    -- prevent further messages
    GAME.MATERIALS[name] = mat
  end

  return mat
end

function get_mat(wall, floor, ceil)
  if not wall then wall = "_ERROR" end

  local w_mat = safe_get_mat(wall)

  local f_mat = w_mat
  if floor then
    f_mat = safe_get_mat(floor)
  end

  local c_mat = f_mat
  if ceil then
    c_mat = safe_get_mat(ceil)
  end

  return
  {
    w_face = { tex=w_mat.t },
    t_face = { tex=f_mat.f or f_mat.t },
    b_face = { tex=c_mat.f or c_mat.t },
  }
end

function Mat_normal(wall, floor)
  if not wall then wall = "_ERROR" end

  local w_mat = safe_get_mat(wall)

  local f_mat = w_mat
  if floor then
    f_mat = safe_get_mat(floor)
  end

  return "solid", { tex=w_mat.t }, { tex=f_mat.f or f_mat.t }
end

function get_sky()
  local mat = assert(GAME.MATERIALS["_SKY"])

  return
  {
    kind = "sky"
    w_face = { tex=mat.t }
    t_face = { tex=mat.f or mat.t }
    b_face = { tex=mat.f or mat.t }
  }
end

function get_liquid()
  assert(LEVEL.liquid)
  local mat = get_mat(LEVEL.liquid.mat)

  mat.t_face.light = LEVEL.liquid.light
  mat.b_face.light = LEVEL.liquid.light

  mat.t_face.special = LEVEL.liquid.special
  mat.b_face.special = LEVEL.liquid.special

  return mat
end

function add_pegging(info, x_offset, y_offset, peg)
  info.w_face.x_offset = x_offset or 0
  info.w_face.y_offset = y_offset or 0
  info.peg = peg or 1

  return info
end


function get_transform_for_seed_side(S, side, thick)
  
  if not thick then thick = S.thick[side] end

  local T = { }

  if side == 8 then T.rotate = 180 end
  if side == 4 then T.rotate = 270 end
  if side == 6 then T.rotate =  90 end

  if side == 2 then T.add_x, T.add_y = S.x1, S.y1 end
  if side == 4 then T.add_x, T.add_y = S.x1, S.y2 end
  if side == 6 then T.add_x, T.add_y = S.x2, S.y1 end
  if side == 8 then T.add_x, T.add_y = S.x2, S.y2 end

  return T, SEED_SIZE, thick
end

function get_transform_for_seed_center(S)
  local T = { }

  T.add_x = S.x1 + S.thick[4]
  T.add_y = S.y1 + S.thick[2]

  local long = S.x2 - S.thick[6] - T.add_x
  local deep = S.y2 - S.thick[8] - T.add_y

  return T, long, deep
end


function diagonal_coords(side, x1,y1, x2,y2)
  if side == 9 then
    return
    {
      { x=x2, y=y1 },
      { x=x2, y=y2 },
      { x=x1, y=y2 },
    }
  elseif side == 7 then
    return
    {
      { x=x1, y=y2 },
      { x=x1, y=y1 },
      { x=x2, y=y2 },
    }
  elseif side == 3 then
    return
    {
      { x=x2, y=y1 },
      { x=x2, y=y2 },
      { x=x1, y=y1 },
    }
  elseif side == 1 then
    return
    {
      { x=x1, y=y2 },
      { x=x1, y=y1 },
      { x=x2, y=y1 },
    }
  else
    error("bad side for diagonal_coords: " .. tostring(side))
  end
end


function get_wall_coords(S, side, thick, pad)
  assert(side != 5)

  local x1, y1 = S.x1, S.y1
  local x2, y2 = S.x2, S.y2

  if side == 4 or side == 1 or side == 7 then
    x2 = x1 + (thick or S.thick[4])
    if pad then x1 = x1 + pad end
  end

  if side == 6 or side == 3 or side == 9 then
    x1 = x2 - (thick or S.thick[6])
    if pad then x2 = x2 - pad end
  end

  if side == 2 or side == 1 or side == 3 then
    y2 = y1 + (thick or S.thick[2])
    if pad then y1 = y1 + pad end
  end

  if side == 8 or side == 7 or side == 9 then
    y1 = y2 - (thick or S.thick[8])
    if pad then y2 = y2 - pad end
  end

  return Trans.rect_coords(x1,y1, x2,y2)
end

