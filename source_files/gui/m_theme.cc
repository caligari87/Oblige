//----------------------------------------------------------------------
//  Theme Editor
//----------------------------------------------------------------------
//
//  Oblige Level Maker
//
//  Copyright (C) 2006-2017 Andrew Apted
//  Modified by Dashodanger
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
//----------------------------------------------------------------------

#include "hdr_fltk.h"
#include "hdr_ui.h"
#include "headers.h"
#include "lib_argv.h"
#include "lib_util.h"
#include "m_addons.h"
#include "m_cookie.h"
#include "m_trans.h"
#include "main.h"

//----------------------------------------------------------------------

const char *Theme_OutputFilename() {

    // save and restore the font height
    // (because FLTK's own browser get totally borked)
    int old_font_h = FL_NORMAL_SIZE;
    FL_NORMAL_SIZE = 14 + KF;

    Fl_Native_File_Chooser chooser;

    chooser.title(_("Select output file"));
    chooser.type(Fl_Native_File_Chooser::BROWSE_SAVE_FILE);

    if (overwrite_warning) {
        chooser.options(Fl_Native_File_Chooser::SAVEAS_CONFIRM);
    }

    chooser.filter("Text files\t*.txt");

    chooser.directory("theme");

    int result = chooser.show();

    FL_NORMAL_SIZE = old_font_h;

    switch (result) {
        case -1:
            LogPrintf("Error choosing output file:\n");
            LogPrintf("   %s\n", chooser.errmsg());

            DLG_ShowError(_("Unable to create the file:\n\n%s"),
                          chooser.errmsg());
            return NULL;

        case 1:  // cancelled
            return NULL;

        default:
            break;  // OK
    }

    static char filename[FL_PATH_MAX + 16];

    const char *src_name = chooser.filename();

#ifdef WIN32
    // workaround for accented characters in a username
    // [ real solution is yet to be determined..... ]

    fl_utf8toa(src_name, strlen(src_name), filename, sizeof(filename));
#else
    snprintf(filename, sizeof(filename), "%s", src_name);
#endif

    // add extension if missing
    char *pos = (char *)fl_filename_ext(filename);
    if (!*pos) {
        strcat(filename, ".");
        strcat(filename, "txt");

        // check if exists, ask for confirmation
        FILE *fp = fopen(filename, "rb");
        if (fp) {
            fclose(fp);
            if (!fl_choice("%s", fl_cancel, fl_ok, NULL,
                           Fl_Native_File_Chooser::file_exists_message)) {
                return NULL;  // cancelled
            }
        }
    }

    return StringDup(filename);
}

const char *Theme_AskLoadFilename() {
        Fl_Native_File_Chooser chooser;

        chooser.title(_("Select Theme file to load"));
        chooser.type(Fl_Native_File_Chooser::BROWSE_FILE);
        
    	chooser.filter("Text files\t*.txt");

    	chooser.directory("theme");

        switch (chooser.show()) {
            case -1:
                LogPrintf("Error choosing load file:\n");
                LogPrintf("   %s\n", chooser.errmsg());

                DLG_ShowError(_("Unable to load the file:\n\n%s"),
                              chooser.errmsg());
                return NULL;

            case 1:  // cancelled
                return NULL;

            default:
                break;  // OK
        }

        static char filename[FL_PATH_MAX + 10];

        strcpy(filename, chooser.filename());

        return filename;
}

