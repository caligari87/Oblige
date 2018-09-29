#----------------------------------------------------------------
# OBLIGE
#----------------------------------------------------------------
#
# GNU Makefile for Unix/Linux with system-wide install
#
# Using this makefile (make, make install) will place the
# executable, script and data files in standard Unixy places.
#
# NOTE: a system-wide FLTK library is assumed
#

PROGRAM=Oblige

# prefix choices: /usr  /usr/local  /opt
PREFIX=/usr/local

SCRIPT_DIR=$(PREFIX)/share/oblige

CXX=g++

OBJ_DIR=obj_linux

OPTIMISE=-O2

# operating system choices: UNIX WIN32
OS=UNIX


#--- Internal stuff from here -----------------------------------

# assumes system-wide FLTK installation
FLTK_CONFIG=fltk-config
FLTK_FLAGS=$(shell $(FLTK_CONFIG) --cflags)
FLTK_LIBS=$(shell $(FLTK_CONFIG) --use-images --ldflags)

CXXFLAGS=$(OPTIMISE) -Wall -D$(OS) -Ilua_src -Iglbsp_src -Iajpoly_src -Iphysfs_src $(FLTK_FLAGS)
LDFLAGS=-L/usr/X11R6/lib
LIBS=-lm -lz $(FLTK_LIBS)


#----- OBLIGE Objects ----------------------------------------------

OBJS=	$(OBJ_DIR)/main.o      \
	$(OBJ_DIR)/m_about.o  \
	$(OBJ_DIR)/m_addons.o  \
	$(OBJ_DIR)/m_cookie.o  \
	$(OBJ_DIR)/m_dialog.o  \
	$(OBJ_DIR)/m_lua.o     \
	$(OBJ_DIR)/m_manage.o  \
	$(OBJ_DIR)/m_options.o  \
	$(OBJ_DIR)/m_trans.o  \
	$(OBJ_DIR)/lib_argv.o  \
	$(OBJ_DIR)/lib_file.o  \
	$(OBJ_DIR)/lib_signal.o \
	$(OBJ_DIR)/lib_util.o  \
	$(OBJ_DIR)/lib_grp.o   \
	$(OBJ_DIR)/lib_pak.o   \
	$(OBJ_DIR)/lib_tga.o   \
	$(OBJ_DIR)/lib_wad.o   \
	$(OBJ_DIR)/lib_zip.o   \
	$(OBJ_DIR)/sys_assert.o \
	$(OBJ_DIR)/sys_debug.o \
	$(OBJ_DIR)/img_bolt.o  \
	$(OBJ_DIR)/img_pill.o  \
	$(OBJ_DIR)/img_carve.o \
	$(OBJ_DIR)/img_relief.o \
	$(OBJ_DIR)/img_font1.o  \
	\
	$(OBJ_DIR)/csg_bsp.o  \
	$(OBJ_DIR)/csg_clip.o  \
	$(OBJ_DIR)/csg_main.o  \
	$(OBJ_DIR)/csg_doom.o  \
	$(OBJ_DIR)/csg_nukem.o \
	$(OBJ_DIR)/csg_quake.o \
	$(OBJ_DIR)/csg_shade.o \
	$(OBJ_DIR)/csg_spots.o \
	$(OBJ_DIR)/dm_extra.o  \
	$(OBJ_DIR)/dm_prefab.o \
	$(OBJ_DIR)/g_doom.o    \
	$(OBJ_DIR)/g_nukem.o   \
	$(OBJ_DIR)/g_quake.o   \
	$(OBJ_DIR)/g_quake2.o  \
	$(OBJ_DIR)/g_quake3.o  \
	$(OBJ_DIR)/g_wolf.o    \
	$(OBJ_DIR)/q_common.o  \
	$(OBJ_DIR)/q_light.o   \
	$(OBJ_DIR)/q_tjuncs.o  \
	$(OBJ_DIR)/q_vis.o     \
	$(OBJ_DIR)/vis_buffer.o \
	$(OBJ_DIR)/vis_occlude.o \
	\
	$(OBJ_DIR)/tx_forge.o  \
	$(OBJ_DIR)/tx_skies.o  \
	$(OBJ_DIR)/ui_build.o  \
	$(OBJ_DIR)/ui_game.o   \
	$(OBJ_DIR)/ui_hyper.o  \
	$(OBJ_DIR)/ui_map.o    \
	$(OBJ_DIR)/ui_module.o \
	$(OBJ_DIR)/ui_rchoice.o \
	$(OBJ_DIR)/ui_window.o \
	\
	$(OBJ_DIR)/zf_menu.o

