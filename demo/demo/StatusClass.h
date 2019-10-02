//
//  StatusClass.h
//  demo
//
//  Created by Phil on 2019/10/2.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StatusClass : NSObject

+ (StatusClass*)sharedInstance;

@property BOOL isAudioPlaying;

@end

NS_ASSUME_NONNULL_END