static void Parse_Theme_Option(const char *name, const char *value) {

	if (StringCaseCmp(name, "window_scaling") == 0) {
        window_scaling = atoi(value);
        window_scaling = CLAMP(0, window_scaling, 5);
    } else if (StringCaseCmp(name, "font_scaling") == 0) {
        font_scaling = atoi(value);
    } else if (StringCaseCmp(name, "font_theme") == 0) {
        font_theme = atoi(value);
    } else if (StringCaseCmp(name, "widget_theme") == 0) {
        widget_theme = atoi(value);
    } else if (StringCaseCmp(name, "box_theme") == 0) {
        box_theme = atoi(value);
    } else if (StringCaseCmp(name, "button_theme") == 0) {
        button_theme = atoi(value);
    } else if (StringCaseCmp(name, "single_pane") == 0) {
        single_pane = atoi(value) ? true : false;
	} else if (StringCaseCmp(name, "color_scheme") == 0) {
        color_scheme = atoi(value);
	} else if (StringCaseCmp(name, "text_red") == 0) {
        text_red = atoi(value);
	} else if (StringCaseCmp(name, "text_green") == 0) {
        text_green = atoi(value);  
	} else if (StringCaseCmp(name, "text_blue") == 0) {
        text_blue = atoi(value);
	} else if (StringCaseCmp(name, "bg_red") == 0) {
        bg_red = atoi(value);
	} else if (StringCaseCmp(name, "bg_green") == 0) {
        bg_green = atoi(value);  
	} else if (StringCaseCmp(name, "bg_blue") == 0) {
        bg_blue = atoi(value);
	} else if (StringCaseCmp(name, "bg2_red") == 0) {
        bg2_red = atoi(value);
	} else if (StringCaseCmp(name, "bg2_green") == 0) {
        bg2_green = atoi(value);  
	} else if (StringCaseCmp(name, "bg2_blue") == 0) {
        bg2_blue = atoi(value);
	} else if (StringCaseCmp(name, "button_red") == 0) {
        button_red = atoi(value);
	} else if (StringCaseCmp(name, "button_green") == 0) {
        button_green = atoi(value);  
	} else if (StringCaseCmp(name, "button_blue") == 0) {
        button_blue = atoi(value);
	} else if (StringCaseCmp(name, "gradient_red") == 0) {
        gradient_red = atoi(value);
	} else if (StringCaseCmp(name, "gradient_green") == 0) {
        gradient_green = atoi(value);  
	} else if (StringCaseCmp(name, "gradient_blue") == 0) {
        gradient_blue = atoi(value);
	} else if (StringCaseCmp(name, "border_red") == 0) {
        border_red = atoi(value);
	} else if (StringCaseCmp(name, "border_green") == 0) {
        border_green = atoi(value);  
	} else if (StringCaseCmp(name, "border_blue") == 0) {
        border_blue = atoi(value);
	} else if (StringCaseCmp(name, "gap_red") == 0) {
        gap_red = atoi(value);
	} else if (StringCaseCmp(name, "gap_green") == 0) {
        gap_green = atoi(value);  
	} else if (StringCaseCmp(name, "gap_blue") == 0) {
        gap_blue = atoi(value);
    } else {
        LogPrintf("Unknown option: '%s'\n", name);
    }
}

static bool Theme_Options_ParseLine(char *buf) {
    // remove whitespace
    while (isspace(*buf)) {
        buf++;
    }

    int len = strlen(buf);

    while (len > 0 && isspace(buf[len - 1])) {
        buf[--len] = 0;
    }

    // ignore blank lines and comments
    if (*buf == 0) {
        return true;
    }

    if (buf[0] == '-' && buf[1] == '-') {
        return true;
    }

    if (!isalpha(*buf)) {
        LogPrintf("Weird option line: [%s]\n", buf);
        return false;
    }

    // Righteo, line starts with an identifier.  It should be of the
    // form "name = value".  We terminate the identifier and pass
    // the name/value strings to the matcher function.

    const char *name = buf;

    for (buf++; isalnum(*buf) || *buf == '_' || *buf == '.';
         buf++) { /* nothing here */
    }

    while (isspace(*buf)) {
        *buf++ = 0;
    }

    if (*buf != '=') {
        LogPrintf("Option line missing '=': [%s]\n", buf);
        return false;
    }

    *buf++ = 0;

    if (isspace(*buf)) {
        *buf++ = 0;
    }

    // everything after the " = " (note: single space) is the value,
    // and it does not need escaping since our values never contain
    // newlines or embedded spaces (nor control characters, but may
    // contain UTF-8 encoded filenames).

    if (*buf == 0) {
        LogPrintf("Option line missing value!\n");
        return false;
    }

    Parse_Theme_Option(name, buf);
    return true;
}

bool Theme_Options_Load(const char *filename) {
    FILE *option_fp = fopen(filename, "r");

    if (!option_fp) {
        LogPrintf("Missing Theme file -- using defaults.\n\n");
        return false;
    }

    LogPrintf("Loading theme file: %s\n", filename);

    // simple line-by-line parser
    char buffer[MSG_BUF_LEN];

    int error_count = 0;

    while (fgets(buffer, MSG_BUF_LEN - 2, option_fp)) {
        if (!Theme_Options_ParseLine(buffer)) {
            error_count += 1;
        }
    }

    if (error_count > 0) {
        LogPrintf("DONE (found %d parse errors)\n\n", error_count);
    } else {
        LogPrintf("DONE.\n\n");
    }

    fclose(option_fp);

    return true;
}

