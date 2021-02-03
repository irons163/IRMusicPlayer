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
#import "UIImage+Bundle.h"

@interface MusicPlayerViewController (){
    float musicLength;
    float downloadSeconds;
    float audioNowTime;
    BOOL tagIfControl, tagIfStop;
    NSMutableDictionary *controlMediaInfo;
    
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

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.titleLbl.textColor = [UIColor colorWithRGB:0x00b4f5];
    self.playBarView.backgroundColor = [UIColor colorWithRGB:0x00b4f5];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Turn on remote control event delivery
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    // Set itself as the first responder
    [self becomeFirstResponder];
    
    //button Status
    self.randomBtn.selected = [[NSUserDefaults standardUserDefaults] boolForKey:PLAYER_RANDOM_BUTTON_STATUS_KEY];
    self.randomBtn.alpha = self.randomBtn.selected ? 1.0f : 0.3f;
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"playerCircleBtnStatus"] == 0) {
        self.circleBtn.tag = 0;
        [self.circleBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_repeat_all"] forState:UIControlStateNormal];
        self.circleBtn.alpha = 0.3f;
    }else if ([[NSUserDefaults standardUserDefaults] integerForKey:PLAYER_CIRCLE_BUTTON_STATUS_KEY] == 1) {
        self.circleBtn.tag = 1;
        [self.circleBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_repeat_all"] forState:UIControlStateNormal];
    }else if ([[NSUserDefaults standardUserDefaults] integerForKey:PLAYER_CIRCLE_BUTTON_STATUS_KEY] == 2) {
        self.circleBtn.tag = 2;
        [self.circleBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_repeat_1"] forState:UIControlStateNormal];
    }

    self.coverView.image = [UIImage imageNamedForCurrentBundle:@"img_cover"];
    [self performSelectorInBackground:@selector(getMusicCover:) withObject:[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"]];
    
    AVPlayerItem *firstItem;
    if ( [[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"] rangeOfString:@"http://"].length >0) {
        firstItem = [AVPlayerItem playerItemWithURL: [NSURL URLWithString:[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"] ]];
    }else{
        firstItem = [AVPlayerItem playerItemWithURL: [NSURL fileURLWithPath:[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"] ]];
    }
    self.player = [AVQueuePlayer queuePlayerWithItems:[NSArray arrayWithObjects:firstItem, nil]];
    [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:firstItem];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:NULL];
    
    self.slider.enabled = false;
    [self.slider addTarget:self action:@selector(sliderValueChangedAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.slider setMaximumTrackTintColor:[UIColor clearColor]];
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
    [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_play"] forState:UIControlStateNormal];
    
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
    NSLog(@"Ready to Play.");
    
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        if (self.player.status == AVPlayerStatusReadyToPlay) {
            //dwnProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateProgress:) userInfo:nil repeats:YES];
            goProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(goProgress:) userInfo:nil repeats:YES];
            
            [_player play];
            [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_pause"] forState:UIControlStateNormal];
            
            tagIfControl = YES;
            NSLog(@"Play");
            [StatusClass sharedInstance].isAudioPlaying = YES;
        } else if (self.player.status == AVPlayerStatusFailed) {
            NSLog(@"Play failure");
            [StatusClass sharedInstance].isAudioPlaying = NO;
        }
    }
}

- (void)updateProgress:(NSTimer *)theTimer {
    if (self.progressBar.progress == 1) { //stop
        [dwnProgressTimer invalidate];
        dwnProgressTimer = nil;
    }else{
        NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval result = startSeconds + durationSeconds;
        downloadSeconds  = result;
        
        if (downloadSeconds > 0) {
            self.progressBar.progress = downloadSeconds / musicLength;
        }
        if (tagIfStop == NO) {
            if (self.player.rate == 0.0 && downloadSeconds > audioNowTime + 5) {
                [self.player play];
                [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_pause"] forState:UIControlStateNormal];
                [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:audioNowTime];
            }
        }
    }
}

- (void)goProgress:(NSTimer *)theTimer {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay){
        [StatusClass sharedInstance].isAudioPlaying = YES;
        
        if (self.player.rate == 1.0){
            AVPlayerItem *currentItem = self.player.currentItem;
            CMTime currentTime = currentItem.currentTime; //playing time
            audioNowTime = CMTimeGetSeconds(currentTime);
            if (audioNowTime / 3600 >= 1) {//over 1 hr
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
                    [self getMusicLength];
                    [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:0.f];
                    tagIfControl = NO;
                }
                
                //update slider
                float diff = 1 / musicLength;
                float progress = self.slider.value;
                progress = progress + diff;
                [self.slider setValue:progress];
            }
            
            
            [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_pause"] forState:UIControlStateNormal];
            
            if (downloadSeconds < musicLength) {
                self.loadingView.hidden = NO;
            }else{
                self.loadingView.hidden = YES;
            }
        }else{
            
            if (tagIfStop == NO) {
                if (downloadSeconds > audioNowTime + 5) {
                    [self.player play];
                    [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_pause"] forState:UIControlStateNormal];
                    [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:audioNowTime];
                }else{
                    [self.player pause];
                    [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_play"] forState:UIControlStateNormal];
                    [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
                }
            }else{
                [self.player pause];
                [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_play"] forState:UIControlStateNormal];
                [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
            }
            
        }
        
    }else{
        NSLog(@"downloading...");
        
        self.loadingView.hidden = NO;
        [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_pause"] forState:UIControlStateNormal];
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
    }
}

- (IBAction)sliderValueChangedAction:(id)sender {
    audioNowTime = musicLength * [(UISlider *)sender value];
    
    if (audioNowTime / 3600 >= 1) {
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
    
    if (downloadSeconds < audioNowTime) {
        [self.player pause];
        [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_play"] forState:UIControlStateNormal];
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
    }else{
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:audioNowTime];
    }
}

- (void)setClean {
    [StatusClass sharedInstance].isAudioPlaying = NO;
    self.progressBar.progress = 0;
    self.slider.value = 0;
    
    self.startTimeLbl.text = [NSString stringWithFormat:@"00:00"];
    self.endTimeLbl.text = [NSString stringWithFormat:@"00:00"];
    
    [dwnProgressTimer invalidate];
    dwnProgressTimer = nil;
    
    [self setControlMedia:@"Loading..." artist:@"" length:0.f rate:0 seekTime:0.f];
}

- (void)itemDidFinishPlaying {
    [self doNextWithIgnoreCircleStatus:NO];
}

- (void)getMusicLength {
    CMTime duration = self.player.currentItem.asset.duration;
    musicLength = CMTimeGetSeconds(duration);
    self.slider.enabled = true;
    
    NSLog(@"musicLength %f", musicLength);
    
    if (musicLength / 3600 >= 1) {
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
    
    NSArray *array = [[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"]  componentsSeparatedByString:@"/"];
    self.musicNameLbl.text = [array objectAtIndex:[array count]-1];
}

- (void)setControlMedia:(NSString*)title artist:(NSString*)artist length:(int)length rate:(int)rate seekTime:(int)seekTime{
    NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyTitle,MPMediaItemPropertyArtist,MPMediaItemPropertyPlaybackDuration,MPNowPlayingInfoPropertyPlaybackRate,nil];
    NSArray *values = [NSArray arrayWithObjects:title, artist, [NSNumber numberWithInt:length], [NSNumber numberWithInt:rate],nil];
    controlMediaInfo = [NSMutableDictionary dictionaryWithObjects:values forKeys:keys];
    
    [controlMediaInfo setObject:[NSNumber numberWithFloat:seekTime] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:controlMediaInfo];
}

- (void)doPlay {
    if (self.player.rate == 1.0) {
        tagIfStop = YES;
        [self.player pause];
        [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_play"] forState:UIControlStateNormal];
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:0 seekTime:audioNowTime];
    }else{
        tagIfStop = NO;
        [self.player play];
        [self.playBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_pause"] forState:UIControlStateNormal];
        [self setControlMedia:self.musicNameLbl.text artist:@"" length:musicLength rate:1 seekTime:audioNowTime];
    }
}

- (IBAction)doPlay:(id)sender {
    [self doPlay];
}

- (void)doNextWithIgnoreCircleStatus:(BOOL)ignoreCircleStatus {
    [self setClean];
    
    if (ignoreCircleStatus) {
        if (self.randomBtn.selected) {
            self.musicIndex = [self random];
            [self doChangeMusic];
        }else{
            if (self.musicIndex < [self.musicListArray count]-1) {
                self.musicIndex++;
            }else{
                self.musicIndex=0;
            }
            
            [self doChangeMusic];
        }
    } else if (self.circleBtn.tag == 0) {//play all musics once.
        if (self.randomBtn.selected) {
            self.musicIndex = [self random];
            randomCount++;
            if (randomCount == [self.musicListArray count]) {
                [self close];
            }else{
                [self doChangeMusic];
            }
        }else{
            if (self.musicIndex < [self.musicListArray count] - 1) {
                self.musicIndex ++;
                [self doChangeMusic];
            }else{//done
                [self close];
            }
        }
    }else if (self.circleBtn.tag == 1) {//circle
        if (self.randomBtn.selected) {
            self.musicIndex = [self random];
        }else{
            if (self.musicIndex < [self.musicListArray count] - 1) {
                self.musicIndex ++;
            }else{
                self.musicIndex = 0;
            }
        }
        [self doChangeMusic];
    }else if (self.circleBtn.tag == 2) {//repeat
        [self doChangeMusic];
    }
}

- (IBAction)doNext:(id)sender {
    [self doNextWithIgnoreCircleStatus:YES];
}

- (void)doPrev {
    [self setClean];
    
    if (self.randomBtn.selected) {
        self.musicIndex = [self random];
        [self doChangeMusic];
    }else{
        if (self.musicIndex > 0 ) {
            self.musicIndex--;
        }else{
            self.musicIndex = [self.musicListArray count]-1;
        }
        
        [self doChangeMusic];
    }
}

- (IBAction)doPrev:(id)sender {
    [self doPrev];
}

- (void)doChangeMusic{
    self.slider.enabled = false;
    AVPlayerItem *nextItem;
    if ( [[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"] rangeOfString:@"http://"].length >0) {
        nextItem = [AVPlayerItem playerItemWithURL: [NSURL URLWithString:[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"] ]];
    }else{
        nextItem = [AVPlayerItem playerItemWithURL: [NSURL fileURLWithPath:[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"] ]];
    }
    [self.player insertItem:nextItem afterItem:nil];
    [self.player advanceToNextItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:nextItem];
    
    [self performSelectorInBackground:@selector(getMusicCover:) withObject:[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"]];
    
    tagIfControl = YES;
    [self.delegate didMusicChange:[[self.musicListArray objectAtIndex:self.musicIndex] valueForKey:@"musicAddress"]];
}

- (int)random{
    if ([self.musicListArray count] > 1) {
        int i = arc4random() % [self.musicListArray count];
        if (i == self.musicIndex) {
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
    self.randomBtn.alpha = self.randomBtn.selected ? 1.0f : 0.3f;
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:[NSString stringWithFormat:@"%d", self.randomBtn.isSelected] forKey:PLAYER_RANDOM_BUTTON_STATUS_KEY];
    [userDefault synchronize];
}

- (IBAction)doCircle:(id)sender {
    if (self.circleBtn.tag == 0) {
        self.circleBtn.tag = 1;
        [self.circleBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_repeat_all"] forState:UIControlStateNormal];
        self.circleBtn.alpha = 1.0f;
    }else if (self.circleBtn.tag == 1) {
        self.circleBtn.tag = 2;
        [self.circleBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_repeat_1"] forState:UIControlStateNormal];
    }else if (self.circleBtn.tag == 2) {
        self.circleBtn.tag = 0;
        [self.circleBtn setImage:[UIImage imageNamedForCurrentBundle:@"btn_repeat_all"] forState:UIControlStateNormal];
        self.circleBtn.alpha = 0.3f;
    }
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:[NSString stringWithFormat:@"%ld", self.circleBtn.tag] forKey:PLAYER_CIRCLE_BUTTON_STATUS_KEY];
    [userDefault synchronize];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPlay:
                [self doPlay];
                break;
            case UIEventSubtypeRemoteControlPause:
                [self doPlay];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self doPrev];
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [self doNextWithIgnoreCircleStatus:YES];
                break;
            default:
                break;
        }
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)getMusicCover:(NSString*)urlString{
    NSURL *url = [NSURL URLWithString:urlString];
    AVAsset *asset = [AVAsset assetWithURL:url];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.coverView.image = [UIImage imageNamedForCurrentBundle:@"img_cover"];
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

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)close:(id)sender{
    [self close];
}

@end

