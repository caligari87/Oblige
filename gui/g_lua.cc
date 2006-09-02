//------------------------------------------------------------------------
//  LUA interface
//------------------------------------------------------------------------
//
//  Oblige Level Maker (C) 2006 Andrew Apted
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//------------------------------------------------------------------------

#include "headers.h"
#include "hdr_lua.h"

#include "g_lua.h"
#include "g_doom.h"
#include "g_glbsp.h"
#include "main.h"

#include "hdr_fltk.h"
#include "ui_dialog.h"
#include "ui_window.h"


static lua_State *LUA_ST;


namespace con
{

// LUA: printf(fmt_str, ...)
//
int print_f(lua_State *L)
{
	int nargs = lua_gettop(L);

	// LUA: string.format(...)
	//
	lua_getglobal(L, "string");
	lua_getfield(L, -1, "format");

	lua_insert(L, 1);  // move function to first slot

	int status = lua_pcall(LUA_ST, nargs, 1, 0);
	
	if (status != 0)
	{
		// FIXME: lua_pcall failed - do what?
	}
	else
	{
		// formatted string
		const char *res = luaL_checkstring(L,1);
		SYS_ASSERT(res);

		fprintf(stderr, "%s", res);
	}

	return 0;
}


static int lev_IDX = 0;
static int lev_TOTAL = 0;


// LUA: at_level(name, idx, total)
//
int at_level(lua_State *L)
{
	lev_IDX = luaL_checkint(L, 2);
	lev_TOTAL = luaL_checkint(L, 3);

	return 0;
}

// LUA: progress(percent)
//
int progress(lua_State *L)
{
	lua_Number perc = luaL_checknumber(L, 1);

	SYS_ASSERT(lev_TOTAL > 0);

	perc = ((lev_IDX-1) * 100 + perc) / lev_TOTAL;

	main_win->build_box->P_Update(perc);

	return 0;
}


// LUA: ticker()
//
int ticker(lua_State *L)
{
	Main_Ticker();

	return 0;
}

// LUA: abort() -> boolean
//
static int abort(lua_State *L)
{
	int value = 0;

	if (main_win->action >= UI_MainWin::ABORT)
		value = 1;

	lua_pushboolean(L, value);
	return 1;
}


// LUA: map_begin(pixel_W, pixel_H)
//
int map_begin(lua_State *L)
{
	int pixel_W = luaL_checkint(L, 1);
	int pixel_H = luaL_checkint(L, 2);

	SYS_ASSERT(1 <= pixel_W && pixel_W < 1000);
	SYS_ASSERT(1 <= pixel_H && pixel_H < 1000);

	main_win->build_box->MapBegin(pixel_W, pixel_H);

	return 0;
}

// LUA: map_end()
//
int map_end(lua_State *L)
{
	main_win->build_box->MapFinish();

	return 0;
}

// LUA: map_pixel(kind)
//
int map_pixel(lua_State *L)
{
	int kind = luaL_checkint(L, 1);

	main_win->build_box->MapPixel(kind);

	return 0;
}

} // namespace con


static const luaL_Reg videolib[] =
{
	{ "printf",     con::print_f },
	{ "at_level",   con::at_level },
	{ "progress",   con::progress },
	{ "ticker",     con::ticker },
	{ "abort",      con::abort },
	
	{ "map_begin",  con::map_begin },
	{ "map_pixel",  con::map_pixel },
	{ "map_end",    con::map_end },

	{ NULL, NULL } // the end
};

int Script_open_video(lua_State *L)
{
	luaL_register(L, "con", videolib);

	return 0;
}


//------------------------------------------------------------------------


static int p_init_lua(lua_State *L)
{
	/* stop collector during initialization */
	lua_gc(L, LUA_GCSTOP, 0);
	{
		luaL_openlibs(L);  /* open libraries */

		Script_open_video(L);

//		Script_register_misc(L);
	}
	lua_gc(L, LUA_GCRESTART, 0);

	return 0;
}

void Script_Init()
{
	LUA_ST = lua_open();
	if (! LUA_ST)
		Main_FatalError("LUA Init failed: cannot create new state");

	int status = lua_cpcall(LUA_ST, &p_init_lua, NULL);
	if (status != 0)
		Main_FatalError("LUA Init failed: cannot load standard libs (%d)", status);

	Doom_InitLua(LUA_ST);

	Script_Load();
}

void Script_Done()
{
	lua_close(LUA_ST);
}

void Script_Load()
{
	int status = luaL_loadfile(LUA_ST, "./oblige.lua"); 

	if (status != 0)
	{
fprintf(stderr, "status: %d\n", status);
		const char *msg = lua_tolstring(LUA_ST, -1, NULL);
fprintf(stderr, "ERR: %s\n", msg);
		Main_FatalError("Unable to load script 'oblige.lua' (%d)\n%s", status, msg);
	}

	status = lua_pcall(LUA_ST, 0, 0, 0);
	if (status != 0)
	{
fprintf(stderr, "status: %d\n", status);
		const char *msg = lua_tolstring(LUA_ST, -1, NULL);
fprintf(stderr, "ERR: %s\n", msg);
		Main_FatalError("Error with script (%d)\n%s", status, msg);
	}

}


static void AddField(lua_State *L, const char *key, const char *value)
{
	SYS_NULL_CHECK(value);

	lua_pushstring(L, key);
	lua_pushstring(L, value);
	lua_rawset(L, -3);
}

void Script_MakeSettings(lua_State *L)
{
	lua_newtable(L);

	AddField(L, "seed", main_win->setup_box->cur_Seed());
	AddField(L, "game", main_win->setup_box->cur_Game());
	AddField(L, "addon",main_win->setup_box->cur_Addon());
	AddField(L, "mode", main_win->setup_box->cur_Mode());
	AddField(L, "size", main_win->setup_box->cur_Size());

	lua_setglobal(LUA_ST, "settings");
}

bool Script_Run()
{
	Script_MakeSettings(LUA_ST);

	// LUA: build_cool_shit()
	//
	lua_getglobal(LUA_ST, "build_cool_shit");

	int status = lua_pcall(LUA_ST, 0, 1, 0);
	if (status != 0)
	{
fprintf(stderr, "status: %d\n", status);
		const char *msg = lua_tolstring(LUA_ST, -1, NULL);
fprintf(stderr, "ERR: %s\n", msg);

		DLG_ShowError("Problem occurred while making level:\n%s", msg);
				
		return false;
	}
	else
	{
		const char *res = lua_tolstring(LUA_ST, -1, NULL);

		if (res && strcmp(res, "ok") == 0)
			return true;

		// FIXME: strcmp(res, "abort")

		return false;
	}
}

