//------------------------------------------------------------------------
//  IMAGE manipulations
//------------------------------------------------------------------------
//
//  Oblige Level Maker (C) 2006,2007 Andrew Apted
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
#include "hdr_fltk.h"

#include "g_image.h"

#include "lib_util.h"
#include "ui_window.h"
#include "main.h"


// include the raw image data
const byte raw_image_data[128*128+64*128] =
{
#include "img_data.h"
};

const byte doom_palette[256*3] =
{
    0,  0,  0,  31, 23, 11,  23, 15,  7,  75, 75, 75, 255,255,255,
   27, 27, 27,  19, 19, 19,  11, 11, 11,   7,  7,  7,  47, 55, 31,
   35, 43, 15,  23, 31,  7,  15, 23,  0,  79, 59, 43,  71, 51, 35,
   63, 43, 27, 255,183,183, 247,171,171, 243,163,163, 235,151,151,
  231,143,143, 223,135,135, 219,123,123, 211,115,115, 203,107,107,
  199, 99, 99, 191, 91, 91, 187, 87, 87, 179, 79, 79, 175, 71, 71,
  167, 63, 63, 163, 59, 59, 155, 51, 51, 151, 47, 47, 143, 43, 43,
  139, 35, 35, 131, 31, 31, 127, 27, 27, 119, 23, 23, 115, 19, 19,
  107, 15, 15, 103, 11, 11,  95,  7,  7,  91,  7,  7,  83,  7,  7,
   79,  0,  0,  71,  0,  0,  67,  0,  0, 255,235,223, 255,227,211,
  255,219,199, 255,211,187, 255,207,179, 255,199,167, 255,191,155,
  255,187,147, 255,179,131, 247,171,123, 239,163,115, 231,155,107,
  223,147, 99, 215,139, 91, 207,131, 83, 203,127, 79, 191,123, 75,
  179,115, 71, 171,111, 67, 163,107, 63, 155, 99, 59, 143, 95, 55,
  135, 87, 51, 127, 83, 47, 119, 79, 43, 107, 71, 39,  95, 67, 35,
   83, 63, 31,  75, 55, 27,  63, 47, 23,  51, 43, 19,  43, 35, 15,
  239,239,239, 231,231,231, 223,223,223, 219,219,219, 211,211,211,
  203,203,203, 199,199,199, 191,191,191, 183,183,183, 179,179,179,
  171,171,171, 167,167,167, 159,159,159, 151,151,151, 147,147,147,
  139,139,139, 131,131,131, 127,127,127, 119,119,119, 111,111,111,
  107,107,107,  99, 99, 99,  91, 91, 91,  87, 87, 87,  79, 79, 79,
   71, 71, 71,  67, 67, 67,  59, 59, 59,  55, 55, 55,  47, 47, 47,
   39, 39, 39,  35, 35, 35, 119,255,111, 111,239,103, 103,223, 95,
   95,207, 87,  91,191, 79,  83,175, 71,  75,159, 63,  67,147, 55,
   63,131, 47,  55,115, 43,  47, 99, 35,  39, 83, 27,  31, 67, 23,
   23, 51, 15,  19, 35, 11,  11, 23,  7, 191,167,143, 183,159,135,
  175,151,127, 167,143,119, 159,135,111, 155,127,107, 147,123, 99,
  139,115, 91, 131,107, 87, 123, 99, 79, 119, 95, 75, 111, 87, 67,
  103, 83, 63,  95, 75, 55,  87, 67, 51,  83, 63, 47, 159,131, 99,
  143,119, 83, 131,107, 75, 119, 95, 63, 103, 83, 51,  91, 71, 43,
   79, 59, 35,  67, 51, 27, 123,127, 99, 111,115, 87, 103,107, 79,
   91, 99, 71,  83, 87, 59,  71, 79, 51,  63, 71, 43,  55, 63, 39,
  255,255,115, 235,219, 87, 215,187, 67, 195,155, 47, 175,123, 31,
  155, 91, 19, 135, 67,  7, 115, 43,  0, 255,255,255, 255,219,219,
  255,187,187, 255,155,155, 255,123,123, 255, 95, 95, 255, 63, 63,
  255, 31, 31, 255,  0,  0, 239,  0,  0, 227,  0,  0, 215,  0,  0,
  203,  0,  0, 191,  0,  0, 179,  0,  0, 167,  0,  0, 155,  0,  0,
  139,  0,  0, 127,  0,  0, 115,  0,  0, 103,  0,  0,  91,  0,  0,
   79,  0,  0,  67,  0,  0, 231,231,255, 199,199,255, 171,171,255,
  143,143,255, 115,115,255,  83, 83,255,  55, 55,255,  27, 27,255,
    0,  0,255,   0,  0,227,   0,  0,203,   0,  0,179,   0,  0,155,
    0,  0,131,   0,  0,107,   0,  0, 83, 255,255,255, 255,235,219,
  255,215,187, 255,199,155, 255,179,123, 255,163, 91, 255,143, 59,
  255,127, 27, 243,115, 23, 235,111, 15, 223,103, 15, 215, 95, 11,
  203, 87,  7, 195, 79,  0, 183, 71,  0, 175, 67,  0, 255,255,255,
  255,255,215, 255,255,179, 255,255,143, 255,255,107, 255,255, 71,
  255,255, 35, 255,255,  0, 167, 63,  0, 159, 55,  0, 147, 47,  0,
  135, 35,  0,  79, 59, 39,  67, 47, 27,  55, 35, 19,  47, 27, 11,
    0,  0, 83,   0,  0, 71,   0,  0, 59,   0,  0, 47,   0,  0, 35,
    0,  0, 23,   0,  0, 11,   0, 47, 47, 255,159, 67, 255,231, 75,
  255,123,255, 255,  0,255, 207,  0,207, 159,  0,155, 111,  0,107,
    0,255,255
};

