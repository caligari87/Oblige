----------------------------------------------------------------
--  OBLIGE  :  INTERFACE WITH GUI CODE
----------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2006-2010 Andrew Apted
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

OB_CONFIG  = { }

OB_GAMES   = { }
OB_ENGINES = { }
OB_MODULES = { }
OB_THEMES  = { }

UNFINISHED = { }


require 'util'


function ob_traceback(msg)

  -- guard against very early errors
  if not gui or not gui.printf then
    return msg
  end

  gui.printf("\n")
  gui.printf("@1****** ERROR OCCURRED ******\n\n")
  gui.printf("Stack Trace:\n")

  local stack_limit = 40

  local function format_source(info)
    if not info.short_src or info.currentline <= 0 then
      return ""
    end

    local base_fn = string.match(info.short_src, "[^/]*$")

    return string.format("@ %s:%d", base_fn, info.currentline)
  end

  for i = 1,stack_limit do
    local info = debug.getinfo(i+1)
    if not info then break end

    if i == stack_limit then
      gui.printf("(remaining stack trace omitted)\n")
      break;
    end

    if info.what == "Lua" then

      local func_name = "???"

      if info.namewhat and info.namewhat ~= "" then
        func_name = info.name or "???"
      else
        -- perform our own search of the global namespace,
        -- since the standard LUA code (5.1.2) will not check it
        -- for the topmost function (the one called by C code)
        for k,v in pairs(_G) do
          if v == info.func then
            func_name = k
            break;
          end
        end
      end

      gui.printf("  %d: %s() %s\n", i, func_name, format_source(info))

    elseif info.what == "main" then

      gui.printf("  %d: main body %s\n", i, format_source(info))

    elseif info.what == "tail" then

      gui.printf("  %d: tail call\n", i)

    elseif info.what == "C" then

      if info.namewhat and info.namewhat ~= "" then
        gui.printf("  %d: c-function %s()\n", i, info.name or "???")
      end
    end
  end

  return msg
end


-- replace the standard 'print' function
print = function(...)
  local args = { ... }
  local line = ""

  for i = 1,select("#", ...) do
    line = line .. "\t" .. tostring(args[i])
  end

  gui.printf("%s\n", line)
end


function ob_ref_table(op, t)
  if not gui.___REFS then
    gui.___REFS = {}
  end

  if op == "clear" then
    gui.___REFS = {}
    collectgarbage("collect")
    return
  end

  if op == "store" then
    if t == _G then return 0 end
    local id = 1 + #gui.___REFS
    gui.___REFS[id] = t    -- t == table
    return id
  end

  if op == "lookup" then
    if t == 0 then return _G end
    return gui.___REFS[t]  -- t == id number
  end

  error("ob_ref_table: unknown op: " .. tostring(op))
end

function ob_console_dump(info, ...)

  local function dump_tab(t, indent)
    assert(t)

    indent = indent or 0

    local keys = {}
    local longest_k = 1

    for k,v in pairs(t) do
      table.insert(keys, k)
      longest_k = math.max(longest_k, string.len(tostring(k)))
    end

    gui.conprintf("@2%s{\n", string.rep("   ", indent))

    table.sort(keys, function (A,B) return tostring(A) < tostring(B) end)

    local space = string.rep("   ", indent+1)

    for index,k in ipairs(keys) do
      local v = t[k]

      local k_type = type(k)
      local v_type = type(v)

      if not (k_type == "string" or k_type == "number") or k == "___REFS" then
        gui.conprintf("%s@1%s@7 = %s\n", space, tostring(k), tostring(v))

      elseif v_type == "table" then
        if table.empty(v) then
          gui.conprintf("%s%s = @2{ }\n", space, k)
        else
          local label = "table"
          if #v > 0 then label = string.format("list %d", #v) end

          local ref_id = ob_ref_table("store", v)

          gui.printf("%s%s = @b2%s:e:%d:%d@\n", space, k, label, indent+1, ref_id);
        end

      elseif type(v) == "string" then
        gui.conprintf("%s%s = @5\"%s\"\n", space, k, tostring(v))

      elseif type(v) == "function" then
        gui.conprintf("%s@3%s()\n", space, k)

      else
        gui.conprintf("%s%s = @3%s\n", space, k, tostring(v))
      end
    end

    gui.conprintf("@2%s}\n", string.rep("   ",indent))
  end

  function dump_value(val)
    local t = type(val)

    if val == nil then
      gui.conprintf("@1nil\n")
    elseif t == "table" then
      if table.empty(val) then
        gui.conprintf("@2{ }\n")
      else
        dump_tab(val)
      end
    elseif t == "string" then
      gui.conprintf("@5\"%s\"\n", tostring(val))
    else
      gui.conprintf("@3%s\n", tostring(val))
    end
  end


  --| ob_console_dump |--

  if info and info.tab_ref then
    local t = ob_ref_table("lookup", info.tab_ref)
    if t then
      dump_tab(t, info.indent)
    else
      gui.conprintf("@1BAD TABLE REF: %s\n", tostring(info.tab_ref))
    end

    return
  end

  -- grab results and show them
  local args = { ... }
  local count = select("#", ...)

  if count == 0 then
    gui.conprintf("no results\n")
  else
    for index = 1,count do
      dump_value(args[index])
    end
  end
