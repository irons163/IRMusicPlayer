//
//  UIColor+Helper.h
//  IRMusicPlayer
//
//  Created by Phil on 2019/11/1.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Helper)

+ (UIColor *)colorWithColorCodeString:(NSString*)colorString;
+ (UIColor *)colorWithARGB:(NSUInteger)color;
+ (UIColor *)colorWithRGB:(NSUInteger)color;
+ (UIColor *)colorWithRGBA:(NSUInteger)color;
+ (UIColor *)colorWithRGBWithString:(NSString*)colorString;

@end

NS_ASSUME_NONNULL_END
