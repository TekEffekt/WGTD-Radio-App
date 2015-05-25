//
//  ViewController.m
//  WGTD Radio App
//
//  Created by Kyle Zawacki on 3/22/15.
//  Copyright (c) 2015 University Of Wiscosnin Parkside. All rights reserved.
//

#import "ViewController.h"
#import "STKAudioPlayer.h"
#import "WaveView.h"
#import "InfoViewController.h"
#import "FSAudioStream.h"
#import "Reachability.h"
#import "JFMinimalNotification.h"

@interface ViewController () <FSPCMAudioStreamDelegate>

@property (strong, nonatomic) WaveView *waveView;
@property(strong, nonatomic) UIVisualEffectView *blurEffectView;

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *backwardsButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardsButton;
@property (weak, nonatomic) IBOutlet UIImageView *background;
@property (weak, nonatomic) IBOutlet UILabel *channelLabel;
@property (weak, nonatomic) IBOutlet UILabel *forwardLabel;
@property (weak, nonatomic) IBOutlet UILabel *backwardLabel;
@property (weak, nonatomic) IBOutlet UIView *waveContainer;
@property (weak, nonatomic) IBOutlet UIImageView *bannerImage;
@property (weak, nonatomic) IBOutlet UIView *stationImage;

@property(nonatomic) BOOL playing;
@property(nonatomic) BOOL streamReady;
@property(strong, nonatomic) FSAudioStream *audioPlayer;
@property(strong, nonatomic) STKAudioPlayer *stkPlayer;

@property(strong, nonatomic) NSArray *channels;
@property(nonatomic) int channelIndex;
@property(strong, nonatomic) NSArray *channelLabelTexts;
@property(strong, nonatomic) NSArray *skipButtonLabelText;

@property(nonatomic) int bannerNumber;

@property(strong, nonatomic) JFMinimalNotification *notification;

@end

@implementation ViewController

#pragma mark - MVC Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateWaveView) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(changeAdBanner) userInfo:nil repeats:YES];
    
    self.channels = @[@"http://media.gtc.edu:8000/stream", @"http://199.255.3.11:88/broadwave.mp3?src=1&rate=1&ref=http%3A%2F%2Fwww.wgtd.org%2Fhd2.asp",
                      @"http://199.255.3.11:88/broadwave.mp3?src=2&rate=1&ref=http%3A%2F%2Fwww.wgtd.org%2Fhd3.asp"];
    self.channelLabelTexts = @[@"Classical Radio", @"Jazz Radio", @"Community Radio"];
    self.skipButtonLabelText = @[@"Classical", @"Jazz", @"Community"];
    
    if(![[NSUserDefaults standardUserDefaults] integerForKey:@"Channel Index"])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"Channel Index"];
        self.channelIndex = 0;
    } else
    {
        self.channelIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"Channel Index"];
    }
    
    [self setSkipButtonLabels];
    
    self.bannerNumber = 1;
    
    self.stkPlayer = [[STKAudioPlayer alloc] init];
    STKAudioPlayerOptions options = self.stkPlayer.options;
    options.enableVolumeMixer = YES;
    
    self.stkPlayer = [[STKAudioPlayer alloc] initWithOptions:options];
    self.stkPlayer.meteringEnabled = YES;
    self.stkPlayer.volume = 0.0;
    
    self.audioPlayer = [[FSAudioStream alloc] init];
    self.audioPlayer.url = [NSURL URLWithString:self.channels[self.channelIndex]];
    
    self.audioPlayer.onStateChange = ^ (FSAudioStreamState state)
    {
        if([Reachability connectedToInternet])
        {
            NSLog(@"%u", state);
            if(state == kFsAudioStreamBuffering)
            {
                self.streamReady = NO;
                
                self.notification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleWarning title:@"" subTitle:@"Your stream is loading....."];
                
                [self.view addSubview:self.notification];
                
                [self.notification show];
            } else if(state == kFsAudioStreamPlaying)
            {
                self.streamReady = YES;
                
                if(self.notification)
                {
                    [self.notification dismiss];
                }
                
                self.notification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleSuccess title:@"" subTitle:@"Your stream is now playing!" dismissalDelay:1];
                
                [self.view addSubview:self.notification];
                
                [self.notification show];
            } else if(state == kFsAudioStreamFailed)
            {
                self.streamReady = NO;
                
                if(self.notification)
                {
                    [self.notification dismiss];
                }
                
                self.notification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleError title:@"" subTitle:@"There was an error!" dismissalDelay:1];
                
                [self.view addSubview:self.notification];
                
                [self.notification show];
            }
        } else
        {
            [self.audioPlayer stop];
            [self.stkPlayer stop];
            UIImage *image = [UIImage imageNamed:@"play"];
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.playButton setImage:image forState:UIControlStateNormal];
            
            self.playing = NO;
            self.streamReady = NO;
            
            if(self.notification.currentStyle != JFMinimalNotificationStyleError)
            {
                if(self.notification)
                {
                    [self.notification dismiss];
                }
                
                self.notification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleError title:@"" subTitle:@"There was an error!" dismissalDelay:1];
                
                [self.view addSubview:self.notification];
                
                [self.notification show];
            }
        }
    };
    
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(snapshotStats) userInfo:nil repeats:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    self.blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    [self.blurEffectView setFrame:self.view.bounds];
    [self.view insertSubview:self.blurEffectView aboveSubview:self.background];
    
    // Vibrancy effect
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
    [vibrancyEffectView setFrame:self.view.bounds];
    
    // Add the vibrancy view to the blur view
    [[self.blurEffectView contentView] addSubview:vibrancyEffectView];
    
    UIImage *image = [UIImage imageNamed:@"play"];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    [self.playButton setImage:image forState:UIControlStateNormal];
    self.playButton.tintColor = self.view.tintColor;
    
    self.channelLabel.text = self.channelLabelTexts[self.channelIndex];
}

