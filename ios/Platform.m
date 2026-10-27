#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <unistd.h>
#include <SDL.h>
#include <SDL_syswm.h>
#include "Platform.h"
#import "SaveArchive.h"
#include "ImportData.h"
#import "GameInfo.h"
static BOOL ready, paused, importingSaves, exporting;
static SDL_Window* gameWindow;
static UIViewController* host;
static NSString* folder;
static NSString* saveFolder;
@interface Mobile : NSObject <UIDocumentPickerDelegate>
-(void)menu;
@end
static Mobile* mobile;
static BOOL showTouchButtons=YES;
static void updateButtons(void) {
 for(UIView* view in host.view.subviews) if([view isKindOfClass:UIButton.class] && view.tag && view.tag!=SDL_SCANCODE_ESCAPE)view.hidden=!showTouchButtons;
}
static void notice(NSString* message) {
 UIAlertController* a=[UIAlertController alertControllerWithTitle:GAME_TITLE message:message preferredStyle:UIAlertControllerStyleAlert];
 [a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
  paused=NO;
  if(!ready) dispatch_async(dispatch_get_main_queue(), ^{ [mobile menu]; });
 }]];
 [host presentViewController:a animated:YES completion:nil];
}
static BOOL assetsReady(void) {
 NSFileManager* fm=NSFileManager.defaultManager;
 return [fm fileExistsAtPath:[folder stringByAppendingPathComponent:GAME_ARCHIVE]];
}
@implementation Mobile
-(void)key:(UIButton*)button down:(BOOL)down {
 SDL_Event event; SDL_zero(event); event.type=down ? SDL_KEYDOWN : SDL_KEYUP;
 event.key.state=down ? SDL_PRESSED : SDL_RELEASED; event.key.keysym.scancode=(SDL_Scancode)button.tag;
 SDL_PushEvent(&event);
}
-(void)down:(UIButton*)button { [self key:button down:YES]; }
-(void)up:(UIButton*)button { [self key:button down:NO]; }
-(void)start {
 if(!assetsReady()) { notice(@"Import the original game IPA first. Choose it from iCloud Drive or On My iPhone in Files."); return; }
 ready=YES; [host dismissViewControllerAnimated:YES completion:nil];
}
-(void)pick:(BOOL)saves {
 importingSaves=saves; exporting=NO;
 UIDocumentPickerViewController* picker=[[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeData] asCopy:YES];
 picker.allowsMultipleSelection=NO; picker.delegate=self;
 [host presentViewController:picker animated:YES completion:nil];
}
-(void)exportSaves {
 NSError* error=nil;
 NSData* data=DRPGExportSave(saveFolder,&error);
 if(!data) { notice(@"No complete saved game yet. Save using the in-game menu, then export again."); return; }
 NSURL* url=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"DoomIIRPG-save.rpgsave"]];
 if(!data || ![data writeToURL:url options:NSDataWritingAtomic error:&error]) { notice(error.localizedDescription); return; }
 exporting=YES;
 UIDocumentPickerViewController* picker=[[UIDocumentPickerViewController alloc] initForExportingURLs:@[url] asCopy:YES]; picker.delegate=self;
 [host presentViewController:picker animated:YES completion:nil];
}
-(void)menu {
 paused=YES;
 UIAlertController* a=[UIAlertController alertControllerWithTitle:@"Files & iCloud Drive" message:ready ? @"Export includes the latest in-game save. To restore a backup or replace game data, reopen the app and use the startup screen." : @"Import your own original game IPA from Files or iCloud Drive. Saves stay on this device until you export them." preferredStyle:UIAlertControllerStyleAlert];
 if(!ready) {
  [a addAction:[UIAlertAction actionWithTitle:@"Play" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){[mobile start];}]];
  [a addAction:[UIAlertAction actionWithTitle:@"Import game data from Files / iCloud" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){[mobile pick:NO];}]];
  [a addAction:[UIAlertAction actionWithTitle:@"Import save backup" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){[mobile pick:YES];}]];
 }
 [a addAction:[UIAlertAction actionWithTitle:showTouchButtons ? @"Hide touch buttons" : @"Show touch buttons" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
  showTouchButtons=!showTouchButtons;
  [NSUserDefaults.standardUserDefaults setBool:showTouchButtons forKey:@"showTouchButtons"];
  updateButtons(); paused=NO;
  if(!ready)dispatch_async(dispatch_get_main_queue(), ^{ [mobile menu]; });
 }]];
 [a addAction:[UIAlertAction actionWithTitle:@"Export save to Files / iCloud" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){[mobile exportSaves];}]];
 if(ready)[a addAction:[UIAlertAction actionWithTitle:@"Resume" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action){paused=NO;}]];
 [host presentViewController:a animated:YES completion:nil];
}
-(void)documentPickerWasCancelled:(UIDocumentPickerViewController*)controller { if(ready)paused=NO; else dispatch_async(dispatch_get_main_queue(), ^{ [mobile menu]; }); }
-(void)documentPicker:(UIDocumentPickerViewController*)controller didPickDocumentsAtURLs:(NSArray<NSURL*>*)urls {
 if(exporting) { paused=NO; return; }
 NSError* error=nil;
 if(importingSaves) {
  NSURL* url=urls.firstObject; BOOL scoped=[url startAccessingSecurityScopedResource];
  NSNumber* size=nil; [url getResourceValue:&size forKey:NSURLFileSizeKey error:&error];
  NSData* data=size.unsignedLongLongValue<=8*1024*1024 ? [NSData dataWithContentsOfURL:url options:0 error:&error] : nil;
  if(scoped)[url stopAccessingSecurityScopedResource];
  NSDictionary* files=DRPGReadSave(data,&error);
  if(!files) { notice(error.localizedDescription ?: @"This is not a valid game save backup."); return; }
  UIAlertController* a=[UIAlertController alertControllerWithTitle:@"Replace local saves?" message:@"A copy of the existing save files will be kept in Previous Saves in the app’s Files folder." preferredStyle:UIAlertControllerStyleAlert];
  [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [a addAction:[UIAlertAction actionWithTitle:@"Import" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action){
   NSError* e=nil;
   DRPGRestoreSave(files,saveFolder,&e);
   chdir(folder.fileSystemRepresentation);
   notice(e ? e.localizedDescription : @"Save imported. Tap Files, then Play, and choose Continue in the game.");
  }]]; [host presentViewController:a animated:YES completion:nil];
 } else {
   NSURL* url=urls.firstObject;
   BOOL scoped=[url startAccessingSecurityScopedResource];
   NSNumber* size=nil; [url getResourceValue:&size forKey:NSURLFileSizeKey error:&error];
   NSData* data=size && size.unsignedLongLongValue<=256*1024*1024 ? [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error] : nil;
   BOOL valid=IOS_ValidateZip(data.bytes,data.length);
   BOOL copied=valid && [data writeToFile:[folder stringByAppendingPathComponent:GAME_ARCHIVE] options:NSDataWritingAtomic error:&error];
   if(scoped)[url stopAccessingSecurityScopedResource];
   notice(copied ? @"Game data imported. Choose Play to start." : @"This file is incomplete or does not contain the correct game resources. Select the original game IPA in Files.");
 }
}
@end
static void button(UIView* view,NSString* title,int key,CGFloat x,CGFloat y,BOOL right,BOOL bottom) {
 UIButton* b=[UIButton buttonWithType:UIButtonTypeSystem]; b.translatesAutoresizingMaskIntoConstraints=NO;
 [b setTitle:title forState:UIControlStateNormal]; b.tintColor=UIColor.whiteColor;
 b.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
 b.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:.45]; b.layer.cornerRadius=10; b.tag=key;
 [view addSubview:b]; UILayoutGuide* g=view.safeAreaLayoutGuide;
 [NSLayoutConstraint activateConstraints:@[[b.widthAnchor constraintEqualToConstant:64],[b.heightAnchor constraintEqualToConstant:44],right ? [b.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-x] : [b.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:x],bottom ? [b.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-y] : [b.topAnchor constraintEqualToAnchor:g.topAnchor constant:y]]];
 if(key) { [b addTarget:mobile action:@selector(down:) forControlEvents:UIControlEventTouchDown]; [b addTarget:mobile action:@selector(up:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel]; }
 else [b addTarget:mobile action:@selector(menu) forControlEvents:UIControlEventTouchUpInside];
}
void IOS_SetupStorage(void) {
 NSString* docs=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES).firstObject;
 folder=[docs stringByAppendingPathComponent:@"Game"];
 [NSFileManager.defaultManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
 saveFolder=[folder stringByAppendingPathComponent:GAME_SAVE_DIR];
 [NSFileManager.defaultManager createDirectoryAtPath:saveFolder withIntermediateDirectories:YES attributes:nil error:nil];
 chdir(folder.fileSystemRepresentation);
}
void IOS_Prepare(SDL_Window* window) {
 gameWindow=window;
 SDL_SysWMinfo info; SDL_VERSION(&info.version); SDL_GetWindowWMInfo(window,&info);
 host=info.info.uikit.window.rootViewController; mobile=[Mobile new];
 if([NSUserDefaults.standardUserDefaults objectForKey:@"showTouchButtons"])showTouchButtons=[NSUserDefaults.standardUserDefaults boolForKey:@"showTouchButtons"];
 button(host.view,@"Files",0,8,4,YES,NO);
 button(host.view,@"Menu",SDL_SCANCODE_ESCAPE,8,4,NO,NO);
 button(host.view,@"↑",SDL_SCANCODE_UP,68,100,NO,YES);
 button(host.view,@"↓",SDL_SCANCODE_DOWN,68,4,NO,YES);
 button(host.view,@"←",SDL_SCANCODE_LEFT,8,52,NO,YES);
 button(host.view,@"→",SDL_SCANCODE_RIGHT,128,52,NO,YES);
 button(host.view,@"Use",SDL_SCANCODE_RETURN,8,52,YES,YES);
 button(host.view,@"Map",SDL_SCANCODE_TAB,8,100,YES,YES);
 button(host.view,@"Weapon",SDL_SCANCODE_Z,76,52,YES,YES);
 button(host.view,@"Wait",SDL_SCANCODE_C,8,4,YES,YES);
 button(host.view,@"Strafe L",SDL_SCANCODE_A,8,152,NO,YES);
 button(host.view,@"Strafe R",SDL_SCANCODE_D,128,152,NO,YES);
 button(host.view,@"Items",SDL_SCANCODE_I,76,100,YES,YES);
 button(host.view,@"PDA",SDL_SCANCODE_P,144,100,YES,YES);
 button(host.view,@"Drinks",SDL_SCANCODE_O,76,4,YES,YES);
 button(host.view,@"Bot",SDL_SCANCODE_B,144,4,YES,YES);
 SDL_SetHint(SDL_HINT_TOUCH_MOUSE_EVENTS,"0");
 updateButtons();
 [mobile menu];
 while(!ready) { SDL_PumpEvents(); SDL_Delay(16); }
 paused=NO;
}
int IOS_Paused(void) { return paused || host.presentedViewController!=nil || UIApplication.sharedApplication.applicationState!=UIApplicationStateActive; }

int IOS_MapTouch(float* x,float* y) {
 int w,h; SDL_GetWindowSize(gameWindow,&w,&h);
 float scale=fminf(w/480.f,h/320.f);
 *x=(*x*w-(w-480*scale)/2)/(480*scale);
 *y=(*y*h-(h-320*scale)/2)/(320*scale);
 return *x>=0 && *x<=1 && *y>=0 && *y<=1;
}
