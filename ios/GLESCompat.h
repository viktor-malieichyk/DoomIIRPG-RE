#pragma once
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#include "Platform.h"
#ifndef APIENTRYP
#define APIENTRYP *
#endif
#define glOrtho glOrthof
#define glViewport IOS_GLViewport
#define glScissor IOS_GLScissor
static inline void RPG_GetRenderSize(SDL_Window* window,int* w,int* h) { *w=480; *h=320; }

typedef void (APIENTRYP PFNGLACTIVETEXTUREPROC)(GLenum texture);
#define GL_SOURCE0_RGB GL_SRC0_RGB
#define GL_SOURCE1_RGB GL_SRC1_RGB
#define GL_SOURCE0_ALPHA GL_SRC0_ALPHA
#define GL_SOURCE1_ALPHA GL_SRC1_ALPHA