bool Theme_Options_Save(const char *filename) {
    FILE *option_fp = fopen(filename, "w");

    if (!option_fp) {
        LogPrintf("Error: unable to create file: %s\n(%s)\n\n", filename,
                  strerror(errno));
        return false;
    }

    LogPrintf("Saving theme file...\n");

    fprintf(option_fp, "-- THEME FILE : OBSIDIAN %s\n", OBSIDIAN_VERSION);
    fprintf(option_fp,
            "-- Based on OBLIGE Level Maker (C) 2006-2017 Andrew Apted\n");
    fprintf(option_fp, "-- " OBSIDIAN_WEBSITE "\n\n");

    fprintf(option_fp, "window_scaling      = %d\n", window_scaling);
    fprintf(option_fp, "font_scaling      = %d\n", font_scaling);
    fprintf(option_fp, "font_theme      = %d\n", font_theme);
    fprintf(option_fp, "widget_theme      = %d\n", widget_theme);
    fprintf(option_fp, "box_theme      = %d\n", box_theme);
    fprintf(option_fp, "button_theme      = %d\n", button_theme);
    fprintf(option_fp, "single_pane = %d\n", single_pane ? 1 : 0);
    fprintf(option_fp, "color_scheme      = %d\n", color_scheme);
    fprintf(option_fp, "text_red      = %d\n", text_red);
    fprintf(option_fp, "text_green      = %d\n", text_green);
    fprintf(option_fp, "text_blue      = %d\n", text_blue);
    fprintf(option_fp, "bg_red      = %d\n", bg_red);
    fprintf(option_fp, "bg_green      = %d\n", bg_green);
    fprintf(option_fp, "bg_blue      = %d\n", bg_blue);
    fprintf(option_fp, "bg2_red      = %d\n", bg2_red);
    fprintf(option_fp, "bg2_green      = %d\n", bg2_green);
    fprintf(option_fp, "bg2_blue      = %d\n", bg2_blue);
    fprintf(option_fp, "button_red      = %d\n", button_red);
    fprintf(option_fp, "button_green      = %d\n", button_green);
    fprintf(option_fp, "button_blue      = %d\n", button_blue);
    fprintf(option_fp, "gradient_red      = %d\n", gradient_red);
    fprintf(option_fp, "gradient_green      = %d\n", gradient_green);
    fprintf(option_fp, "gradient_blue      = %d\n", gradient_blue);
    fprintf(option_fp, "border_red      = %d\n", border_red);
    fprintf(option_fp, "border_green      = %d\n", border_green);
    fprintf(option_fp, "border_blue      = %d\n", border_blue);
    fprintf(option_fp, "gap_red      = %d\n", gap_red);
    fprintf(option_fp, "gap_green      = %d\n", gap_green);
    fprintf(option_fp, "gap_blue      = %d\n", gap_blue);
    fprintf(option_fp, "\n");

    fprintf(option_fp, "\n");

    fclose(option_fp);

    LogPrintf("DONE.\n\n");

    return true;
}

//----------------------------------------------------------------------

class UI_ThemeWin : public Fl_Window {
   public:
    bool want_quit;

   private:
    UI_CustomMenu *opt_window_scaling;
    UI_CustomMenu *opt_font_scaling;
    UI_CustomMenu *opt_font_theme;
    UI_CustomMenu *opt_widget_theme;
    UI_CustomMenu *opt_box_theme;
    UI_CustomMenu *opt_button_theme;

    UI_CustomCheckBox *opt_single_pane;
    UI_CustomMenu *opt_color_scheme;
    Fl_Button *opt_text_color;
    Fl_Button *opt_bg_color;
    Fl_Button *opt_bg2_color;
    Fl_Button *opt_button_color;
    Fl_Button *opt_gradient_color;
    Fl_Button *opt_border_color;
    Fl_Button *opt_gap_color;
    Fl_Button *load_theme;
    Fl_Button *save_theme;

   public:
    UI_ThemeWin(int W, int H, const char *label = NULL);

    virtual ~UI_ThemeWin() {
        // nothing needed
    }

    bool WantQuit() const { return want_quit; }

   public:
    // FLTK virtual method for handling input events.
    int handle(int event);
   