const byte heretic_palette[256*3] =
{
    0,  0,  0,   2,  2,  2,  16, 16, 16,  24, 24, 24,  31, 31, 31,
   36, 36, 36,  44, 44, 44,  48, 48, 48,  55, 55, 55,  63, 63, 63,
   70, 70, 70,  78, 78, 78,  86, 86, 86,  93, 93, 93, 101,101,101,
  108,108,108, 116,116,116, 124,124,124, 131,131,131, 139,139,139,
  146,146,146, 154,154,154, 162,162,162, 169,169,169, 177,177,177,
  184,184,184, 192,192,192, 200,200,200, 207,207,207, 210,210,210,
  215,215,215, 222,222,222, 228,228,228, 236,236,236, 245,245,245,
  255,255,255,  50, 50, 50,  59, 60, 59,  69, 72, 68,  78, 80, 77,
   88, 93, 86,  97,100, 95, 109,112,104, 116,123,112, 125,131,121,
  134,141,130, 144,151,139, 153,161,148, 163,171,157, 172,181,166,
  181,189,176, 189,196,185,  20, 16, 36,  24, 24, 44,  36, 36, 60,
   52, 52, 80,  68, 68, 96,  88, 88,116, 108,108,136, 124,124,152,
  148,148,172, 164,164,184, 180,184,200, 192,196,208, 208,208,216,
  224,224,224,  27, 15,  8,  38, 20, 11,  49, 27, 14,  61, 31, 14,
   65, 35, 18,  74, 37, 19,  83, 43, 19,  87, 47, 23,  95, 51, 27,
  103, 59, 31, 115, 67, 35, 123, 75, 39, 131, 83, 47, 143, 91, 51,
  151, 99, 59, 160,108, 64, 175,116, 74, 180,126, 81, 192,135, 91,
  204,143, 93, 213,151,103, 216,159,115, 220,167,126, 223,175,138,
  227,183,149, 230,190,161, 233,198,172, 237,206,184, 240,214,195,
   62, 40, 11,  75, 50, 16,  84, 59, 23,  95, 67, 30, 103, 75, 38,
  110, 83, 47, 123, 95, 55, 137,107, 62, 150,118, 75, 163,129, 84,
  171,137, 92, 180,146,101, 188,154,109, 196,162,117, 204,170,125,
  208,176,133,  37, 20,  4,  47, 24,  4,  57, 28,  6,  68, 33,  4,
   76, 36,  3,  84, 40,  0,  97, 47,  2, 114, 54,  0, 125, 63,  6,
  141, 75,  9, 155, 83, 17, 162, 95, 21, 169,103, 26, 180,113, 32,
  188,124, 20, 204,136, 24, 220,148, 28, 236,160, 23, 244,172, 47,
  252,187, 57, 252,194, 70, 251,201, 83, 251,208, 97, 251,214,110,
  251,221,123, 250,228,136, 157, 51,  4, 170, 65,  2, 185, 86,  4,
  213,118,  4, 236,164,  3, 248,190,  3, 255,216, 43, 255,255,  0,
   67,  0,  0,  79,  0,  0,  91,  0,  0, 103,  0,  0, 115,  0,  0,
  127,  0,  0, 139,  0,  0, 155,  0,  0, 167,  0,  0, 179,  0,  0,
  191,  0,  0, 203,  0,  0, 215,  0,  0, 227,  0,  0, 239,  0,  0,
  255,  0,  0, 255, 52, 52, 255, 74, 74, 255, 95, 95, 255,123,123,
  255,155,155, 255,179,179, 255,201,201, 255,215,215,  60, 12, 88,
   80,  8,108, 104,  8,128, 128,  0,144, 152,  0,176, 184,  0,224,
  216, 44,252, 224,120,240,  37,  6,129,  60, 33,147,  82, 61,165,
  105, 88,183, 128,116,201, 151,143,219, 173,171,237, 196,198,255,
    2,  4, 41,   2,  5, 49,   6,  8, 57,   2,  5, 65,   2,  5, 79,
    0,  4, 88,   0,  4, 96,   0,  4,104,   2,  5,121,   2,  5,137,
    6,  9,159,  12, 16,184,  32, 40,200,  56, 60,220,  80, 80,253,
   80,108,252,  80,136,252,  80,164,252,  80,196,252,  72,220,252,
   80,236,252,  84,252,252, 152,252,252, 188,252,244,  11, 23,  7,
   19, 35, 11,  23, 51, 15,  31, 67, 23,  39, 83, 27,  47, 99, 35,
   55,115, 43,  63,131, 47,  67,147, 55,  75,159, 63,  83,175, 71,
   91,191, 79,  95,207, 87, 103,223, 95, 111,239,103, 119,255,111,
   23, 31, 23,  27, 35, 27,  31, 43, 31,  35, 51, 35,  43, 55, 43,
   47, 63, 47,  51, 71, 51,  59, 75, 55,  63, 83, 59,  67, 91, 67,
   75, 95, 71,  79,103, 75,  87,111, 79,  91,115, 83,  95,123, 87,
  103,131, 95, 255,223,  0, 255,191,  0, 255,159,  0, 255,127,  0,
  255, 95,  0, 255, 63,  0, 244, 14,  3,  55,  0,  0,  47,  0,  0,
   39,  0,  0,  23,  0,  0,  15, 15, 15,  11, 11, 11,   7,  7,  7,
  255,255,255
};

