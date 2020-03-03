//
//  ZBCommand.h
//  Zebra
//
//  Created by Wilson Styres on 2/29/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZBCommandDelegate.h"
#import "ZBSlingshot.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZBCommand : NSObject <ZBSlingshotClient>
@property id <ZBCommandDelegate> delegate;
@property id <ZBSlingshotServer> slingshot;
@property BOOL finished;
- (id)initWithDelegate:(id <ZBCommandDelegate> _Nullable)delegate;
- (void)executeCommands:(NSArray <NSArray <NSString *> *> *)commands asRoot:(BOOL)root;
- (int)executeCommand:(NSArray <NSString *> *)command;
@end

NS_ASSUME_NONNULL_END
