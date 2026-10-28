#pragma once
#include <SDL.h>
#ifdef __cplusplus
extern "C" {
#endif
void IOS_SetupStorage(void);
void IOS_Prepare(SDL_Window* window);
int IOS_Paused(void);
int IOS_MapTouch(float* x,float* y);
void IOS_GLViewport(int x,int y,int w,int h);
void IOS_GLScissor(int x,int y,int w,int h);
void IOS_SetActive(int active);
void IOS_ResetTouch(void);
void IOS_RefreshLayout(void);
#ifdef __cplusplus
}
#endif
