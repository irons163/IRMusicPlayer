//
//  StatusClass.m
//  demo
//
//  Created by Phil on 2019/10/2.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "StatusClass.h"

@implementation StatusClass

+ (StatusClass*)sharedInstance {
    static id sharedInstance = nil;
    if (!sharedInstance) {
        sharedInstance = [self alloc];
        sharedInstance = [sharedInstance init];
    }
    return sharedInstance;
}

@end
