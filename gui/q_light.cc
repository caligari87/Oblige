//------------------------------------------------------------------------
//  QUAKE 1/2 LIGHTING
//------------------------------------------------------------------------
//
//  Oblige Level Maker
//
//  Copyright (C) 2006-2010 Andrew Apted
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
#include "hdr_lua.h"
#include "hdr_ui.h"

#include "lib_file.h"
#include "lib_util.h"
#include "main.h"

#include "csg_main.h"

#include "q_bsp.h"
#include "q_light.h"
#include "q1_main.h"
#include "q1_structs.h"


class qLightmap_c
{
private:
  int width, height;

  float *samples;

public:
  qLightmap_c(int w, int h);

  ~qLightmap_c();

  void Clear();
};


qLightmap_c::qLightmap_c(int w, int h) : width(w), height(h)
{
  samples = new float[width * height];

  Clear();
}

qLightmap_c::~qLightmap_c()
{
    delete[] samples;
}

void qLightmap_c::Clear()
{
  for (int i = 0; i < w*h; i++)
    samples[i] = 0.0f;
}


static qLump_c *q1_lightmap;


void Quake1_BeginLightmap(void)
{
  q1_lightmap = BSP_NewLump(LUMP_LIGHTING);



}


s32_t Quake1_LightAddBlock(int w, int h, u8_t level)
{
  s32_t offset = q1_lightmap->GetSize();

  for (int i = 0; i < w*h; i++)
    q1_lightmap->Append(&level, 1);

  return offset;
}

//--- editor settings ---
// vi:ts=2:sw=2:expandtab