- (void)viewDidLayoutSubviews
{
    if(!self.waveView)
    {
        self.waveView = [[WaveView alloc] initWithFrame:self.waveContainer.frame];
        self.waveView.center = self.waveContainer.center;
        self.waveView.backgroundColor = [UIColor clearColor];
        self.waveView.waveColor = self.view.tintColor;
        self.waveView.idleAmplitude = 0.02;
        [self.view insertSubview:self.waveView aboveSubview:self.stationImage];
    }
}

#pragma mark - Button Pressed Handlers
- (IBAction)infoButtonPressed:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"showInfo" sender:self];
}

- (IBAction)playPressed:(UIButton *)sender
{
    
    if([Reachability connectedToInternet])
    {
        if(!self.playing)
        {
            [self.audioPlayer play];
            [self.stkPlayer play: self.channels[self.channelIndex]];
            UIImage *image = [UIImage imageNamed:@"pause"];
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.playButton setImage:image forState:UIControlStateNormal];
            
            self.playing = YES;
        } else
        {
            [self.audioPlayer stop];
            [self.stkPlayer stop];
            UIImage *image = [UIImage imageNamed:@"play"];
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.playButton setImage:image forState:UIControlStateNormal];
            
            self.playing = NO;
            self.streamReady = NO;
            
            if(self.notification)
            {
                [self.notification dismiss];
            }
        }
    } else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Uh Oh!" message:@"You have no internet connection!" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
        
        [alert addAction:action];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)skipButtonsPressed:(UIButton *)sender
{
    if(sender == self.forwardsButton)
    {
        self.channelIndex += 1;
        
        if(self.channelIndex > 2)
        {
            self.channelIndex = 0;
        }
    } else
    {
        self.channelIndex -= 1;
        
        if(self.channelIndex < 0)
        {
            self.channelIndex = 2;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.channelIndex forKey:@"Channel Index"];
    self.channelLabel.text = self.channelLabelTexts[self.channelIndex];
    
    self.audioPlayer.url = [NSURL URLWithString:self.channels[self.channelIndex]];
    
    if(self.playing)
    {
        [self.audioPlayer stop];
        [self.stkPlayer stop];
        
        UIImage *image = [UIImage imageNamed:@"play"];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.playButton setImage:image forState:UIControlStateNormal];
        
        self.playing = NO;
        self.streamReady = NO;
    }
    
    if(self.notification)
    {
        [self.notification dismiss];
    }
    
    [self setSkipButtonLabels];
}

- (void)setSkipButtonLabels
{
    int forwardLabelIndex;
    int backwardLabelIndex;
    
    forwardLabelIndex = self.channelIndex + 1;
    backwardLabelIndex = self.channelIndex - 1;
    
    if(forwardLabelIndex > 2)
    {
        forwardLabelIndex = 0;
    } else if(backwardLabelIndex < 0)
    {
        backwardLabelIndex = 2;
    }
    
    self.forwardLabel.text = self.skipButtonLabelText[forwardLabelIndex];
    self.backwardLabel.text = self.skipButtonLabelText[backwardLabelIndex];
}

- (void)changeAdBanner
{
    self.bannerNumber += 1;
    
    if(self.bannerNumber > 5)
    {
        self.bannerNumber = 1;
    }
    
    self.bannerImage.image = [UIImage imageNamed:[NSString stringWithFormat:@"banner%d", self.bannerNumber]];
}

# pragma mark - Wave View
- (void)updateWaveView
{
    CGFloat level = (([self.stkPlayer averagePowerInDecibelsForChannel:1] + 60) / 60);

    if(self.streamReady)
    {
        if(self.stkPlayer.state == STKAudioPlayerStateError)
        {
            NSLog(@"STK broken");
            [self.waveView updateWithLevel: 0.5];
            [self.stkPlayer stop];
            [self.stkPlayer play:self.channels[self.channelIndex]];
        } else
        {
            NSLog(@"STK not broken");
            [self.waveView updateWithLevel: level];
        }
    } else
    {
        [self.waveView updateWithLevel: 0.01];
    }
}

# pragma mark - Stream Stats
- (void)snapshotStats
{
    FSStreamStatistics *stat = self.audioPlayer.statistics;
    
    
    NSString *statDescription = [stat description];
}


@end
