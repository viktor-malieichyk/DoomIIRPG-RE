#ifdef DOOMRPG_IOS
#include "Platform.h"
#endif
#include <stdexcept>
#include <stdio.h>
#include <stdlib.h>

#include <SDL.h>
#include "SDLGL.h"
#include "ZipFile.h"

#include "CAppContainer.h"
#include "App.h"
#include "Image.h"
#include "Resource.h"
#include "Render.h"
#include "GLES.h"

#include "Canvas.h"
#include "Graphics.h"
#include "Player.h"
#include "Game.h"
#include "Graphics.h"
#include "Utils.h"
#include "TinyGL.h"
#include "Input.h"

void drawView(SDLGL* sdlGL);

#ifdef DOOMRPG_IOS
struct IOSGameLoop {
 SDLGL video;
 ZipFile archive;
 Input input;
};
static void iosFrame(void* context) {
 IOSGameLoop* loop=(IOSGameLoop*)context;
 if(IOS_Paused() || CAppContainer::getInstance()->app->closeApplet)return;
 loop->input.handleEvents();
 drawView(&loop->video);
 loop->input.consumeEvents();
}
extern "C" int SDL_main(int argc,char** argv) {
 IOS_SetupStorage();
 IOSGameLoop* loop=new IOSGameLoop;
 loop->video.Initialize();
 IOS_Prepare(loop->video.window);
 loop->archive.openZipFile("Doom 2 RPG.ipa");
 loop->input.init();
 CAppContainer::getInstance()->Construct(&loop->video,&loop->archive);
 loop->video.updateVideo();
 SDL_iPhoneSetAnimationCallback(loop->video.window,1,iosFrame,loop);
 return 0;
}
#else
int main(int argc, char* args[]) {
    int		UpTime = 0;
    
    ZipFile zipFile;
    zipFile.openZipFile("Doom 2 RPG.ipa");

#ifndef DOOMRPG_IOS
	SDLGL sdlGL;
	sdlGL.Initialize();
#endif

    Input input;
    input.init(); // [GEC] Port: set default Binds

    CAppContainer::getInstance()->Construct(&sdlGL, &zipFile);
    sdlGL.updateVideo(); // [GEC]

    SDL_Event ev;
    

    float x = 0.0f, y = 30.0f;
    int   vp_cx = 480;
    int   vp_cy = 320;


    Uint8 state;
    int mX, mY;           /* mouse location*/
    float mousePressX = 0.f, mousePressY = 0.f;           /* mouse location float*/
    int winVidWidth = sdlGL.winVidWidth;
    int winVidHeight = sdlGL.winVidHeight;
    bool useMouse = false;
   
    

    while (CAppContainer::getInstance()->app->closeApplet != true) {

        #ifdef DOOMRPG_IOS
        if (IOS_Paused()) { SDL_PumpEvents(); SDL_Delay(16); continue; }
#endif
        int currentTimeMillis = CAppContainer::getInstance()->getTimeMS();

        //if (!useMouse) {
            //float ax = SDL_GameControllerGetAxis(sdlGL.accelerometer, SDL_CONTROLLER_AXIS_LEFTX);
            //float ay = SDL_GameControllerGetAxis(sdlGL.accelerometer, SDL_CONTROLLER_AXIS_LEFTY);
            //CAppContainer::getInstance()->UpdateAccelerometer((ax* (1.0f / 32767))/2, (ay* (1.0f / 32767))/2, 0.f, false);
        //}

        if (currentTimeMillis > UpTime) {
            input.handleEvents();
            UpTime = currentTimeMillis + 15;
            drawView(&sdlGL);
            input.consumeEvents();
        }
    }

    printf("APP_QUIT\n");
    CAppContainer::getInstance()->~CAppContainer();
    zipFile.closeZipFile();
    sdlGL.~SDLGL();
    input.~Input();
	return 0;
}


#endif

static uint32_t lastTimems = 0;

void drawView(SDLGL *sdlGL) {

    int cx, cy;
    int w = sdlGL->vidWidth;
    int h = sdlGL->vidHeight;

    if (lastTimems == 0) {
        lastTimems = CAppContainer::getInstance()->getTimeMS();
    }

    RPG_GetRenderSize(sdlGL->window, &cx, &cy);
    if (w != cx || h != cy) {
        w = cx; h = cy;
    }

    glViewport(0, 0, (GLsizei)w, (GLsizei)h);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_ALPHA_TEST);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0, Applet::IOS_WIDTH, Applet::IOS_HEIGHT, 0.0, -1.0, 1.0);
    //glRotatef(90.0, 0.0, 0.0, 1.0);
    //glTranslatef(0.0, -320.0, 0.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    

    uint32_t startTime = CAppContainer::getInstance()->getTimeMS();
    uint32_t passedTime = startTime - lastTimems;
    lastTimems = startTime;

    if (passedTime >= 125) {
        passedTime = 125;
    }
    //printf("passedTime %d\n", passedTime);

    CAppContainer::getInstance()->DoLoop(passedTime);

    SDL_GL_SwapWindow(sdlGL->window);  // Swap the window/pBmp to display the result.
    
}