    void PopulateFonts() {

		std::string default_name = Fl::get_font_name(0);

		default_name.at(0) = std::toupper(default_name.at(0));

		default_name = default_name.append(" <Default>");

		opt_font_theme->add(_(default_name.c_str()));

  		for (int x = 0; x < num_fonts; x++) {
  		  	for (auto font = font_menu_items[x].begin(); font != font_menu_items[x].end(); ++font) {
    			opt_font_theme->add(font->first.c_str());
  			}
  		}
				
        opt_font_theme->value(font_theme);
		
    }

   private:
    static void callback_Quit(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

        that->want_quit = true;
    }

    static void callback_WindowScaling(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

        window_scaling = that->opt_window_scaling->value();
    }
    
    static void callback_FontScaling(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

        font_scaling = that->opt_font_scaling->value();
    }

    static void callback_FontTheme(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

        font_theme = that->opt_font_theme->value();
        if (font_theme > 0) {
			for (auto font = font_menu_items[font_theme - 1].begin(); font != font_menu_items[font_theme - 1].end(); ++font) {
				font_style = font->second;
				fl_font(font_style, FL_NORMAL_SIZE);
				fl_message_font(font_style, FL_NORMAL_SIZE);
			}
    	} else {
    		font_style = 0;
    		fl_font(0, FL_NORMAL_SIZE);
    		fl_message_font(font_style, FL_NORMAL_SIZE);
    	}
    	main_win->menu_bar->textfont(font_style);
    	main_win->menu_bar->redraw();
    	main_win->game_box->heading->labelfont(font_style);
    	main_win->game_box->game->labelfont(font_style);
    	main_win->game_box->game->textfont(font_style);
    	main_win->game_box->game->copy_label("										");
    	main_win->game_box->engine->labelfont(font_style);
    	main_win->game_box->engine->textfont(font_style);
    	main_win->game_box->engine->copy_label("										");
    	main_win->game_box->engine_help->copy_label("");
    	main_win->game_box->engine_help->labelfont(font_style);
    	main_win->game_box->length->labelfont(font_style);
    	main_win->game_box->length->textfont(font_style);
    	main_win->game_box->length->copy_label("										");
    	main_win->game_box->length_help->copy_label("");
    	main_win->game_box->length_help->labelfont(font_style);
    	main_win->game_box->theme->labelfont(font_style);
    	main_win->game_box->theme->textfont(font_style);
    	main_win->game_box->theme->copy_label("										");
    	main_win->game_box->theme_help->labelfont(font_style);
    	main_win->game_box->theme_help->copy_label("");
    	main_win->game_box->build->labelfont(font_style | FL_BOLD);
    	main_win->game_box->quit->labelfont(font_style);
    	for (int x = 0; x < main_win->game_box->children(); x++) {
            main_win->game_box->child(x)->redraw();
        }
        main_win->game_box->game->copy_label("Game: ");
        main_win->game_box->engine->copy_label("Engine: ");
        main_win->game_box->length->copy_label("Length: ");
        main_win->game_box->theme->copy_label("Theme: ");
    	main_win->game_box->engine_help->copy_label("?");
    	main_win->game_box->length_help->copy_label("?");
    	main_win->game_box->theme_help->copy_label("?");        
    	main_win->build_box->seed_disp->labelfont(font_style);
    	main_win->build_box->name_disp->labelfont(font_style);
    	main_win->build_box->status->labelfont(font_style);
    	main_win->build_box->progress->labelfont(font_style);
    	for (int x = 0; x < main_win->build_box->children(); x++) {
            main_win->build_box->child(x)->redraw();
        }
        for (int x = 0; x < main_win->left_mods->mod_pack->children(); x++) {
        	UI_Module *M = (UI_Module *)main_win->left_mods->mod_pack->child(x);
            SYS_ASSERT(M);
            M->heading->labelfont(font_style | FL_BOLD);
            M->redraw();
			std::map<std::string, UI_RChoice *>::const_iterator IT;
			std::map<std::string, UI_RSlide *>::const_iterator IT2;
			std::map<std::string, UI_RButton *>::const_iterator IT3;
			for (IT = M->choice_map.begin(); IT != M->choice_map.end(); IT++) {
				UI_RChoice *rch = IT->second;
				rch->mod_label->labelfont(font_style);
				rch->mod_menu->textfont(font_style);
				rch->mod_help->labelfont(font_style);
				rch->mod_label->redraw();
			}			
			for (IT2 = M->choice_map_slider.begin(); IT2 != M->choice_map_slider.end(); IT2++) {
				UI_RSlide *rsl = IT2->second;
				rsl->mod_label->labelfont(font_style);
				rsl->mod_entry->labelfont(font_style);
				rsl->mod_help->labelfont(font_style);
				rsl->mod_label->redraw();
			}			
			for (IT3 = M->choice_map_button.begin(); IT3 != M->choice_map_button.end(); IT3++) {
				UI_RButton *rbt = IT3->second;
				rbt->mod_label->labelfont(font_style);
				rbt->mod_help->labelfont(font_style);
				rbt->mod_label->redraw();
			}
        }
        if (main_win->right_mods) {
		    for (int x = 0; x < main_win->right_mods->mod_pack->children(); x++) {
		    	UI_Module *M = (UI_Module *)main_win->right_mods->mod_pack->child(x);
		        SYS_ASSERT(M);
		        M->heading->labelfont(font_style | FL_BOLD);
		        M->redraw();
				std::map<std::string, UI_RChoice *>::const_iterator IT;
				std::map<std::string, UI_RSlide *>::const_iterator IT2;
				std::map<std::string, UI_RButton *>::const_iterator IT3;
				for (IT = M->choice_map.begin(); IT != M->choice_map.end(); IT++) {
					UI_RChoice *rch = IT->second;
					rch->mod_label->labelfont(font_style);
					rch->mod_menu->textfont(font_style);
					rch->mod_help->labelfont(font_style);
					rch->mod_label->redraw();
				}			
				for (IT2 = M->choice_map_slider.begin(); IT2 != M->choice_map_slider.end(); IT2++) {
					UI_RSlide *rsl = IT2->second;
					rsl->mod_label->labelfont(font_style);
					rsl->mod_entry->labelfont(font_style);
					rsl->mod_help->labelfont(font_style);
					rsl->mod_label->redraw();
				}			
				for (IT3 = M->choice_map_button.begin(); IT3 != M->choice_map_button.end(); IT3++) {
					UI_RButton *rbt = IT3->second;
					rbt->mod_label->labelfont(font_style);
					rbt->mod_help->labelfont(font_style);
					rbt->mod_label->redraw();
				}
		    }
		}
    }
    
