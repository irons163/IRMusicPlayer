//
//  MusicPlayerViewController.h
//  demo
//
//  Created by Phil on 2019/10/2.
//  Copyright © 2019 Phil. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MusicPlayerViewCallBackDelegate <NSObject>
-(void)didMusicChange:(NSString*)path;
@end

@interface MusicPlayerViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) IBOutlet UILabel *musicNameLbl;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBar;
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UILabel *startTimeLbl;
@property (strong, nonatomic) IBOutlet UILabel *endTimeLbl;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;
@property (strong, nonatomic) IBOutlet UIButton *playBtn;
@property (strong, nonatomic) IBOutlet UIButton *randomBtn;
@property (strong, nonatomic) IBOutlet UIButton *circleBtn;
@property (strong, nonatomic) IBOutlet UIImageView *coverView;
@property (strong, nonatomic) IBOutlet UILabel *titleLbl;
@property (strong, nonatomic) IBOutlet UIView *playBarView;

@property (strong, nonatomic) NSMutableArray *musicListArray;
@property int musicLocation;//第幾首

@property (weak) id<MusicPlayerViewCallBackDelegate> delegate;

- (IBAction)close:(id)sender;
- (IBAction)doPlay:(id)sender;
- (IBAction)doNext:(id)sender;
- (IBAction)doPrev:(id)sender;
- (IBAction)doRandom:(id)sender;
- (IBAction)doCircle:(id)sender;

@end

NS_ASSUME_NONNULL_END
