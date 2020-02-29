//
//  ZBCommand.h
//  Zebra
//
//  Created by Wilson Styres on 2/29/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZBCommand : NSObject
- (void)runCommandAtPath:(NSString *)path arguments:(NSArray *)arguments asRoot:(BOOL)root;
@end

NS_ASSUME_NONNULL_END