end


function ob_match_conf(T)
  assert(OB_CONFIG.game)
  assert(OB_CONFIG.mode)

  if T.for_games and not T.for_games[OB_CONFIG.game] then
    local game_def = OB_GAMES[OB_CONFIG.game]
    while game_def do
      if not game_def.extends then return false end

      if T.for_games[game_def.extends] then
        break; -- OK --
      end

      game_def = OB_GAMES[game_def.extends]
    end
  end

  if T.for_modes and not T.for_modes[OB_CONFIG.mode] then
    return false
  end

  if T.for_modules then
    for name,_ in pairs(T.for_modules) do
      local def = OB_MODULES[name]
      if not (def and def.shown and def.enabled) then
        return false
      end
    end
  end

  return true --OK--
end


function ob_update_modules()
  -- modules may depend on other modules, hence we may need
  -- to repeat this multiple times until all the dependencies
  -- have flowed through.

  for loop = 1,100 do
    local changed = false

    for name,def in pairs(OB_MODULES) do
      local shown = ob_match_conf(def)

      if shown ~= def.shown then
        changed = true
      end

      def.shown = shown
      gui.show_button("module", name, def.shown)
    end

    if not changed then break; end
  end
end


function ob_update_all()
  ob_update_modules()
end


function ob_defs_conflict(def1, def2)
  if not def1.conflicts then return false end
  if not def2.conflicts then return false end

  for K,_ in pairs(def1.conflicts) do
    if def2.conflicts[K] then
      return true
    end
  end

  return false
end


function ob_set_mod_option(name, option, value)
  local mod = OB_MODULES[name]
  if not mod then
    gui.printf("Ignoring unknown module: %s\n", name)
    return
  end

  if option == "self" then
    -- convert 'value' from string to a boolean
    value = not (value == "false" or value == "0")

    if mod.enabled == value then
      return -- no change
    end

    mod.enabled = value

    -- handle conflicting modules (like Radio buttons)
    if value then
      for other,odef in pairs(OB_MODULES) do
        if odef ~= mod and ob_defs_conflict(mod, odef) then
          odef.enabled = false
          gui.change_button("module", other, odef.enabled)
        end
      end
    end

    -- this is required for parsing the CONFIG.CFG file
    -- [but redundant when the user merely changed the widget]
    gui.change_button("module", name, mod.enabled)

    ob_update_all()
    return
  end


  local def = mod.options and mod.options[option]
  if not def then
    gui.printf("Ignoring unknown option: %s.%s\n", name, option)
    return
  end

  -- this can only happen while parsing the CONFIG.CFG file
  -- (containing some old no-longer-used value).
  if not def.avail_choices[value] then
    gui.printf("WARNING: invalid choice: %s (for option %s.%s)\n",
               value, name, option)
    return
  end

  def.value = value

  -- no need to call ob_update_all
  -- (nothing ever depends on custom options)
end


function ob_set_config(name, value)
  -- See the document 'doc/Config_Flow.txt' for a good
  -- description of the flow of configuration values
  -- between the C++ GUI and the Lua scripts.

  assert(name and value and type(value) == "string")

  if name == "seed" then
    OB_CONFIG[name] = tonumber(value) or 0
    return
  end


  if OB_CONFIG[name] and OB_CONFIG[name] == value then
    return -- no change
  end


  -- validate some important variables
  if name == "game" then
    assert(OB_CONFIG.game)
    if not OB_GAMES[value] then
      gui.printf("Ignoring unknown game: %s\n", value)
      return
    end
  end

  OB_CONFIG[name] = value

  if (name == "game") or (name == "mode") then
    ob_update_all()
  end

  -- this is required for parsing the CONFIG.CFG file
  -- [but redundant when the user merely changed the widget]
  if (name == "game") then
    gui.change_button(name, OB_CONFIG[name])
  end
end


