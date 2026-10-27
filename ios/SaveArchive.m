#import "SaveArchive.h"
#import "GameInfo.h"
static NSArray* saveNames(void) {
 NSMutableArray* names=[NSMutableArray arrayWithArray:@[@"CONFIGFILENAME",@"BRIEFPLAYER",@"FULLPLAYER",@"FWORLD"]];
 for(int i=1;i<=10;i++)[names addObject:[NSString stringWithFormat:@"SB_%d",i]];
 return names;
}
static void invalid(NSError** error) {
 if(error)*error=[NSError errorWithDomain:@"DoomRPG" code:1 userInfo:@{NSLocalizedDescriptionKey:@"Select a complete save backup (.rpgsave) for this game."}];
}
NSDictionary* DRPGReadSave(NSData* data,NSError** error) {
 if(!data || data.length>8*1024*1024) { invalid(error); return nil; }
 id root=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:nil error:error];
 if(![root isKindOfClass:NSDictionary.class] || ![root[@"format"] isEqual:@1] || ![root[@"game"] isEqual:GAME_IDENTIFIER] || ![root[@"files"] isKindOfClass:NSDictionary.class]) { invalid(error); return nil; }
 NSDictionary* files=root[@"files"];
 if(!files[@"CONFIGFILENAME"] || (!files[@"BRIEFPLAYER"] && !files[@"FULLPLAYER"]) || files.count>14) { invalid(error); return nil; }
 for(NSString* n in files) {
  if(![saveNames() containsObject:n]) { invalid(error); return nil; }
  NSData* d=files[n];
  if(![d isKindOfClass:NSData.class] || d.length<4 || d.length>2*1024*1024) { invalid(error); return nil; }
 }
 const unsigned char* config=[files[@"CONFIGFILENAME"] bytes];
 if(config[0]!=GAME_CONFIG_VERSION || config[1] || config[2] || config[3]) { invalid(error); return nil; }
 return files;
}
NSData* DRPGExportSave(NSString* folder,NSError** error) {
 NSMutableDictionary* files=[NSMutableDictionary dictionary];
 for(NSString* n in saveNames()) {
  NSData* data=[NSData dataWithContentsOfFile:[folder stringByAppendingPathComponent:n] options:0 error:nil];
  if(!data)continue;
  files[n]=data;
 }
 NSData* data=[NSPropertyListSerialization dataWithPropertyList:@{@"format":@1,@"game":GAME_IDENTIFIER,@"files":files} format:NSPropertyListBinaryFormat_v1_0 options:0 error:error];
 return DRPGReadSave(data,error) ? data : nil;
}
BOOL DRPGRestoreSave(NSDictionary* files,NSString* folder,NSError** error) {
 // Revalidate even when called outside the document picker.
 NSData* archive=[NSPropertyListSerialization dataWithPropertyList:@{@"format":@1,@"game":GAME_IDENTIFIER,@"files":files} format:NSPropertyListBinaryFormat_v1_0 options:0 error:error];
 if(!DRPGReadSave(archive,error))return NO;
 NSFileManager* fm=NSFileManager.defaultManager;
 NSString* parent=folder.stringByDeletingLastPathComponent;
 NSString* stage=[parent stringByAppendingPathComponent:[@"Import " stringByAppendingString:NSUUID.UUID.UUIDString]];
 if(![fm copyItemAtPath:folder toPath:stage error:error])return NO;
 for(NSString* n in saveNames()) [fm removeItemAtPath:[stage stringByAppendingPathComponent:n] error:nil];
 for(NSString* n in files) {
  if(![files[n] writeToFile:[stage stringByAppendingPathComponent:n] options:NSDataWritingAtomic error:error]) { [fm removeItemAtPath:stage error:nil]; return NO; }
 }
 NSString* backup=[parent stringByAppendingPathComponent:[@"Previous Saves " stringByAppendingString:NSUUID.UUID.UUIDString]];
 if(![fm moveItemAtPath:folder toPath:backup error:error]) { [fm removeItemAtPath:stage error:nil]; return NO; }
 if(![fm moveItemAtPath:stage toPath:folder error:error]) {
  [fm moveItemAtPath:backup toPath:folder error:nil]; return NO;
 }
 return YES;
}
