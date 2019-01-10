------------------------------------------------------------------------
--  Weird Shape Generation
------------------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2014-2015 Andrew Apted
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
------------------------------------------------------------------------


-- lower this to make larger areas
T_BRANCH_PROB = 85

-- if true, allow creation of single-seed squares shapes
ALLOW_CLOSED_SQUARES = true


-- class POINT
--[[
    gx, gy   : grid coordinate

    neighbor : table[DIR] --> POINT

    edges : table[DIR] --> true if an edge to that neighbor

    num_edges : number

    dead : boolean  -- true if cannot make any more edges off here

    ghost : table[DIR] --> edges which were killed (dead ends)

    limit_edges : number  -- do not allow more than this
--]]

GRID = {}

GRID_W = 0
GRID_H = 0


function Weird_save_svg()

  local function wr_line(fp, x1, y1, x2, y2, color, width)
    fp:write(string.format('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="%d" />\n',
             x1, y1, x2, y2, color, width or 1))
  end

  -- grid size
  local SIZE = 14

  local filename = "weird_" .. LEVEL.name .. ".svg"

  local fp = io.open(filename, "w")

  if not fp then error("Cannot create file") end

  -- header
  fp:write('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">\n')

  -- grid
  local min_x = 1 * SIZE
  local min_y = 1 * SIZE

  local max_x = GRID_W * SIZE
  local max_y = GRID_H * SIZE

  for x = 1, GRID_W do
    wr_line(fp, x * SIZE, SIZE, x * SIZE, max_y, "#bbb")
  end

  for y = 1, GRID_H do
    wr_line(fp, SIZE, y * SIZE, max_x, y * SIZE, "#bbb")
  end

  -- for testing boundary outline (only works in GRID_W == GRID_H)
  if SHOW_RED_CROSS then
    wr_line(fp, min_x, min_y, max_x, max_y, "#f00")
    wr_line(fp, max_x, min_y, min_x, max_y, "#f00")
  end

  -- points
  for x = 1, GRID_W do
  for y = 1, GRID_H do
    local P = GRID[x][y]

    local x1 = x * SIZE
    local y1 = (GRID_H - y + 1) * SIZE

    for dir = 6,9 do
      local N = P.neighbor[dir]

      if N then
        local x2 = N.gx * SIZE
        local y2 = (GRID_H - N.gy + 1) * SIZE

        if P.edge[dir] == "boundary" then
          wr_line(fp, x1, y1, x2, y2, "#0f0", 3)

        elseif P.edge[dir] then
          wr_line(fp, x1, y1, x2, y2, "#00f", 3)

        elseif P.ghost[dir] and SHOW_GHOST then
          wr_line(fp, x1, y1, x2, y2, "#f00", 1)
        end
      end

    end -- dir

    if P.is_staircase and SHOW_STAIRCASE then
      fp:write(string.format('<circle cx="%d" cy="%d" r="5" fill="#f0f" />\n', x1, y1))
    end

  end -- x, y
  end

  -- end
  fp:write('</svg>\n')

  fp:close()
end