$(OBJ_DIR)/%.o: gui/%.cc
	mkdir -p $(OBJ_DIR)
	$(CXX) $(CXXFLAGS) -o $@ -c $<


#----- LUA Objects --------------------------------------------------

LUA_OBJS=\
	$(OBJ_DIR)/lua/lapi.o     \
	$(OBJ_DIR)/lua/lcode.o    \
	$(OBJ_DIR)/lua/ldebug.o   \
	$(OBJ_DIR)/lua/ldo.o      \
	$(OBJ_DIR)/lua/ldump.o    \
	$(OBJ_DIR)/lua/lfunc.o    \
	$(OBJ_DIR)/lua/lgc.o      \
	$(OBJ_DIR)/lua/llex.o     \
	$(OBJ_DIR)/lua/lmem.o     \
	$(OBJ_DIR)/lua/lobject.o  \
	$(OBJ_DIR)/lua/lopcodes.o \
	$(OBJ_DIR)/lua/lparser.o  \
	$(OBJ_DIR)/lua/lstate.o   \
	$(OBJ_DIR)/lua/lstring.o  \
	$(OBJ_DIR)/lua/ltable.o   \
	$(OBJ_DIR)/lua/ltm.o      \
	$(OBJ_DIR)/lua/lundump.o  \
	$(OBJ_DIR)/lua/lvm.o      \
	$(OBJ_DIR)/lua/lzio.o     \
	\
	$(OBJ_DIR)/lua/lauxlib.o   \
	$(OBJ_DIR)/lua/lbaselib.o  \
	$(OBJ_DIR)/lua/ldblib.o    \
	$(OBJ_DIR)/lua/liolib.o    \
	$(OBJ_DIR)/lua/lmathlib.o  \
	$(OBJ_DIR)/lua/loslib.o    \
	$(OBJ_DIR)/lua/ltablib.o   \
	$(OBJ_DIR)/lua/lstrlib.o   \
	$(OBJ_DIR)/lua/loadlib.o   \
	$(OBJ_DIR)/lua/linit.o

LUA_CXXFLAGS=$(OPTIMISE) -Wall -DLUA_ANSI -DLUA_USE_MKSTEMP

$(OBJ_DIR)/lua/%.o: lua_src/%.cc
	mkdir -p $(OBJ_DIR)/lua
	$(CXX) $(LUA_CXXFLAGS) -o $@ -c $<


#----- glBSP Objects ------------------------------------------------

GLBSP_OBJS= \
	$(OBJ_DIR)/glbsp/analyze.o  \
	$(OBJ_DIR)/glbsp/blockmap.o \
	$(OBJ_DIR)/glbsp/glbsp.o    \
	$(OBJ_DIR)/glbsp/level.o    \
	$(OBJ_DIR)/glbsp/node.o     \
	$(OBJ_DIR)/glbsp/reject.o   \
	$(OBJ_DIR)/glbsp/seg.o      \
	$(OBJ_DIR)/glbsp/system.o   \
	$(OBJ_DIR)/glbsp/util.o     \
	$(OBJ_DIR)/glbsp/wad.o

GLBSP_CXXFLAGS=$(OPTIMISE) -Wall -DINLINE_G=inline

$(OBJ_DIR)/glbsp/%.o: glbsp_src/%.cc
	mkdir -p $(OBJ_DIR)/glbsp
	$(CXX) $(GLBSP_CXXFLAGS) -o $@ -c $<


#----- AJ-Polygonator Objects --------------------------------------

AJPOLY_OBJS= \
	$(OBJ_DIR)/ajpoly/pl_map.o   \
	$(OBJ_DIR)/ajpoly/pl_poly.o  \
	$(OBJ_DIR)/ajpoly/pl_util.o  \
	$(OBJ_DIR)/ajpoly/pl_wad.o

AJPOLY_CXXFLAGS=$(OPTIMISE) -Wall -Iphysfs_src

$(OBJ_DIR)/ajpoly/%.o: ajpoly_src/%.cc
	mkdir -p $(OBJ_DIR)/ajpoly
	$(CXX) $(AJPOLY_CXXFLAGS) -o $@ -c $<


#----- PhysFS Objects ---------------------------------------------

