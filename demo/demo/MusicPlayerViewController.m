//
//  MusicPlayerViewController.m
//  demo
//
//  Created by Phil on 2019/10/2.
//  Copyright © 2019 Phil. All rights reserved.
//

#import "MusicPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>
#import "StatusClass.h"
#import "KeysDefine.h"
#import "UIColor+Helper.h"

@interface MusicPlayerViewController (){
    //NSMutableArray *musicListArray;//音樂檔案
    //int musicLocation;//第幾首
    float musicLength,downloadSeconds;//音樂長度,下載秒數
    float audioNowTime;//目前播放秒數
    BOOL tagIfControl, tagIfStop;//是否要重新將資料列到control, 是否停止Player
    NSMutableDictionary *controlMediaInfo;//控制面板的資訊
    
    NSTimer *dwnProgressTimer,*goProgressTimer;
    int randomCount;
}

@property (nonatomic, strong) AVQueuePlayer *player;

@end

@implementation MusicPlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.musicListArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
#ifdef MESSHUDrive
    self.titleLbl.textColor = [UIColor whiteColor];
    self.playBarView.backgroundColor = [UIColor colorWithColorCodeString:NavigationBarBGColor];
#else
    self.titleLbl.textColor = [UIColor colorWithRGB:0x00b4f5];
    self.playBarView.backgroundColor = [UIColor colorWithRGB:0x00b4f5];
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {// iOS 7
        self.mainView.frame = CGRectMake(0, 20, self.mainView.frame.size.width, self.mainView.frame.size.height-20);
    } else {// iOS 6
    }