    static void callback_WidgetTheme(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

        widget_theme = that->opt_widget_theme->value();
    }
    
    static void callback_BoxTheme(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

        box_theme = that->opt_box_theme->value();
    }
    
    static void callback_ButtonTheme(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

        button_theme = that->opt_button_theme->value();
    }
   
    static void callback_SinglePane(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

        single_pane = that->opt_single_pane->value() ? true : false;
    }

    static void callback_ColorScheme(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

        color_scheme = that->opt_color_scheme->value();
    }
    
    static void callback_TextColor(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;     
        if (fl_color_chooser((const char *)"Select Text Color", text_red, text_green, text_blue, 1)) {
    		that->opt_text_color->color(fl_rgb_color(text_red, text_green, text_blue));
    		that->opt_text_color->redraw();
    	}
    }
    
    static void callback_BgColor(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;     
        if (fl_color_chooser((const char *)"Select Panel Color", bg_red, bg_green, bg_blue, 1)) {
    		that->opt_bg_color->color(fl_rgb_color(bg_red, bg_green, bg_blue));
    		that->opt_bg_color->redraw();
    	}
    }
    
    static void callback_Bg2Color(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;       
        if (fl_color_chooser((const char *)"Select Highlight Color", bg2_red, bg2_green, bg2_blue, 1)) {
    		that->opt_bg2_color->color(fl_rgb_color(bg2_red, bg2_green, bg2_blue));
    		that->opt_bg2_color->redraw();
    	}
    }
    
    static void callback_ButtonColor(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;     
        if (fl_color_chooser((const char *)"Select Button Color", button_red, button_green, button_blue, 1)) {
    		that->opt_button_color->color(fl_rgb_color(button_red, button_green, button_blue));
    		that->opt_button_color->redraw();
    	}
    }
    
    static void callback_GradientColor(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;     
        if (fl_color_chooser((const char *)"Select Gradient Color", gradient_red, gradient_green, gradient_blue, 1)) {
    		that->opt_gradient_color->color(fl_rgb_color(gradient_red, gradient_green, gradient_blue));
    		that->opt_gradient_color->redraw();
    	}
    }
    
