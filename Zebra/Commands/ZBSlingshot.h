//
//  ZBSlingshot.h
//  Zebra
//
//  Created by Wilson Styres on 2/29/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#ifndef ZBSlingshot_h
#define ZBSlingshot_h

@protocol ZBSlingshotServer

- (void)runCommandAtPath:(NSString *)path arguments:(NSArray *)arguments asRoot:(BOOL)root;

@end

@protocol ZBSlingshotClient

- (void)receivedData:(NSData *)data;
- (void)receivedErrorData:(NSData *)data;

@end

@interface ZBSlingshot : NSObject <NSXPCListenerDelegate, ZBSlingshotServer>

@end

#endif /* ZBSlingshotProtocol_h */
