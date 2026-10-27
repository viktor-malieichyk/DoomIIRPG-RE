#import "SaveArchive.h"
#import "GameInfo.h"
#include <assert.h>
int main(int argc,char** argv) { @autoreleasepool {
 if(argc==2) {
  NSString* folder=[NSString stringWithUTF8String:argv[1]];
  NSError* error=nil; NSData* archive=DRPGExportSave(folder,&error);
  assert(archive && !error && DRPGReadSave(archive,&error));
  puts("PASS: actual simulator save files export and validate"); return 0;
 }
 NSFileManager* fm=NSFileManager.defaultManager;
 NSString* parent=[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
 NSString* folder=[parent stringByAppendingPathComponent:@"Saves"];
 [fm createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
 unsigned char raw[]={GAME_CONFIG_VERSION,0,0,0,1,2,3,4};
 NSData* config=[NSData dataWithBytes:raw length:sizeof(raw)];
 [config writeToFile:[folder stringByAppendingPathComponent:@"CONFIGFILENAME"] atomically:YES];
 [config writeToFile:[folder stringByAppendingPathComponent:@"BRIEFPLAYER"] atomically:YES];
 [config writeToFile:[folder stringByAppendingPathComponent:@"FWORLD"] atomically:YES];
 NSError* error=nil; NSData* data=DRPGExportSave(folder,&error); assert(data && !error);
 NSDictionary* files=DRPGReadSave(data,&error); assert(files.count==3);
 NSMutableDictionary* badRoot=[[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:nil error:nil] mutableCopy];
 badRoot[@"game"]=@"another.game";
 NSData* bad=[NSPropertyListSerialization dataWithPropertyList:badRoot format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
 assert(!DRPGReadSave(bad,&error));
 NSMutableDictionary* imported=[files mutableCopy]; imported[@"FULLPLAYER"]=config; [imported removeObjectForKey:@"FWORLD"];
 error=nil; assert(DRPGRestoreSave(imported,folder,&error)); assert(!error);
 assert(![fm fileExistsAtPath:[folder stringByAppendingPathComponent:@"FWORLD"]]);
 assert([fm fileExistsAtPath:[folder stringByAppendingPathComponent:@"FULLPLAYER"]]);
 NSArray* names=[fm contentsOfDirectoryAtPath:parent error:nil]; assert(names.count==2);
 NSString* backup=[names[0] isEqual:@"Saves"] ? names[1] : names[0];
 assert([fm fileExistsAtPath:[[parent stringByAppendingPathComponent:backup] stringByAppendingPathComponent:@"FWORLD"]]);
 imported[@"../unexpected"]=config;
 assert(!DRPGRestoreSave(imported,folder,&error));
 assert([fm fileExistsAtPath:[folder stringByAppendingPathComponent:@"FULLPLAYER"]]);
 [fm removeItemAtPath:parent error:nil];
 puts("PASS: save round trip, cross-game rejection, previous-save backup, stale-world removal, path rejection");
 } return 0; }