    static void callback_BorderColor(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;       
        if (fl_color_chooser((const char *)"Select Border Color", border_red, border_green, border_blue, 1)) {
    		that->opt_border_color->color(fl_rgb_color(border_red, border_green, border_blue));
    		that->opt_border_color->redraw();
    	}
    }
    
    static void callback_GapColor(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;       
        if (fl_color_chooser((const char *)"Select Gap Color", gap_red, gap_green, gap_blue, 1)) {
    		that->opt_gap_color->color(fl_rgb_color(gap_red, gap_green, gap_blue));
    		that->opt_gap_color->redraw();
    	}
    }
    
    static void callback_LoadTheme(Fl_Widget *w, void *data) {
        UI_ThemeWin *that = (UI_ThemeWin *)data;

		const char* theme_file = Theme_AskLoadFilename();
		if (theme_file) {
			Theme_Options_Load(theme_file);
            Options_Save(options_file);

            fl_alert("%s", _("Changes to theme require a restart.\nOBSIDIAN will "
                         "now close."));

            main_action = MAIN_QUIT;

            that->want_quit = true;
		}
				
    }

    static void callback_SaveTheme(Fl_Widget *w, void *data) {
        
		const char* new_theme_file = Theme_OutputFilename();
		if (new_theme_file) {
			Theme_Options_Save(new_theme_file);
		}
				
    }

};

