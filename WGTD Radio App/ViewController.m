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

@interface ViewController () <STKAudioPlayerDelegate>

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

@property(nonatomic) BOOL playing;
@property(strong, nonatomic) STKAudioPlayer *audioPlayer;

@property(strong, nonatomic) NSArray *channels;
@property(nonatomic) int channelIndex;
@property(strong, nonatomic) NSArray *channelLabelTexts;
@property(strong, nonatomic) NSArray *skipButtonLabelText;

@property(nonatomic) int bannerNumber;

@end

@implementation ViewController

#pragma mark - MVC Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.audioPlayer = [[STKAudioPlayer alloc] init];
    self.audioPlayer.delegate = self;
    self.audioPlayer.meteringEnabled = YES;
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
        [self.view insertSubview:self.waveView belowSubview:self.playButton];
    }
}

#pragma mark - Button Pressed Handlers
- (IBAction)infoButtonPressed:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"showInfo" sender:self];
}

- (IBAction)playPressed:(UIButton *)sender
{
    if(!self.playing)
    {
        [self.audioPlayer play:self.channels[self.channelIndex]];
        UIImage *image = [UIImage imageNamed:@"pause"];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.playButton setImage:image forState:UIControlStateNormal];
        
        self.playing = YES;
    } else
    {
        [self.audioPlayer stop];
        UIImage *image = [UIImage imageNamed:@"play"];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.playButton setImage:image forState:UIControlStateNormal];
        
        self.playing = NO;
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
    
    if(self.playing)
    {
        [self.audioPlayer stop];
        [self.audioPlayer play:self.channels[self.channelIndex]];
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.channelIndex forKey:@"Channel Index"];
    self.channelLabel.text = self.channelLabelTexts[self.channelIndex];
    
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
    CGFloat level = (([self.audioPlayer averagePowerInDecibelsForChannel:1] + 60) / 60);
    NSLog(@"%f", level);
    
    [self.waveView updateWithLevel:level];
}

#pragma mark - Audio Player Delegate
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
    
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
}

-(void) audioPlayer:(STKAudioPlayer *)audioPlayer logInfo:(NSString *)line
{
}

@end
