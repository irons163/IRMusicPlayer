//
//  UIColor+Helper.m
//  IRMusicPlayer
//
//  Created by Phil on 2019/11/1.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "UIColor+Helper.h"

@implementation UIColor (Helper)

+ (UIColor *)colorWithColorCodeString:(NSString*)colorString
{
    unsigned color = 0;
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    
    //    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&color];
    
//    NSLog(@"%u",((color >> 24) & 0xFF));
    if(colorString.length==6){
        return [UIColor colorWithRGB:color];
    }else{
        return [UIColor colorWithARGB:color];
    }
}
+ (UIColor *)colorWithARGB:(NSUInteger)color
{
    return [UIColor colorWithRed:((color >> 16) & 0xFF) / 255.0f
                           green:((color >> 8) & 0xFF) / 255.0f
                            blue:((color >> 0) & 0xFF) / 255.0f
                           alpha:((color >> 24) & 0xFF) / 255.0f];
}
+ (UIColor *)colorWithRGB:(NSUInteger)color
{
    return [UIColor colorWithRed:((color >> 16) & 0xFF) / 255.0f
                           green:((color >> 8) & 0xFF) / 255.0f
                            blue:((color >> 0) & 0xFF) / 255.0f
                           alpha:255.0f];
}
+ (UIColor *)colorWithRGBA:(NSUInteger)color
{
    return [UIColor colorWithRed:((color >> 24) & 0xFF) / 255.0f
                           green:((color >> 16) & 0xFF) / 255.0f
                            blue:((color >> 8) & 0xFF) / 255.0f
                           alpha:((color) & 0xFF) / 255.0f];
}
+ (UIColor *)colorWithRGBWithString:(NSString*)colorString
{
    unsigned color = 0;
    NSScanner *scanner = [NSScanner scannerWithString:colorString];
    
//    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&color];
    return [UIColor colorWithRGB:color];
}

@end
