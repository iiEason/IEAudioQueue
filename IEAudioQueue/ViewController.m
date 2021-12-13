//
//  ViewController.m
//  IEAudioQueue
//
//  Created by L on 2021/12/10.
//

#import "ViewController.h"
#import "IEMediaAuthor.h"
#import "IEAudioManager.h"
#import "IEPCMAudioWriter.h"
#import <AVKit/AVKit.h>
#import "IEPCMPlayer.h"

typedef enum : NSInteger{
    PlayerStop = 0,
    PlayerPlay,
    PlayerPause,
} PlayerState;

@interface ViewController ()<IEAudioManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *pathLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) long count;
@property (nonatomic, strong) IEAudioManager *manager;
@property (nonatomic, strong) IEPCMAudioWriter *pcmWriter;
@property (nonatomic, assign) PlayerState state;
@property (nonatomic, strong) IEPCMPlayer *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [IEMediaAuthor getAuthorMicphone:nil];
    _manager = [IEAudioManager shareAudioManager];
    _manager.delegate = self;
    
    _pcmWriter = [[IEPCMAudioWriter alloc] init];
    [_pcmWriter clearAllPCM];
    [_pcmWriter resetPCMHandler];
    _state = 0;
    
    [self updateButtonState];
    
}
- (IBAction)startButtonEvent:(id)sender {
    
    if (_state == PlayerPlay) return;
    _state = PlayerPlay;
    [self.manager start];
    [self updateButtonState];
    
    _pathLabel.text = [_pcmWriter getPCMHandler];
    
    if (!_timer) {
        __weak typeof(self) wself = self;
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(_timer, ^{
            if (wself.state == PlayerPlay) {
                wself.count++;
                wself.timeLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",wself.count/3600,wself.count/60,wself.count];
            }
        });
        dispatch_resume(_timer);
    }
    
}
- (IBAction)pauseButtonEvent:(id)sender {
    
    if (_state == PlayerPlay) {
        _state = 2;
        [self.manager pause];
        dispatch_suspend(_timer);
        [self updateButtonState];
    }
    
}

- (IBAction)stopButtonEvent:(id)sender {
    
    if (_state == PlayerPlay || _state == PlayerPause) {
        _state = PlayerStop;
        [self.manager stop];
        dispatch_source_cancel(_timer);
        _timer = nil;
        [self updateButtonState];
    }
    
}

- (IBAction)playButtonEvent:(id)sender {
    
    NSString *path = [_pcmWriter getPCMHandler];
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path];
    NSLog(@"play pcm : %@, isExist : %d",path,isExist);
    //设置audiosession和扬声器播放
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    _player = [[IEPCMPlayer alloc] initWithPCMFile:path];
    [_player play];
    
}

- (IBAction)clearButtonEvent:(id)sender {
    _state = PlayerStop;
    if (self.manager.aqc.run) {
        [self.manager stop];
    }
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    self.count = 0;
    self.timeLabel.text = @"00:00:00";
    self.pathLabel.text = @"地址";
    [self updateButtonState];
    [_pcmWriter clearAllPCM];
    [_pcmWriter resetPCMHandler];
}

- (void)updateButtonState {
    if (_state == PlayerPlay) {
        _startButton.backgroundColor = [UIColor grayColor];
        _stopButton.backgroundColor = [UIColor greenColor];
        _pauseButton.backgroundColor = [UIColor greenColor];
    }else if (_state == PlayerPause) {
        _pauseButton.backgroundColor = [UIColor grayColor];
        _stopButton.backgroundColor = [UIColor greenColor];
        _startButton.backgroundColor = [UIColor greenColor];
    }else{
        _stopButton.backgroundColor = [UIColor grayColor];
        _pauseButton.backgroundColor = [UIColor grayColor];
        _startButton.backgroundColor = [UIColor greenColor];
    }
}

- (void)processAudioPacket:(char *)data
                    length:(int)len {
    if (len > 0) {
        NSLog(@"write pcm data : %d",len);
        [_pcmWriter writePCM:data length:len];
    }
}

@end
