//
//  ZBStage.h
//  Zebra
//
//  Created by Wilson Styres on 3/2/20.
//  Copyright © 2020 Wilson Styres. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ZBStageDownload = 0,
    ZBStageInstall,
    ZBStageReinstall,
    ZBStageRemove,
    ZBStageUpgrade,
    ZBStageDowngrade,
    ZBStageFinished
} ZBStageType;

NS_ASSUME_NONNULL_BEGIN

@interface ZBStage : NSObject
@property ZBStageType type;
@property (strong) NSArray *command;
@end

NS_ASSUME_NONNULL_END