#endif
    [UIView setAnimationsEnabled:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Turn on remote control event delivery
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // Set itself as the first responder
    [self becomeFirstResponder];
    
    //button Status
    self.randomBtn.selected = [[NSUserDefaults standardUserDefaults] boolForKey:PLAYER_RANDOM_BUTTON_STATUS_KEY];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"playerCircleBtnStatus"] == 0) {
        self.circleBtn.tag = 0;
        [self.circleBtn setImage:[UIImage imageNamed:@"btn_repeat_0"] forState:UIControlStateNormal];
    }else if ([[NSUserDefaults standardUserDefaults] integerForKey:PLAYER_CIRCLE_BUTTON_STATUS_KEY] == 1) {
        self.circleBtn.tag = 1;
        [self.circleBtn setImage:[UIImage imageNamed:@"btn_repeat_all"] forState:UIControlStateNormal];
    }else if ([[NSUserDefaults standardUserDefaults] integerForKey:PLAYER_CIRCLE_BUTTON_STATUS_KEY] == 2) {
        self.circleBtn.tag = 2;
        [self.circleBtn setImage:[UIImage imageNamed:@"btn_repeat_1"] forState:UIControlStateNormal];
    }
    
    //self.musicLocation = 0;
    //LogMessage(nil, 0, @"musicAddress %@", [[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"]);
    self.coverView.image = [UIImage imageNamed:@"img_cover"];
    [self performSelectorInBackground:@selector(getMusicCover:) withObject:[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"]];
    
    AVPlayerItem *firstItem;
    if ( [[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"] rangeOfString:@"http://"].length >0) {
        firstItem = [AVPlayerItem playerItemWithURL: [NSURL URLWithString:[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"] ]];
    }else{
        firstItem = [AVPlayerItem playerItemWithURL: [NSURL fileURLWithPath:[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"] ]];
    }
    self.player = [AVQueuePlayer queuePlayerWithItems:[NSArray arrayWithObjects:firstItem, nil]];
    [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:firstItem];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    self.slider.enabled = false;
    [self.slider addTarget:self action:@selector(sliderValueChangedAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.slider setMaximumTrackTintColor:[UIColor clearColor]];
    //[self.slider setMinimumTrackTintColor:[UIColor clearColor]];
    
    //設定音量0.0~1.0
    //[_player setVolume:1];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Turn off remote control event delivery
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
    // Resign as first responder
    [self resignFirstResponder];
    
    
    tagIfStop = YES;
    [StatusClass sharedInstance].isAudioPlaying = NO;
    self.musicNameLbl.text = @"";
    [self.player pause];
    [self.playBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateNormal];
    
    [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
    [self setClean];
    [self.musicListArray removeAllObjects];
    [dwnProgressTimer invalidate];
    dwnProgressTimer = nil;
    [goProgressTimer invalidate];
    goProgressTimer = nil;
    
    [self.player removeObserver:self forKeyPath:@"status" context:nil];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    NSLog(@"ReceiveMemoryWarning");
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSLog(@"放歌通知");
    
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        if (self.player.status == AVPlayerStatusReadyToPlay) {
            //歌曲長度
            //[self getMusicLength];
            
            //NSLog(@"musicLength: %.2f", musicLength);
            
            //dwnProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
            goProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(goProgress:) userInfo:nil repeats:YES];
            
            //播放
            [_player play];
            [self.playBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
            
            tagIfControl = YES;
            NSLog(@"放歌");
            [StatusClass sharedInstance].isAudioPlaying = YES;
        } else if (self.player.status == AVPlayerStatusFailed) {
            NSLog(@"歌曲失敗");
            [StatusClass sharedInstance].isAudioPlaying = NO;
        }
    }
}

//計算下載到幾秒
- (void)updateProgress:(NSTimer *)theTimer {
    //停止
    if (self.progressBar.progress == 1) {
        [dwnProgressTimer invalidate];
        dwnProgressTimer = nil;
    }else{
        NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        //downloadSeconds = CMTimeGetSeconds(timeRange.duration);
        
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval result = startSeconds + durationSeconds;
        downloadSeconds  = result;
        //LogMessage(nil, 0, @"downloadSeconds %f", downloadSeconds);
        
        if (downloadSeconds > 0) {
            self.progressBar.progress = downloadSeconds / musicLength;
        }
        if (tagIfStop == NO) {
            if (self.player.rate == 0.0 && downloadSeconds > audioNowTime + 5) {
                [self.player play];
                [self.playBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
                [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:audioNowTime];
            }
        }
    }
}

- (void)goProgress:(NSTimer *)theTimer {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay){
        [StatusClass sharedInstance].isAudioPlaying = YES;
        //LogMessage(nil, 0, @"%f", self.player.rate);
        if (self.player.rate == 1.0){
            
            AVPlayerItem *currentItem = self.player.currentItem;
            CMTime currentTime = currentItem.currentTime; //playing time
            audioNowTime = CMTimeGetSeconds(currentTime);
            if (audioNowTime / 3600 >= 1) {//超過一個小時
                if (((int)audioNowTime%3600)%60 < 10) {
                    self.startTimeLbl.text = [NSString stringWithFormat:@"%d:%d:0%d", (int)audioNowTime/3600, ((int)audioNowTime%3600)/60, ((int)audioNowTime%3600)%60];
                }else{
                    self.startTimeLbl.text = [NSString stringWithFormat:@"%d:%d:%d", (int)audioNowTime/3600, ((int)audioNowTime%3600)/60, ((int)audioNowTime%3600)%60];
                }
            }else{
                if ((int)audioNowTime%60<10) {
                    self.startTimeLbl.text = [NSString stringWithFormat:@"%d:0%d",(int)audioNowTime/60, (int)audioNowTime%60];
                }else{
                    self.startTimeLbl.text = [NSString stringWithFormat:@"%d:%d",(int)audioNowTime/60, (int)audioNowTime%60];
                }
            }
            
            if ((int)audioNowTime%60>0) {
                if (tagIfControl == YES) {
                    dwnProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
                    //歌曲長度
                    [self getMusicLength];
                    
                    //控制器宣告
                    [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:0.f];
                    tagIfControl = NO;
                }
                
                //每秒增加的progress
                float diff = 1 / musicLength;
                float progress = self.slider.value;
                progress = progress + diff;
                [self.slider setValue:progress];
            }
            
            
            [self.playBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
            
            if (downloadSeconds < musicLength) {
                self.loadingView.hidden = NO;
            }else{
                self.loadingView.hidden = YES;
            }
        }else{
            
            if (tagIfStop == NO) {
                if (downloadSeconds > audioNowTime + 5) {
                    [self.player play];
                    [self.playBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
                    [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:audioNowTime];
                }else{
                    [self.player pause];
                    [self.playBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateNormal];
                    [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
                }
            }else{
                [self.player pause];
                [self.playBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateNormal];
                [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
            }
            
        }
        
    }else{
        NSLog(@"音樂下載中");
        
        self.loadingView.hidden = NO;
        [self.playBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
    }
}

//改變UISlide
- (IBAction)sliderValueChangedAction:(id)sender {
    audioNowTime = musicLength * [(UISlider *)sender value];//計算移動到幾妙
    //NSLog(@"%f",musicSeekTime);
    
    if (audioNowTime / 3600 >= 1) {//超過一個小時
        if (((int)audioNowTime%3600)%60 < 10) {
            self.startTimeLbl.text = [NSString stringWithFormat:@"%d:%d:0%d", (int)audioNowTime/3600, ((int)audioNowTime%3600)/60, ((int)audioNowTime%3600)%60];
        }else{
            self.startTimeLbl.text = [NSString stringWithFormat:@"%d:%d:%d", (int)audioNowTime/3600, ((int)audioNowTime%3600)/60, ((int)audioNowTime%3600)%60];
        }
    }else{
        if ((int)audioNowTime%60<10) {
            self.startTimeLbl.text = [NSString stringWithFormat:@"%d:0%d",(int)audioNowTime/60, (int)audioNowTime%60];
        }else{
            self.startTimeLbl.text = [NSString stringWithFormat:@"%d:%d",(int)audioNowTime/60, (int)audioNowTime%60];
        }
    }
    
    CMTime cmTime = CMTimeMake(audioNowTime, 1);
    [self.player seekToTime:cmTime];
    
    if (downloadSeconds < audioNowTime) {//如果尚未下載完成
        //tagIfStop = YES;
        [self.player pause];
        [self.playBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateNormal];
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
    }else{
        //audioNowTime = musicSeekTime;
        //tagIfStop = NO;
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:audioNowTime];
    }
}

- (void)setClean{
    [StatusClass sharedInstance].isAudioPlaying = NO;
    self.progressBar.progress = 0;
    self.slider.value = 0;
    
    self.startTimeLbl.text = [NSString stringWithFormat:@"00:00"];
    self.endTimeLbl.text = [NSString stringWithFormat:@"00:00"];
    
    [dwnProgressTimer invalidate];
    dwnProgressTimer = nil;
    
    //控制器
    [self setControlMedia:@"Loading..." artist:@"" length:0.f rate:0 seekTime:0.f];
}

//結束完播放下一首歌曲
-(void)itemDidFinishPlaying {
    [self doNext];
    //[self doNext:nil];
}

//取得歌曲長度
- (void)getMusicLength{
    CMTime duration = self.player.currentItem.asset.duration;
    
    //    NSLog(@"CMTimeGetSeconds asset.duration %f",CMTimeGetSeconds(self.player.currentItem.asset.duration));
    //    NSLog(@"CMTimeGetSeconds duration %f",CMTimeGetSeconds(self.player.currentItem.duration));
    
    musicLength = CMTimeGetSeconds(duration);
    //musicLength = 5689;
    self.slider.enabled = true;
    
    NSLog(@"musicLength %f", musicLength);
    
    if (musicLength / 3600 >= 1) {//超過一個小時
        if (((int)musicLength%3600)%60 < 10) {
            self.endTimeLbl.text = [NSString stringWithFormat:@"%d:%d:0%d", (int)musicLength/3600, ((int)musicLength%3600)/60, ((int)musicLength%3600)%60];
        }else{
            self.endTimeLbl.text = [NSString stringWithFormat:@"%d:%d:%d", (int)musicLength/3600, ((int)musicLength%3600)/60, ((int)musicLength%3600)%60];
        }
    }else{
        if ((int)musicLength%60<10) {
            self.endTimeLbl.text = [NSString stringWithFormat:@"%d:0%d",(int)musicLength/60, (int)musicLength%60];
        }else{
            self.endTimeLbl.text = [NSString stringWithFormat:@"%d:%d",(int)musicLength/60, (int)musicLength%60];
        }
    }
    
    //歌名
    NSArray *array = [[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicName"]  componentsSeparatedByString:@"/"];
    self.musicNameLbl.text = [array objectAtIndex:[array count]-1];
}

//設定控制器
- (void)setControlMedia:(NSString*)title artist:(NSString*)artist length:(int)length rate:(int)rate seekTime:(int)seekTime{
    //控制器宣告
    NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyTitle,MPMediaItemPropertyArtist,MPMediaItemPropertyPlaybackDuration,MPNowPlayingInfoPropertyPlaybackRate,nil];
    NSArray *values = [NSArray arrayWithObjects:title, artist, [NSNumber numberWithInt:length], [NSNumber numberWithInt:rate],nil];
    controlMediaInfo = [NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
    
    [controlMediaInfo setObject:[NSNumber numberWithFloat:seekTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:controlMediaInfo];
}

- (IBAction)doPlay:(id)sender {
    if (self.player.rate == 1.0) {
        tagIfStop = YES;
        [self.player pause];
        [self.playBtn setImage:[UIImage imageNamed:@"btn_play"] forState:UIControlStateNormal];
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
    }else{
        tagIfStop = NO;
        [self.player play];
        [self.playBtn setImage:[UIImage imageNamed:@"btn_pause"] forState:UIControlStateNormal];
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:audioNowTime];
    }
}

//自動播放下一首歌時
- (void)doNext{
    [self setClean];
    
    if (self.circleBtn.tag == 0) {//播全部歌一次
        if (self.randomBtn.selected) {//隨機
            self.musicLocation = [self random];
            randomCount++;
            if (randomCount == [self.musicListArray count]) {
                [self close:nil];
            }else{
                [self doChangeMusic];
            }
        }else{
            if (self.musicLocation < [self.musicListArray count] - 1) {
                self.musicLocation ++;
                [self doChangeMusic];
            }else{//播完了
                [self close:nil];
            }
        }
    }else if (self.circleBtn.tag == 1) {//circle
        if (self.randomBtn.selected) {
            self.musicLocation = [self random];
        }else{
            if (self.musicLocation < [self.musicListArray count] - 1) {
                self.musicLocation ++;
            }else{
                self.musicLocation = 0;
            }
        }
        [self doChangeMusic];
    }else if (self.circleBtn.tag == 2) {//單首
        [self doChangeMusic];
    }
}

- (IBAction)doNext:(id)sender {
    [self setClean];
    
    if (self.randomBtn.selected) {//隨機
        self.musicLocation = [self random];
        [self doChangeMusic];
    }else{
        if (self.musicLocation < [self.musicListArray count]-1) {
            self.musicLocation++;
        }else{
            self.musicLocation=0;
        }
        
        [self doChangeMusic];
    }
}

- (IBAction)doPrev:(id)sender {
    [self setClean];
    
    if (self.randomBtn.selected) {//隨機
        self.musicLocation = [self random];
        [self doChangeMusic];
    }else{
        if (self.musicLocation > 0 ) {
            self.musicLocation--;
        }else{
            self.musicLocation = [self.musicListArray count]-1;
        }
        
        [self doChangeMusic];
    }
}

- (void)doChangeMusic{
    self.slider.enabled = false;
    AVPlayerItem *nextItem;
    if ( [[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"] rangeOfString:@"http://"].length >0) {
        nextItem = [AVPlayerItem playerItemWithURL: [NSURL URLWithString:[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"] ]];
    }else{
        nextItem = [AVPlayerItem playerItemWithURL: [NSURL fileURLWithPath:[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"] ]];
    }
    [self.player insertItem:nextItem afterItem:nil];
    [self.player advanceToNextItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:nextItem];
    
    [self performSelectorInBackground:@selector(getMusicCover:) withObject:[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"]];
    
    tagIfControl = YES;
    [self.delegate didMusicChange:[[self.musicListArray objectAtIndex:self.musicLocation] valueForKey:@"musicAddress"]];
}

- (int)random{
    if ([self.musicListArray count] > 1) {
        int i = arc4random() % [self.musicListArray count];
        if (i == self.musicLocation) {
            i = [self random];
        }
        return i;
    }else{
        return 0;
    }
}

- (IBAction)doRandom:(id)sender {
    randomCount = 0;
    self.randomBtn.selected = !self.randomBtn.selected;
    
    //NSLog(@"%d", self.randomBtn.isSelected);
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:[NSString stringWithFormat:@"%d", self.randomBtn.isSelected] forKey:PLAYER_RANDOM_BUTTON_STATUS_KEY];
    [userDefault synchronize];
}

- (IBAction)doCircle:(id)sender {
    if (self.circleBtn.tag == 0) {
        self.circleBtn.tag = 1;
        [self.circleBtn setImage:[UIImage imageNamed:@"btn_repeat_all"] forState:UIControlStateNormal];
    }else if (self.circleBtn.tag == 1) {
        self.circleBtn.tag = 2;
        [self.circleBtn setImage:[UIImage imageNamed:@"btn_repeat_1"] forState:UIControlStateNormal];
    }else if (self.circleBtn.tag == 2) {
        self.circleBtn.tag = 0;
        [self.circleBtn setImage:[UIImage imageNamed:@"btn_repeat_0"] forState:UIControlStateNormal];
    }
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:[NSString stringWithFormat:@"%d", self.circleBtn.tag] forKey:PLAYER_CIRCLE_BUTTON_STATUS_KEY];
    [userDefault synchronize];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [self doPlay:nil];
                break;
            case UIEventSubtypeRemoteControlPause:
                [self doPlay:nil];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self doPrev:nil];
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [self doNext:nil];
                break;
            default:
                break;
        }
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (IBAction)close:(id)sender{
    //    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

//取得音樂封面
- (void)getMusicCover:(NSString*)urlString{
    NSURL *url = [NSURL URLWithString:urlString];
    AVAsset *asset = [AVAsset assetWithURL:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.coverView.image = [UIImage imageNamed:@"img_cover"];
        for (AVMetadataItem *metadataItem in asset.commonMetadata) {
            if ([metadataItem.keySpace isEqualToString:AVMetadataKeySpaceID3]){
                if ([metadataItem.value isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *imageDataDictionary = (NSDictionary *)metadataItem.value;
                    NSData *imageData = [imageDataDictionary objectForKey:@"data"];
                    UIImage *image = [UIImage imageWithData:imageData];
                    // Display this image on my UIImageView property imageView
                    if (image) {
                        self.coverView.image = image;
                        break;
                    }
                }else if([metadataItem.value isKindOfClass:[NSData class]]){
                    UIImage *image = [UIImage imageWithData:(NSData*)metadataItem.value];
                    if (image) {
                        self.coverView.image = image;
                        break;
                    }
                }
            }else if ([metadataItem.keySpace isEqualToString:AVMetadataKeySpaceiTunes]){
                if([[metadataItem.value copyWithZone:nil] isKindOfClass:[NSData class]]){
                    UIImage* image = [UIImage imageWithData:[metadataItem.value copyWithZone:nil]];
                    if (image) {
                        self.coverView.image = image;
                        break;
                    }
                }
            }
        }
    });
}

@end

