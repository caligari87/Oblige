------------------------------------------------------------------------
--  MODULE: Text Generator
------------------------------------------------------------------------
--
--  Copyright (C) 2016 Andrew Apted
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

TEXT_GEN = {}


function TEXT_GEN.generate_texts()

  local info = {}


  local WIDTH_TABLE =
  {
    [' '] = 0.6
    ['.'] = 0.6
    [','] = 0.6
    ['!'] = 0.6
    ['\''] = 0.6
    ['i'] = 0.6
    ['I'] = 0.6
  }

  local function estimate_width(line)
    local width = 0

    for i = 1, #line do
      local ch = string.gsub(line, i, i)

      width = width + (WIDTH_TABLE[ch] or 1.0)
    end

    return width
  end


  local function reformat_text(text)
    -- perform some replacements (e.g. name of the big boss), and
    -- split lines which are too long to fit on the screen.

    -- FIXME
  end


  local function make_a_screen(where)
    -- where can be: "first", "last" or "middle"

    -- FIXME

    if where == "first" then return "Firstly...." end
    if where == "last"  then return "T H E    E N D" end

    return "a\n b\nc\n d\n" ..
           "e\n f\ng\n h\n" ..
           "i\n j\nk\n l\n" ..
           "m\n n\no\n p"
  end


  local function validate_screen(text)
    -- check that the screen is not too long

    local s, num_lines = string.gsub(text, "\n", "\n")

    num_lines = num_lines + 1

stderrf("num_lines = %d\n", num_lines)
    if num_lines > PARAM.max_screen_lines then
      return false
    end

    return true
  end


  local function create_story(num_parts)

    -- TODO : decide some story elements (like who's the boss)

    local parts = {}

    for i = 1, num_parts do
      local where

      -- a single part is treated as the final screen
          if i >= num_parts then where = "last"
      elseif i <= 1 then where = "first"
      else where = "middle"
      end

      local text

      for loop = 1,20 do
        text = make_a_screen(where)

        if validate_screen(text) then
          break;
        end
      end

      table.insert(parts, text)
    end

    return parts
  end


  local function handle_main_texts()
    -- count needed parts (generally 3 or 4)
    local num_parts = 0

    each EPI in GAME.episodes do
      if EPI.bex_mid_name then num_parts = num_parts + 1 end
      if EPI.bex_end_name then num_parts = num_parts + 1 end
    end

  stderrf("num_parts = %d\n", num_parts)

    if num_parts == 0 then return end

    local texts = create_story(num_parts)

    local function get_part()
      return table.remove(texts, 1)
    end

    each EPI in GAME.episodes do
      if EPI.bex_mid_name then EPI.mid_text = get_part() end
      if EPI.bex_end_name then EPI.end_text = get_part() end
    end
  end


  local function handle_secrets()
    local list1 = namelib.generate("TEXT_SECRET",  1, 500)
    local list2 = namelib.generate("TEXT_SECRET2", 1, 500)

    GAME.secret_text  = list1[1]
    GAME.secret2_text = list2[1]
  end


  ---| generate_texts |---

  handle_main_texts()
  handle_secrets()
end


OB_MODULES["text_generator"] =
{
  label = _("Text Generator")
  priority = 84

  game = "doomish"
  engine = "boom"

  hooks =
  {
    get_levels = TEXT_GEN.generate_texts
  }
}