const byte hexen_palette[256*3] =
{
    2,  2,  2,   4,  4,  4,  15, 15, 15,  19, 19, 19,  27, 27, 27,
   28, 28, 28,  33, 33, 33,  39, 39, 39,  45, 45, 45,  51, 51, 51,
   57, 57, 57,  63, 63, 63,  69, 69, 69,  75, 75, 75,  81, 81, 81,
   86, 86, 86,  92, 92, 92,  98, 98, 98, 104,104,104, 112,112,112,
  121,121,121, 130,130,130, 139,139,139, 147,147,147, 157,157,157,
  166,166,166, 176,176,176, 185,185,185, 194,194,194, 203,203,203,
  212,212,212, 221,221,221, 230,230,230,  29, 32, 29,  38, 40, 37,
   50, 50, 50,  59, 60, 59,  69, 72, 68,  78, 80, 77,  88, 93, 86,
   97,100, 95, 109,112,104, 116,123,112, 125,131,121, 134,141,130,
  144,151,139, 153,161,148, 163,171,157, 172,181,166, 181,189,176,
  189,196,185,  22, 29, 22,  27, 36, 27,  31, 43, 31,  35, 51, 35,
   43, 55, 43,  47, 63, 47,  51, 71, 51,  59, 75, 55,  63, 83, 59,
   67, 91, 67,  75, 95, 71,  79,103, 75,  87,111, 79,  91,115, 83,
   95,123, 87, 103,131, 95,  20, 16, 36,  30, 26, 46,  40, 36, 57,
   50, 46, 67,  59, 57, 78,  69, 67, 88,  79, 77, 99,  89, 87,109,
   99, 97,120, 109,107,130, 118,118,141, 128,128,151, 138,138,162,
  148,148,172,  62, 40, 11,  75, 50, 16,  84, 59, 23,  95, 67, 30,
  103, 75, 38, 110, 83, 47, 123, 95, 55, 137,107, 62, 150,118, 75,
  163,129, 84, 171,137, 92, 180,146,101, 188,154,109, 196,162,117,
  204,170,125, 208,176,133,  27, 15,  8,  38, 20, 11,  49, 27, 14,
   61, 31, 14,  65, 35, 18,  74, 37, 19,  83, 43, 19,  87, 47, 23,
   95, 51, 27, 103, 59, 31, 115, 67, 35, 123, 75, 39, 131, 83, 47,
  143, 91, 51, 151, 99, 59, 160,108, 64, 175,116, 74, 180,126, 81,
  192,135, 91, 204,143, 93, 213,151,103, 216,159,115, 220,167,126,
  223,175,138, 227,183,149,  37, 20,  4,  47, 24,  4,  57, 28,  6,
   68, 33,  4,  76, 36,  3,  84, 40,  0,  97, 47,  2, 114, 54,  0,
  125, 63,  6, 141, 75,  9, 155, 83, 17, 162, 95, 21, 169,103, 26,
  180,113, 32, 188,124, 20, 204,136, 24, 220,148, 28, 236,160, 23,
  244,172, 47, 252,187, 57, 252,194, 70, 251,201, 83, 251,208, 97,
  251,221,123,   2,  4, 41,   2,  5, 49,   6,  8, 57,   2,  5, 65,
    2,  5, 79,   0,  4, 88,   0,  4, 96,   0,  4,104,   4,  6,121,
    2,  5,137,  20, 23,152,  38, 41,167,  56, 59,181,  74, 77,196,
   91, 94,211, 109,112,226, 127,130,240, 145,148,255,  31,  4,  4,
   39,  0,  0,  47,  0,  0,  55,  0,  0,  67,  0,  0,  79,  0,  0,
   91,  0,  0, 103,  0,  0, 115,  0,  0, 127,  0,  0, 139,  0,  0,
  155,  0,  0, 167,  0,  0, 185,  0,  0, 202,  0,  0, 220,  0,  0,
  237,  0,  0, 255,  0,  0, 255, 46, 46, 255, 91, 91, 255,137,137,
  255,171,171,  20, 16,  4,  13, 24,  9,  17, 33, 12,  21, 41, 14,
   24, 50, 17,  28, 57, 20,  32, 65, 24,  35, 73, 28,  39, 80, 31,
   44, 86, 37,  46, 95, 38,  51,104, 43,  60,122, 51,  68,139, 58,
   77,157, 66,  85,174, 73,  94,192, 81, 157, 51,  4, 170, 65,  2,
  185, 86,  4, 213,119,  6, 234,147,  5, 255,178,  6, 255,195, 26,
  255,216, 45,   4,133,  4,   8,175,  8,   2,215,  2,   3,234,  3,
   42,252, 42, 121,255,121,   3,  3,184,  15, 41,220,  28, 80,226,
   41,119,233,  54,158,239,  67,197,246,  80,236,252, 244, 14,  3,
  255, 63,  0, 255, 95,  0, 255,127,  0, 255,159,  0, 255,195, 26,
  255,223,  0,  43, 13, 64,  61, 14, 89,  90, 15,122, 120, 16,156,
  149, 16,189, 178, 17,222, 197, 74,232, 215,129,243, 234,169,253,
   61, 16, 16,  90, 36, 33, 118, 56, 49, 147, 77, 66, 176, 97, 83,
  204,117, 99,  71, 53,  2,  81, 63,  6,  96, 72,  0, 108, 80,  0,
  120, 88,  0, 128, 96,  0, 149,112,  1, 181,136,  3, 212,160,  4,
  255,255,255,
};