function Weird_generate(point_W, point_H)
  --
  -- Generates weird shapes in the point grid --> GRID[][]
  --

  local did_change

  local function create_points()
    if (point_W % 2) == 0 or (point_H % 2) == 0 then
      error("Weird_generate : size WxH must be odd numbers")
    end

    GRID_W = point_W
    GRID_H = point_H

    GRID = table.array_2D(GRID_W, GRID_H)

    for gx = 1, GRID_W do
    for gy = 1, GRID_H do
      local P =
      {
        gx = gx
        gy = gy
        neighbor = {}
        edge = {}
        ghost = {}
        num_edges = 0
      }

      GRID[gx][gy] = P

      P.limit_edges = rand.sel(T_BRANCH_PROB, 3, 2)
    end
    end

    -- link neighbors

    for gx = 1, GRID_W do
    for gy = 1, GRID_H do
      local P = GRID[gx][gy]

      each dir in geom.ALL_DIRS do
        local nx, ny = geom.nudge(gx, gy, dir)

        if table.valid_pos(GRID, nx, ny) then
          local N = GRID[nx][ny]
          assert(N)

          P.neighbor[dir] = N
        end
      end
    end
    end
  end


  local function add_edge(gx, gy, dir, kind)
    if not kind then kind = "area" end

    local P = GRID[gx][gy]

    assert(P.edge[dir] == nil)

    P.edge[dir] = kind
    P.num_edges = P.num_edges + 1

    local N = P.neighbor[dir]

    assert(N)
    assert(N.edge[10 - dir] == nil)

    N.edge[10 - dir] = kind
    N.num_edges = N.num_edges + 1
  end


  local function remove_edge(gx, gy, dir)
    local P = GRID[gx][gy]
    local N = P.neighbor[dir]
    assert(N)

    assert(P.edge[dir])
    assert(N.edge[10 - dir])

    P.edge[dir] = nil
    N.edge[10 - dir] = nil

    P.ghost[dir] = true
    N.ghost[10 - dir] = true

    P.num_edges = P.num_edges - 1
    N.num_edges = N.num_edges - 1
  end


  local function is_diagonal_blocked(P, dir)
    -- not a diagonal?
    if not (dir == 1 or dir == 3 or dir == 7 or dir == 9) then
      return false
    end

    local L_dir = geom.LEFT_45[dir]

    local N = P.neighbor[L_dir]
    if not N then return true end

    return N.edge[geom.RIGHT[dir]]
  end


  local function would_close_a_square(P, dir, N)
    if ALLOW_CLOSED_SQUARES then return false end

    for pass = 1, 2 do
      local dir2 = sel(pass == 1, geom.LEFT[dir], geom.RIGHT[dir])

      local P2 = P.neighbor[dir2]

      if P2 then
        if P.edge[dir2] and N.edge[dir2] and P2.edge[dir] then
          return true
        end
      end
    end

    return false
  end


  local function would_be_90_degree(P, dir)
    if P.num_edges ~= 1 then return false end

    each dir2 in geom.ALL_DIRS do
      if P.edge[dir2] then
        return geom.is_perpendic(dir, dir2)
      end
    end

    -- uhh wtf
    return false
  end


  local function eval_edge_at_point(P, dir)
    -- returns < 0 if impossible, score > 0 if possible

    local N = P.neighbor[dir]

    if not N then return -1 end
    if N.dead then return -1 end

    -- already an edge there?
    if P.edge[dir] then return -1 end

    -- ensure it does not cross another diagonal
    if is_diagonal_blocked(P, dir) then return -1 end

    -- rule # 1 : no more than 3 edges at any point
    if P.num_edges >= P.limit_edges then return -1 end
    if N.num_edges >= N.limit_edges then return -1 end

    -- rule # 2 : never make sharp (45-degree) angles
    local L_dir = geom. LEFT_45[dir]
    local R_dir = geom.RIGHT_45[dir]

    if P.edge[L_dir] or P.edge[R_dir] then return -1 end

    if N.edge[10 - L_dir] or N.edge[10 - R_dir] then return -1 end

    -- mirroring checks
    if LEVEL.mirror_gx and N.gx > LEVEL.mirror_gx then return -1 end
    if LEVEL.mirror_gy and N.gy > LEVEL.mirror_gy then return -1 end

    -- other checks [ NOT ACTUALLY USED : REMOVE ]

    if would_close_a_square(P, dir, N) then return -1 end

    if P.no_diagonals or N.no_diagonals then
      if dir == 1 or dir == 3 or dir == 7 or dir == 9 then return -1 end
    end

    if P.no_straights or N.no_straights then
      if dir == 2 or dir == 4 or dir == 6 or dir == 8 then return -1 end
    end

    -- OK --

    -- lass chance if this will form a 90 degree angle
    if would_be_90_degree(P, dir) then
      return 0.1
    end

    return 1
  end


  local function try_edge_at_point(P)
    assert(not P.dead)

    local tab = {}

    each dir in geom.ALL_DIRS do
      local score = eval_edge_at_point(P, dir)

      if score > 0 then
        tab[dir] = score
      end
    end

    -- nothing was possible
    if table.empty(tab) then
      P.dead = true
      return nil
    end

    local dir = rand.key_by_probs(tab)

    add_edge(P.gx, P.gy, dir)

    -- indicate success by returning neighbor
    return P.neighbor[dir]
  end


  local function try_add_edge()
    local points = {}

    for gx = 1, GRID_W do
    for gy = 1, GRID_H do
      local P = GRID[gx][gy]

      if P.num_edges > 0 and P.num_edges < 3 and not P.dead then
        table.insert(points, P)
      end
    end
    end

  --- print("active_points", #points)

    if table.empty(points) then
      return
    end

    local P = rand.pick(points)

    -- keep going until hit dead end or shape joins back onto itself

    repeat
      P = try_edge_at_point(P)
    until not (P and P.num_edges == 0)
  end


  local function remove_dud_point(P)
    each dir in geom.ALL_DIRS do
      if P.edge[dir] then
        remove_edge(P.gx, P.gy, dir)
      end
    end
  end


  local function remove_dead_ends()
    local found

    repeat
      found = false

      for gx = 2, GRID_W-1 do
      for gy = 2, GRID_H-1 do
        local P = GRID[gx][gy]

        if P.num_edges == 1 then
          found = true

          remove_dud_point(P)
        end
      end
      end

    until not found
  end


  local function add_lotsa_edges(qty)
    local count = 10 + GRID_W * GRID_H * qty

    for loop = 1, count do
      try_add_edge()
    end

    remove_dead_ends()
  end


  local function check_point_is_staircase(P)
    -- NOTE: only finds outie corners which can be diagonalized

    if P.num_edges ~= 2 then return false end

    if P.edge[1] or P.edge[3] or P.edge[7] or P.edge[9] then return false end

    if P.edge[4] and P.edge[6] then return false end
    if P.edge[2] and P.edge[8] then return false end

  --[[
    -- skip this point if a connected neighbor point is a staircase
    for dir = 1, 9 do
    if  dir ~= 5 then
      if P.edge[dir] and P.neighbor[dir].is_staircase then
        return false
      end
    end
    end
  --]]


    local x_dir = sel(P.edge[4], 4, 6)
    local y_dir = sel(P.edge[2], 2, 8)

    assert(P.edge[x_dir])
    assert(P.edge[y_dir])

    local NX = P.neighbor[x_dir]
    local NY = P.neighbor[y_dir]

    assert(NX and NY)

    -- diagonal direction from NX
    local corner
    if x_dir == 4 then
      corner = sel(y_dir == 2, 3, 9)
    else
      corner = sel(y_dir == 2, 1, 7)
    end

    -- check for sharp angles (< 90) at these neighbor points

    if NX.edge[y_dir] or NY.edge[x_dir] then return false end

    return true
  end


  local function find_staircases()
    for gx = 1, GRID_W do
    for gy = 1, GRID_H do
      local P = GRID[gx][gy]

      P.is_staircase = check_point_is_staircase(P)
    end
    end
  end


  ------------------------------------------------------------


  local function try_add_boundary_edge(bp, dir)
    local P = GRID[bp.x][bp.y]

    if P.edge[dir] then return false end

    local nx, ny = geom.nudge(bp.x, bp.y, dir)

    if nx <= LEVEL.edge_margin then return false end
    if ny <= LEVEL.edge_margin then return false end

    if nx >= (GRID_W - LEVEL.edge_margin + 1) then return false end
    if ny >= (GRID_H - LEVEL.edge_margin + 1) then return false end

    local m2 = LEVEL.edge_margin + LEVEL.boundary_margin

    if nx > m2 and nx < (GRID_W - m2 + 1) and
       ny > m2 and ny < (GRID_H - m2 + 1)
    then return false end

    -- OK --

    table.insert(bp.edges, { x=bp.x, y=bp.y, dir=dir })

    bp.x = nx
    bp.y = ny

    return true  -- IT WORKED !!
  end


  local function check_new_quadrant(bp)

    local m2 = LEVEL.edge_margin + LEVEL.boundary_margin

    if bp.dir == 6 then
      local dx = bp.x - (GRID_W - m2 + 1)
      local dy = m2 - bp.y

      return dx >= dy

    elseif bp.dir == 4 then
      local dx = m2 - bp.x
      local dy = bp.y - (GRID_H - m2 + 1)

      return dx >= dy

    elseif bp.dir == 8 then
      local dx = bp.x - (GRID_W - m2 + 1)
      local dy = bp.y - (GRID_H - m2 + 1)

      return dy >= dx

    elseif bp.dir == 2 then
      local dx = m2 - bp.x
      local dy = m2 - bp.y

      return dy >= dx

    else
      error("bad quadrant")
    end
  end


  local function iterate_boundary(bp)
    -- returns 'false' when done (cannot continue any further)

    local tab = { [bp.dir] = 50 }

    -- the 'fresh' field forces a straight line after changing the
    -- quadrant : prevents creating a 45 degree angles there.
    if not bp.fresh then
      tab[geom. LEFT_45[bp.dir]] = 60
      tab[geom.RIGHT_45[bp.dir]] = 60
    end

    -- reduce chance of staircases like: /\/\/
    if bp.last_dir and geom.is_corner(bp.last_dir) then
      local dir1 = geom.LEFT [bp.last_dir]
      local dir2 = geom.RIGHT[bp.last_dir]

      if tab[dir1] then tab[dir1] = 5 end
      if tab[dir2] then tab[dir2] = 5 end
    end

    -- find a usable direction
    -- [ luckily we don't need to backtrack ]
    while true do
      if table.empty(tab) then
        error("iterate_boundary failed")
      end

      local dir = rand.key_by_probs(tab)
      tab[dir] = nil

      if try_add_boundary_edge(bp, dir) then
        bp.last_dir = dir
        break;
      end
    end

    bp.fresh = false

    if check_new_quadrant(bp) then
      bp.dir = geom.LEFT[bp.dir]
      bp.fresh = true

      -- have we come full circle?
      if bp.dir == 6 then return false end
    end

    return true
  end


  local function check_rotational_boundary(edges)
    -- for rotationally mirrored maps, check if boundary will survive mirroring

    local mid_gx = (GRID_W + 1) / 2
    local mid_gy = (GRID_H + 1) / 2

    local y1, y2

    each P in edges do
      if P.x == mid_gx then
        if not y1 then
          y1 = P.y
        else
          y2 = P.y
        end
      end
    end

    assert(y1 and y2)

    y1 = math.abs(mid_gy - y1)
    y2 = math.abs(mid_gy - y2)

    return y1 == y2
  end


  local function create_boundary_shape()
    -- keep this number of points free at map edge (never allow boundary there)
    LEVEL.edge_margin = EDGE_SIZE

    -- how many points we can use for the boundary line
    LEVEL.boundary_margin = BOUNDARY_SIZE

    -- current point
    local bp =
    {
      dir = 6
      fresh = true
      edges = {}
    }

    bp.x = LEVEL.edge_margin + 2
    bp.y = bp.x

    bp.start_x = bp.x
    bp.start_y = bp.y

    while iterate_boundary(bp) do end

    if not (bp.x == bp.start_x and bp.y == bp.start_y) then
      -- it failed to hit same point, try again
      -- TODO : a way to "steer" edges which get near the finish point
      --        OR : keep going around until we hit a visited point
      return nil
    end

    if OB_CONFIG.mode == "ctf" and not check_rotational_boundary(bp.edges) then
      return nil  -- try again
    end

    return bp.edges
  end


  local function install_boundary_shape()
    -- create boundary shapes until one is successful
    local edges

    for loop = 1,999 do
      if loop == 999 then
        error("Failed to create a boundary shape.")
      end

      edges = create_boundary_shape()
      if edges then break; end
    end

    -- install the edges
    each E in edges do
      add_edge(E.x, E.y, E.dir, "boundary")
    end
  end


  ------------------------------------------------------------


  local function validate_count(P)
    local count = 0

    each dir in geom.ALL_DIRS do
      if P.edge[dir] then
        count = count + 1
      end
    end

    assert(P.num_edges == count)
  end


  local function mirror_vertically()
    assert((GRID_H % 2) == 1)

    local mid_gy = (GRID_H + 1) / 2

    local HALF_DIRS = { 4,6, 7,8,9 }

    -- this fills the top half, mirroring the bottom half

    for gy = 1, mid_gy do
    for gx = 1, GRID_W do
      local P = GRID[gx][gy]
      local N = GRID[gx][mid_gy + (mid_gy - gy)]

      local dir_list = sel(gy == mid_gy, HALF_DIRS, geom.ALL_DIRS)

      each dir in dir_list do
        if N.edge[dir] then
          remove_edge(N.gx, N.gy, dir)
        end
      end

      each dir in dir_list do
        local dir2 = geom.MIRROR_Y[dir]
        if P.edge[dir2] then
          add_edge(N.gx, N.gy, dir, P.edge[dir2])
        end
      end
    end
    end
  end


  local function mirror_horizontally()
    assert((GRID_W % 2) == 1)

    local mid_gx = (GRID_W + 1) / 2

    local HALF_DIRS = { 2,8, 3,6,9 }

    -- this fills the right half, mirroring the left half

    for gx = 1, mid_gx do
    for gy = 1, GRID_H do
      local P = GRID[gx][gy]
      local N = GRID[mid_gx + (mid_gx - gx)][gy]

      local dir_list = sel(gx == mid_gx, HALF_DIRS, geom.ALL_DIRS)

      each dir in dir_list do
        if N.edge[dir] then
          remove_edge(N.gx, N.gy, dir)
        end
      end

      each dir in dir_list do
        local dir2 = geom.MIRROR_X[dir]
        if P.edge[dir2] then
          add_edge(N.gx, N.gy, dir, P.edge[dir2])
        end
      end
    end
    end
  end


  local function mirror_rotationally()
    assert((GRID_W % 2) == 1)

    local mid_gx = (GRID_W + 1) / 2
    local mid_gy = (GRID_H + 1) / 2

    local HALF_DIRS = { 3,6,9 }

    -- this fills the right half, mirroring (and inverting) the left half

    for gx = 1, mid_gx do
    for gy = 1, GRID_H do
      local P = GRID[gx][gy]
      local N = GRID[mid_gx + (mid_gx - gx)][mid_gy + (mid_gy - gy)]

      local dir_list = sel(gx == mid_gx, HALF_DIRS, geom.ALL_DIRS)

      if gx == mid_gx then
        if P.edge[2] then remove_edge(P.gx, P.gy, 2) end
        if P.edge[8] then remove_edge(P.gx, P.gy, 8) end
      end

      each dir in dir_list do
        if N.edge[dir] then
          remove_edge(N.gx, N.gy, dir)
        end
      end

      each dir in dir_list do
        local dir2 = 10 - dir
        if P.edge[dir2] then
          add_edge(N.gx, N.gy, dir, P.edge[dir2])
        end
      end
    end
    end
  end


  local function mirror_stuff()
    if false then
      mirror_vertically()
    end

    if false then
      mirror_horizontally()
    end

    if OB_CONFIG.mode == "ctf" then
      mirror_rotationally()
    end

    remove_dead_ends()
  end


  local function add_rectangle(px, py, pw, ph, no_subdivide)
    local px2 = px + pw - 1
    local py2 = py + ph - 1

    for a = 0, pw - 2 do
      add_edge(px + a, py,  6)
      add_edge(px + a, py2, 6)
    end

    for b = 0, ph - 2 do
      add_edge(px,  py + b, 8)
      add_edge(px2, py + b, 8)
    end

    -- this only allows edges to connect at the corners
    if no_subdivide then
      for a = 0, pw - 1 do
      for b = 0, ph - 1 do
        if not ((a==0 or a==(pw-1)) and (b==0 or b==(ph-1))) then
          GRID[px + a][py + b].dead = "very"
        end
      end
      end
    end
  end


  local function is_rect_clear(px, py, pw, ph)
    for x = px, px + pw - 1 do
    for y = py, py + ph - 1 do
      local P = GRID[x][y]

      if P.num_edges > 0 then return false end
    end
    end

    return true
  end


  local function place_for_prefab(pw, ph)
    local poss = {}

    for px = 4, GRID_W - pw - 3 do
    for py = 4, GRID_H - ph - 3 do
      if is_rect_clear(px, py, pw, ph) then
        table.insert(poss, { px=px, py=py })
      end
    end
    end

    return rand.pick(poss)
  end


  local function prefabrications()
    LEVEL.prefab_areas = {}

    local max_num = rand.irange(1, 4)

    for loop = 1, max_num do
      -- size is # of grid points, so 2x2 is smallest possible square
      local pw = 3  -- rand.irange(4, 6)
      local ph = 3  -- rand.irange(4, 6)

      local pos = place_for_prefab(pw, ph)

      if pos then
        pos.pw = pw
        pos.ph = ph

        table.insert(LEVEL.prefab_areas, pos)

        add_rectangle(pos.px, pos.py, pw, ph, "no_subdivide")
      end
    end
  end


  ---| Weird_generate |---

  create_points()

  -- boundary also serves as a place to spawn edges from
  install_boundary_shape()

  prefabrications()

  for pass = 1, 4 do
    add_lotsa_edges(2 / pass)

    -- TODO : clear 'dead' flag ??
  end

  mirror_stuff()

  find_staircases()

---DEBUG:
---  Weird_save_svg()
end



------------------------------------------------------------------------


function Weird_create_areas()
  --
  -- Converts the point grid into areas and seeds.
  --

  local function try_set_border(S, dir, kind)
    if kind then
      S.border[dir].edge_kind = kind
    end
  end


  local function convert_to_seeds()
    for gx = 1, GRID_W - 1 do
    for gy = 1, GRID_H - 1 do
      local S = SEEDS[gx][gy]

      local P1 = GRID[gx][gy]
      local P2 = GRID[gx][gy + 1]
      local P3 = GRID[gx + 1][gy]

      local diag_edge = P1.edge[9] or P2.edge[3]

      if diag_edge then
        S:split(sel(P1.edge[9], 3, 1))

        local S2 = S.top

        -- check borders

        if S.diagonal == 3 then
          try_set_border(S,  7, diag_edge)
          try_set_border(S2, 3, diag_edge)
        else
          try_set_border(S,  9, diag_edge)
          try_set_border(S2, 1, diag_edge)
        end

        local T2, T4, T6, T8

        T2 = S ; T8 = S2
        T4 = S ; T6 = S2

        if S.diagonal == 3 then
          T4, T6 = T6, T4
        end

        try_set_border(T4, 4, P1.edge[8])
        try_set_border(T6, 6, P3.edge[8])

        try_set_border(T2, 2, P1.edge[6])
        try_set_border(T8, 8, P2.edge[6])

      else
        -- normal square seed

        try_set_border(S, 4, P1.edge[8])
        try_set_border(S, 6, P3.edge[8])

        try_set_border(S, 2, P1.edge[6])
        try_set_border(S, 8, P2.edge[6])
      end

    end -- gx, gy
    end
  end


  local function assign_area_numbers()
    local area_num = 1

    for sx = 1, SEED_W do
    for sy = 1, SEED_H do
      local S = SEEDS[sx][sy]

      S.area_num = area_num

      if S.top then S.top.area_num = area_num + 1 end

      area_num = area_num + 2
    end -- sx, sy
    end
  end


  local function flood_check_pair(S, dir)
    if not S then return end

    -- blocked by an edge, cannot flood across it
    if S.border[dir].edge_kind then return end

    local N = S:neighbor(dir)

    if not N then return end

    -- already the same?
    if S.area_num == N.area_num then return end

    local new_num = math.min(S.area_num, N.area_num)

    S.area_num = new_num
    N.area_num = new_num

    did_change = true
  end


  local function flood_fill_pass()
    for sx = 1, SEED_W do
    for sy = 1, SEED_H do
      local S  = SEEDS[sx][sy]
      local S2 = S.top

      each dir in geom.ALL_DIRS do
        flood_check_pair(S,  dir)
        flood_check_pair(S2, dir)
      end
    end
    end
  end


  local function area_for_number(num)
    local area = LEVEL.temp_area_map[num]

    if not area then
      -- the mode can become "void" or "scenic" later
      area = AREA_CLASS.new("normal")

      LEVEL.temp_area_map[num] = area
    end

    return area
  end


  local function flood_fill_areas()
    gui.printf("flood_fill_areas....\n")

    assign_area_numbers()

    repeat
gui.printf("  loop %d\n", alloc_id("flood_loop"))
      did_change = false
      flood_fill_pass()
    until not did_change
  end


  local function set_area(S)
    S.area = area_for_number(S.area_num)

    table.insert(S.area.seeds, S)
  end


  local function create_the_areas()
    flood_fill_areas()

    LEVEL.temp_area_map = {}

    for sx = 1, SEED_W do
    for sy = 1, SEED_H do
      local S  = SEEDS[sx][sy]
      local S2 = S.top

      set_area(S)

      if S2 then set_area(S2) end
    end
    end

    LEVEL.temp_area_map = nil
  end


  local function flood_inner_areas(A)
    A.is_inner = true

    each S in A.seeds do
    each dir in geom.ALL_DIRS do
      local N = S:neighbor(dir)

      if not (N and N.area) then continue end

      if N.area.is_inner then continue end

      if S.border[dir].edge_kind == "boundary" then continue end

      flood_inner_areas(N.area)
    end
    end
  end


  local function mark_boundary_areas()
    -- mark areas that lie outside of the boundary outline.

    -- middle seed will be normal (non-boundary)
    local mx = int(SEED_W / 2)
    local my = int(SEED_H / 2)

    local S1 = SEEDS[mx][my]

    flood_inner_areas(assert(S1.area))

    -- bottom left seed will be boundary
    local S2 = SEEDS[1][1]

    if S2.area.is_inner then
      error("mark_boundary_areas failed")
    end

    each area in LEVEL.areas do
      if not area.is_inner then
        area.mode = "scenic"
        area.is_boundary = true
      end
    end
  end


  ---| Weird_create_areas |---

  convert_to_seeds()

  create_the_areas()

  Area_squarify_seeds()
  Area_find_neighbors()

  mark_boundary_areas()
end