function ob_read_all_config(print_to_log)

  local function do_line(fmt, ...)
    if print_to_log then
      gui.printf(fmt .. "\n", ...)
    else
      gui.config_line(string.format(fmt, ...))
    end
  end

  local unknown = "XXX"

  do_line("-- Game Settings --");

  do_line("seed = %d",   OB_CONFIG.seed or 0)
  do_line("game = %s",   OB_CONFIG.game or unknown)
  do_line("mode = %s",   OB_CONFIG.mode or unknown)
  do_line("engine = %s", OB_CONFIG.engine or unknown)
  do_line("length = %s", OB_CONFIG.length or unknown)
  do_line("")

  do_line("-- Level Architecture --");
  do_line("theme = %s",   OB_CONFIG.theme or unknown)
  do_line("size = %s",    OB_CONFIG.size or unknown)
  do_line("outdoors = %s",OB_CONFIG.outdoors or unknown)
  do_line("secrets = %s",  OB_CONFIG.secrets or unknown)
  do_line("traps = %s",   OB_CONFIG.traps or unknown)
  do_line("")

  do_line("-- Playing Style --");
  do_line("mons = %s",    OB_CONFIG.mons or unknown)
  do_line("strength = %s",OB_CONFIG.strength or unknown)
  do_line("powers = %s",  OB_CONFIG.powers or unknown)
  do_line("health = %s",  OB_CONFIG.health or unknown)
  do_line("ammo = %s",    OB_CONFIG.ammo or unknown)
  do_line("")

  do_line("----- Modules -----")
  do_line("")

  for _,name in ipairs(table.keys_sorted(OB_MODULES)) do
    local def = OB_MODULES[name]

    do_line("@%s = %s", name, sel(def.enabled, "1", "0"))

    -- module options
    if def.options then
      do_line("{")

      for o_name,opt in pairs(def.options) do
        do_line("  %s = %s", o_name, opt.value or unknown)
      end

      do_line("}")
      do_line("")
    end
  end

  do_line("-- END --")
end


function ob_init()

  -- the missing print functions
  gui.printf = function (fmt, ...)
    if fmt then gui.raw_log_print(string.format(fmt, ...)) end
  end

  gui.debugf = function (fmt, ...)
    if fmt then gui.raw_debug_print(string.format(fmt, ...)) end
  end

  gui.conprintf = function (fmt, ...)
    if fmt then gui.raw_console_print(string.format(fmt, ...)) end
  end


  gui.printf("~~ Oblige Lua initialization begun ~~\n")

  table.name_up(OB_GAMES)
  table.name_up(OB_MODULES)


  local function preinit_all(DEFS)
    local removed = {}

    for name,def in pairs(DEFS) do
      if def.preinit_func then
        if def.preinit_func(def) == REMOVE_ME then
          removed[name] = true
        end
      end
    end

    for name,_ in pairs(removed) do
      DEFS[name] = nil
    end
  end

  preinit_all(OB_GAMES)
  preinit_all(OB_MODULES)


  local function button_sorter(A, B)
    if A.priority or B.priority then
      return (A.priority or 50) > (B.priority or 50)
    end

    return A.label < B.label
  end

  local function create_buttons(what, DEFS)
    assert(DEFS)
    gui.debugf("creating buttons for %s\n", what)

    local list = {}

    for name,def in pairs(DEFS) do
      assert(def.name and def.label)
      table.insert(list, def)
    end

    table.sort(list, button_sorter)

    for _,def in ipairs(list) do
      gui.add_button(what, def.name, def.label)

      if what == "game" then
        gui.show_button(what, def.name, true)
      end
    end

    return list[1] and list[1].name
  end

  local function create_mod_options()
    gui.debugf("creating module options\n", what)

    for _,mod in pairs(OB_MODULES) do
      if not mod.options then
        mod.options = {}
      else
        local list = {}

        for name,opt in pairs(mod.options) do
          opt.name = name
          table.insert(list, opt)
        end

        table.sort(list, button_sorter)

        for _,opt in ipairs(list) do
          assert(opt.label)
          assert(opt.choices)

          gui.add_mod_option(mod.name, opt.name, opt.label)

          opt.value = opt.default or opt.choices[1]

          opt.avail_choices = {}

          for i = 1,#opt.choices,2 do
            local id    = opt.choices[i]
            local label = opt.choices[i+1]

            gui.add_mod_option(mod.name, opt.name, id, label)
            opt.avail_choices[id] = 1
          end

          gui.change_mod_option(mod.name, opt.name, opt.value)
        end -- for opt
      end
    end -- for mod
  end

  OB_CONFIG.seed = 0
  OB_CONFIG.mode = "sp" -- GUI code sets the real default

  OB_CONFIG.game   = create_buttons("game",   OB_GAMES)

  create_buttons("module", OB_MODULES)
  create_mod_options()

  ob_update_all()

  gui.change_button("game",   OB_CONFIG.game)

  gui.printf("\n~~ Completed Lua initialization ~~\n\n")
end


function ob_game_format()
  assert(OB_CONFIG)
  assert(OB_CONFIG.game)

  local game = OB_GAMES[OB_CONFIG.game]

  assert(game)

  if game.extends then
    game = assert(OB_GAMES[game.extends])
  end

  return assert(game.format)
end


function ob_build_cool_shit()
  assert(OB_CONFIG)
  assert(OB_CONFIG.game)

  gui.printf("\n\n")
  gui.printf("@5~~~~~~~ Making Levels ~~~~~~~\n\n")

  ob_read_all_config(true)

  gui.ticker()

  Levels_setup()

  local status = Levels_make_all()

  Levels_clean_up()

  gui.printf("\n")

  if status == "abort" then
    gui.printf("@1~~~~~~~ Build Aborted! ~~~~~~~\n\n")
    return "abort"
  end

  gui.printf("@5~~~~~~ Finished Making Levels ~~~~~~\n\n")

  return "ok"
end