//------------------------------------------------------------------------

static byte pixel_to_doom[256];
static byte pixel_to_heretic[256];
static byte pixel_to_hexen[256];

static int FindColor(const byte *palette, const byte *col)
{
  int r = col[0];
  int g = col[1];
  int b = col[2];

  int best_idx  = -1;
  int best_dist = (1<<30);
  
  for (int j = 0; j < 256; j++)
  {
    int dr = palette[j*3 + 0] - r;
    int dg = palette[j*3 + 1] - g;
    int db = palette[j*3 + 2] - b;

    int dist = dr*dr + dg*dg + db*db;

    if (dist == 0) // exact match!
      return j;

    if (dist < best_dist)
    {
      best_idx  = j;
      best_dist = dist;
    }
  }

  SYS_ASSERT(best_idx >= 0);

  return best_idx;
}

static void CreateMappingTables(void)
{
  for (int i = 0; i < 256; i++)
  {
    pixel_to_doom   [i] = i; // already in DOOM palette
    pixel_to_heretic[i] = FindColor(heretic_palette, doom_palette + i*3);
    pixel_to_hexen  [i] = FindColor(  hexen_palette, doom_palette + i*3);
  }
}

void Image_Setup(void)
{
  CreateMappingTables();
}

static void FillPost(byte *pat, int x, int w, int pos, const byte *mapper)
{
  // determine and set the offset value
  int offset = 8 + 128*4 + (x % w) * (128+8);

  byte *ofs_var = pat + 8 + x*4;

  ofs_var[0] = offset & 0xFF;
  ofs_var[1] = (offset >>  8) & 0xFF;
  ofs_var[2] = (offset >> 16) & 0xFF;

  if (x >= w)
    return;

  // actually fill in the post

  const byte *src = raw_image_data + pos + (x % w);

  byte *dest = pat + offset;

  *dest++ = 0;   // Y OFFSET
  *dest++ = 128; // HEIGHT

  for (int y=-1; y < 128+1; y++)
  {
    // handling padding (top and bottom)
    int yy = MAX(0, MIN(127, y));

    *dest++ = mapper[src[(127-yy)*w]];
  }

  *dest++ = 255; // END OF POST
}

const byte *Image_MakePatch(int what, int *length)
{
  SYS_ASSERT(0 <= what && what <= 1);

  int w   = what ? 64 : 128;
  int pos = what ? 128*128 : 0;

  *length = 8 + 128*4 + w * (128+8);

  byte *pat = new byte[*length];

  memset(pat, 0, *length);

  // header
  pat[0] = 128;  // width
  pat[2] = 128;  // height

  // palette conversion
  const byte *mapper = pixel_to_doom;

  if (strcmp(main_win->setup_box->get_Game(), "heretic") == 0)
    mapper = pixel_to_heretic;

  if (strcmp(main_win->setup_box->get_Game(), "hexen") == 0)
    mapper = pixel_to_hexen;

  // posts
  for (int x=0; x < 128; x++)
  {
    FillPost(pat, x, w, pos, mapper);
  }

  return pat;
}

void Image_FreePatch(const byte *pat)
{
  delete[] pat;
}