PHYSFS_OBJS= \
	$(OBJ_DIR)/physfs/byteorder.o  \
	$(OBJ_DIR)/physfs/physfs.o  \
	$(OBJ_DIR)/physfs/unicode.o  \
	$(OBJ_DIR)/physfs/arch_dir.o   \
	$(OBJ_DIR)/physfs/arch_zip.o   \
	$(OBJ_DIR)/physfs/sys_unix.o   \
	$(OBJ_DIR)/physfs/sys_posix.o

PHYSFS_CXXFLAGS=$(OPTIMISE) -Wall

$(OBJ_DIR)/physfs/%.o: physfs_src/%.cc
	mkdir -p $(OBJ_DIR)/physfs
	$(CXX) $(PHYSFS_CXXFLAGS) -o $@ -c $<


#----- Language Analysis ------------------------------------------

LANG_FILES= \
	gui/*.cc \
	gui/*.h  \
	scripts/*.lua \
	engines/*.lua \
	modules/*.lua \
	games/*/*.lua


#----- Targets ----------------------------------------------------

all: $(PROGRAM)

$(PROGRAM): $(OBJS) $(LUA_OBJS) $(GLBSP_OBJS) $(AJPOLY_OBJS) $(PHYSFS_OBJS)
	$(CXX) -Wl,--warn-common $^ -o $@ $(LDFLAGS) $(LIBS)

clean:
	rm -f $(PROGRAM) $(OBJ_DIR)/*.o ERRS
	rm -f $(OBJ_DIR)/lua/*.o
	rm -f $(OBJ_DIR)/glbsp/*.o
	rm -f $(OBJ_DIR)/ajpoly/*.o
	rm -f $(OBJ_DIR)/physfs/*.o
	rm -f LANG_TEMPLATE.txt

halfclean:
	rm -f $(PROGRAM) $(OBJ_DIR)/*.o ERRS

fullclean:
	rm -rf $(PROGRAM) $(OBJ_DIR) ERRS LANG_TEMPLATE.txt

svgclean:
	rm -f grow*.svg

stripped: $(PROGRAM)
	strip --strip-unneeded $(PROGRAM)

install: stripped
	install -o root -m 755 $(PROGRAM) $(PREFIX)/bin/oblige
	#
	install -d $(SCRIPT_DIR)/scripts
	install -d $(SCRIPT_DIR)/engines
	install -d $(SCRIPT_DIR)/modules
	install -d $(SCRIPT_DIR)/addons
	install -d $(SCRIPT_DIR)/language
	#
	install -o root -m 644 scripts/*.lua $(SCRIPT_DIR)/scripts
	install -o root -m 644 engines/*.lua $(SCRIPT_DIR)/engines
	install -o root -m 644 modules/*.lua $(SCRIPT_DIR)/modules
	install -o root -m 644  addons/*.pk3 $(SCRIPT_DIR)/addons
	install -o root -m 644 language/*.*  $(SCRIPT_DIR)/language
	#
	install -d $(SCRIPT_DIR)/data
	install -d $(SCRIPT_DIR)/data/bg
	install -d $(SCRIPT_DIR)/data/masks
	install -o root -m 644 data/*.* $(SCRIPT_DIR)/data
	install -o root -m 644 data/bg/*.* $(SCRIPT_DIR)/data/bg
	install -o root -m 644 data/masks/*.* $(SCRIPT_DIR)/data/masks
	#
	rm -Rf $(SCRIPT_DIR)/games
	cp -a games $(SCRIPT_DIR)/games
	chown -R root $(SCRIPT_DIR)/games
	chmod -R g-s  $(SCRIPT_DIR)/games
	#
	xdg-desktop-menu  install --novendor misc/oblige.desktop
	xdg-icon-resource install --novendor --size 32 misc/oblige.xpm

uninstall:
	rm -v $(PREFIX)/bin/oblige
	rm -Rv $(SCRIPT_DIR)
	#
	xdg-desktop-menu  uninstall --novendor misc/oblige.desktop
	xdg-icon-resource uninstall --novendor --size 32 oblige

xgettext:
	xgettext -o LANG_TEMPLATE.txt -k_ -kN_ -F -i --foreign-user --package-name="Oblige Level Maker" $(LANG_FILES)

.PHONY: all clean halfclean fullclean stripped install uninstall xgettext

#--- editor settings ------------
# vi:ts=8:sw=8:noexpandtab
