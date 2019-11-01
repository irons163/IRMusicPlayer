#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MusicPlayerViewController.h"
#import "KeysDefine.h"
#import "StatusClass.h"
#import "UIColor+Helper.h"
#import "UIImage+Bundle.h"
#import "Utilities.h"
#import "IRMusicPlayer.h"

FOUNDATION_EXPORT double IRMusicPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char IRMusicPlayerVersionString[];

