#include <SDL.h>
#include <OpenGLES/ES1/gl.h>
#include "Platform.h"
static void viewport(int* x,int* y,int* w,int* h) {
 int width,height; SDL_GL_GetDrawableSize(SDL_GL_GetCurrentWindow(),&width,&height);
 float scale=SDL_min(width/480.f,height/320.f);
 *x=(int)((width-480*scale)/2+*x*scale); *y=(int)((height-320*scale)/2+*y*scale);
 *w=(int)(*w*scale); *h=(int)(*h*scale);
}
void IOS_GLViewport(int x,int y,int w,int h) { viewport(&x,&y,&w,&h); glViewport(x,y,w,h); }
void IOS_GLScissor(int x,int y,int w,int h) { viewport(&x,&y,&w,&h); glScissor(x,y,w,h); }