//
// Constructor
//
UI_ThemeWin::UI_ThemeWin(int W, int H, const char *label)
    : Fl_Window(W, H, label), want_quit(false) {
    // non-resizable
    size_range(W, H, W, H);

    callback(callback_Quit, this);

    box(FL_FLAT_BOX);

    int y_step = kf_h(9);
    int pad = kf_w(6);

    int cx = x() + kf_w(24);
    int cy = y() + (y_step * 2);

    Fl_Box *heading;

    opt_window_scaling =
        new UI_CustomMenu(136 + KF * 40, cy, kf_w(130), kf_h(24), _("Window Scaling: "));
    opt_window_scaling->align(FL_ALIGN_LEFT);
    opt_window_scaling->add(_("AUTO|Tiny|Small|Medium|Large|Huge"));
    opt_window_scaling->callback(callback_WindowScaling, this);
    opt_window_scaling->value(window_scaling);
    opt_window_scaling->labelfont(font_style);
    opt_window_scaling->textfont(font_style);
    opt_window_scaling->selection_color(SELECTION);

    cy += opt_window_scaling->h() + y_step;
    
    opt_font_scaling =
        new UI_CustomMenu(136 + KF * 40, cy, kf_w(130), kf_h(24), _("Font Scaling: "));
    opt_font_scaling->align(FL_ALIGN_LEFT);
    opt_font_scaling->add(_("Default|Tiny|Small|Large|Huge"));
    opt_font_scaling->callback(callback_FontScaling, this);
    opt_font_scaling->value(font_scaling);
    opt_font_scaling->labelfont(font_style);
    opt_font_scaling->textfont(font_style);
    opt_font_scaling->selection_color(SELECTION);

    cy += opt_font_scaling->h() + y_step;

    opt_font_theme =
        new UI_CustomMenu(136 + KF * 40, cy, kf_w(130), kf_h(24), _("Font: "));
    opt_font_theme->align(FL_ALIGN_LEFT);
    opt_font_theme->callback(callback_FontTheme, this);
    opt_font_theme->value(font_theme);
    opt_font_theme->labelfont(font_style);
    opt_font_theme->textfont(0); // Safe fallback in case bad font is selected
    opt_font_theme->selection_color(SELECTION);
    
    PopulateFonts();

    cy += opt_font_theme->h() + y_step;
    
    opt_widget_theme =
        new UI_CustomMenu(136 + KF * 40, cy, kf_w(130), kf_h(24), _("Widget Theme: "));
    opt_widget_theme->align(FL_ALIGN_LEFT);
    opt_widget_theme->add(_("Default|Gleam|Win95|Plastic"));
    opt_widget_theme->callback(callback_WidgetTheme, this);
    opt_widget_theme->value(widget_theme);
    opt_widget_theme->labelfont(font_style);
    opt_widget_theme->textfont(font_style);
    opt_widget_theme->selection_color(SELECTION);

    cy += opt_widget_theme->h() + y_step;
    
    opt_box_theme =
        new UI_CustomMenu(136 + KF * 40, cy, kf_w(130), kf_h(24), _("Box Theme: "));
    opt_box_theme->align(FL_ALIGN_LEFT);
    opt_box_theme->add(_("Default|Shadow|Embossed|Engraved|Inverted|Flat"));
    opt_box_theme->callback(callback_BoxTheme, this);
    opt_box_theme->value(box_theme);
    opt_box_theme->labelfont(font_style);
    opt_box_theme->textfont(font_style);
    opt_box_theme->selection_color(SELECTION);

    cy += opt_box_theme->h() + y_step;
    
    opt_button_theme =
        new UI_CustomMenu(136 + KF * 40, cy, kf_w(130), kf_h(24), _("Button Theme: "));
    opt_button_theme->align(FL_ALIGN_LEFT);
    opt_button_theme->add(_("Default|Embossed|Engraved|Inverted|Flat"));
    opt_button_theme->callback(callback_ButtonTheme, this);
    opt_button_theme->value(button_theme);
    opt_button_theme->labelfont(font_style);
    opt_button_theme->textfont(font_style);
    opt_button_theme->selection_color(SELECTION);

    cy += opt_button_theme->h() + y_step;

    opt_color_scheme =
        new UI_CustomMenu(136 + KF * 40, cy, kf_w(130), kf_h(24), _("Color Scheme: "));
    opt_color_scheme->align(FL_ALIGN_LEFT);
    opt_color_scheme->add(_("Default|System Colors|Custom"));
    opt_color_scheme->callback(callback_ColorScheme, this);
    opt_color_scheme->value(color_scheme);
    opt_color_scheme->labelfont(font_style);
    opt_color_scheme->textfont(font_style);
	opt_color_scheme->selection_color(SELECTION);

    cy += opt_color_scheme->h() + y_step;
    
    opt_text_color = new Fl_Button(cx + W * .15, cy, W * .15, kf_h(24),
                                       _("Font"));
    opt_text_color->visible_focus(0);
    opt_text_color->box(FL_BORDER_BOX);
    opt_text_color->color(fl_rgb_color(text_red, text_green, text_blue));
    opt_text_color->align(FL_ALIGN_BOTTOM);
    opt_text_color->callback(callback_TextColor, this);
    opt_text_color->labelfont(font_style);

    opt_bg_color = new Fl_Button(cx + W * .15 + opt_text_color->w() +  (3 * pad), cy, W * .15, kf_h(24),
                                       _("Panels"));
    opt_bg_color->visible_focus(0);
    opt_bg_color->box(FL_BORDER_BOX);
    opt_bg_color->color(fl_rgb_color(bg_red, bg_green, bg_blue));
    opt_bg_color->align(FL_ALIGN_BOTTOM);
    opt_bg_color->callback(callback_BgColor, this);
    opt_bg_color->labelfont(font_style);
    
    opt_bg2_color = new Fl_Button(cx + W * .15 + (opt_text_color->w() + (3 * pad)) * 2, cy, W * .15, kf_h(24),
                                       _("Highlights"));
    opt_bg2_color->visible_focus(0);
    opt_bg2_color->box(FL_BORDER_BOX);
    opt_bg2_color->color(fl_rgb_color(bg2_red, bg2_green, bg2_blue));
    opt_bg2_color->align(FL_ALIGN_BOTTOM);
    opt_bg2_color->callback(callback_Bg2Color, this);
    opt_bg2_color->labelfont(font_style);

    cy += opt_text_color->h() + y_step * 3;
    
    opt_button_color = new Fl_Button(cx + W * .05, cy, W * .15, kf_h(24),
                                       _("Buttons"));
    opt_button_color->visible_focus(0);
    opt_button_color->box(FL_BORDER_BOX);
    opt_button_color->color(fl_rgb_color(button_red, button_green, button_blue));
    opt_button_color->align(FL_ALIGN_BOTTOM);
    opt_button_color->callback(callback_ButtonColor, this);
    opt_button_color->labelfont(font_style);

    opt_gradient_color = new Fl_Button(cx + W * .05 + opt_text_color->w() +  (3 * pad), cy, W * .15, kf_h(24),
                                       _("Gradient"));
    opt_gradient_color->visible_focus(0);
    opt_gradient_color->box(FL_BORDER_BOX);
    opt_gradient_color->color(fl_rgb_color(gradient_red, gradient_green, gradient_blue));
    opt_gradient_color->align(FL_ALIGN_BOTTOM);
    opt_gradient_color->callback(callback_GradientColor, this);
    opt_gradient_color->labelfont(font_style);
    
    opt_border_color = new Fl_Button(cx + W * .05 + (opt_text_color->w() + (3 * pad)) * 2, cy, W * .15, kf_h(24),
                                       _("Borders"));
    opt_border_color->visible_focus(0);
    opt_border_color->box(FL_BORDER_BOX);
    opt_border_color->color(fl_rgb_color(border_red, border_green, border_blue));
    opt_border_color->align(FL_ALIGN_BOTTOM);
    opt_border_color->callback(callback_BorderColor, this);
    opt_border_color->labelfont(font_style);
    
    opt_gap_color = new Fl_Button(cx + W * .05 + (opt_text_color->w() + (3 * pad)) * 3, cy, W * .15, kf_h(24),
                                       _("Gaps"));
    opt_gap_color->visible_focus(0);
    opt_gap_color->box(FL_BORDER_BOX);
    opt_gap_color->color(fl_rgb_color(gap_red, gap_green, gap_blue));
    opt_gap_color->align(FL_ALIGN_BOTTOM);
    opt_gap_color->callback(callback_GapColor, this);
    opt_gap_color->labelfont(font_style);

    cy += opt_text_color->h() + y_step * 3;

    opt_single_pane = new UI_CustomCheckBox(cx, cy, W - cx - pad, kf_h(24),
                                       _(" Single Pane Mode"));
    opt_single_pane->value(single_pane ? 1 : 0);
    opt_single_pane->callback(callback_SinglePane, this);
    opt_single_pane->labelfont(font_style);
    opt_single_pane->selection_color(SELECTION);
    opt_single_pane->down_box(button_style);
    
    cy += opt_single_pane->h() + y_step * 3;
    
    load_theme = new Fl_Button(cx + W * .15, cy, W * .25, kf_h(24),
                                       _("Load Theme"));
    load_theme->visible_focus(0);
    load_theme->box(button_style);
    load_theme->color(BUTTON_COLOR);
    load_theme->callback(callback_LoadTheme, this);
    load_theme->labelfont(font_style);
    
    save_theme = new Fl_Button(cx + W * .15 + (load_theme->w() +  pad), cy, W * .25, kf_h(24),
                                       _("Save Theme"));
    save_theme->visible_focus(0);
    save_theme->box(button_style);
    save_theme->color(BUTTON_COLOR);
    save_theme->callback(callback_SaveTheme, this);
    save_theme->labelfont(font_style);

    //----------------

    int dh = kf_h(60);

    int bw = kf_w(60);
    int bh = kf_h(30);
    int bx = W - kf_w(40) - bw;
    int by = H - dh / 2 - bh / 2;

    Fl_Group *darkish = new Fl_Group(0, H - dh, W, dh);
    darkish->box(FL_FLAT_BOX);
    {
        // finally add an "Close" button

        Fl_Button *button = new Fl_Button(bx, by, bw, bh, fl_close);
        button->box(button_style);
        button->callback(callback_Quit, this);
        button->labelfont(font_style);
    }
    darkish->end();

    // restart needed warning
    heading = new Fl_Box(FL_NO_BOX, x() + pad - kf_w(5), H - dh - kf_h(3), W - pad * 2,
                         kf_h(14), _("Note: Some theme options will not be effective until a restart."));
    heading->align(FL_ALIGN_INSIDE);
    heading->labelsize(small_font_size);
    heading->labelfont(font_style);

    end();

    resizable(NULL);
}

int UI_ThemeWin::handle(int event) {
    if (event == FL_KEYDOWN || event == FL_SHORTCUT) {
        int key = Fl::event_key();

        switch (key) {
            case FL_Escape:
                want_quit = true;
                return 1;

            default:
                break;
        }

        // eat all other function keys
        if (FL_F + 1 <= key && key <= FL_F + 12) {
            return 1;
        }
    }

    return Fl_Window::handle(event);
}

void DLG_ThemeEditor(void) {

    int theme_w = kf_w(350);
    int theme_h = kf_h(500);

    UI_ThemeWin *theme_window =
            new UI_ThemeWin(theme_w, theme_h, _("OBSIDIAN Theme Options"));

    theme_window->want_quit = false;
    theme_window->set_modal();
    theme_window->show();

    // run the GUI until the user closes
    while (!theme_window->WantQuit()) {
        Fl::wait();
    }

    // save the options now
    Theme_Options_Save(theme_file);
    
    delete theme_window;
    
}

//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
