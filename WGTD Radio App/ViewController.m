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
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "Networking.h"
#import "XMLDictionary.h"
#import "WGTD-Swift.h"

#define BlockWeakObject(o) __typeof(o) __weak
#define BlockWeakSelf BlockWeakObject(self)

@interface ViewController () <FSPCMAudioStreamDelegate>

@property (strong, nonatomic) WaveView *waveView;
@property(strong, nonatomic) UIVisualEffectView *blurEffectView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bannerHeightConst;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *backwardsButton;
@property (weak, nonatomic) IBOutlet UIButton *forwardsButton;
@property (weak, nonatomic) IBOutlet UIImageView *background;
@property (weak, nonatomic) IBOutlet UILabel *channelLabel;
@property (weak, nonatomic) IBOutlet UILabel *forwardLabel;
@property (weak, nonatomic) IBOutlet UILabel *backwardLabel;
@property (weak, nonatomic) IBOutlet UIView *waveContainer;
@property (weak, nonatomic) IBOutlet UIImageView *bannerImage;
@property (weak, nonatomic) IBOutlet UIImageView *stationImage;

@property(nonatomic) BOOL playing;
@property(nonatomic) BOOL streamReady;
@property(strong, nonatomic) FSAudioStream *audioPlayer;
@property(strong, nonatomic) STKAudioPlayer *stkPlayer;

@property(strong, nonatomic) NSArray *channels;
@property(nonatomic) int channelIndex;
@property(strong, nonatomic) NSArray *channelLabelTexts;
@property(strong, nonatomic) NSArray *skipButtonLabelText;
@property(strong, nonatomic) NSArray *stationImageNames;

@property(nonatomic) int bannerNumber;
@property(nonatomic, strong) NSMutableArray *bannerAdArray;

@property(strong, nonatomic) JFMinimalNotification *notification;

@property(strong, nonatomic) ChannelDropdown *dropdown;

@end

@implementation ViewController

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.bannerAdArray = [[NSMutableArray alloc] init];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self setupChannels];
    [self scheduleWaveAndAdTimers];
    [self setupGoogleAnalytics];
    
    self.navigationController.navigationBar.topItem.title = @"";
    
    self.bannerNumber = 0;
    
    [self setSkipButtonLabels];
    [self setupAudioPlayers];
    
    [self grabBannerImagesFromServer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupViews];
    
    self.dropdown = [[ChannelDropdown alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) items:@[@"Classical",@"Jazz",@"Reading",@"Sports"] title:@"Classical" nav: self.navigationController];
    self.dropdown.master = self;
    [self.navigationController.view addSubview:self.dropdown];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if(!self.waveView)
    {
        [self setupWaveView];
    }
}

- (void)setupWaveView
{
    self.waveView = [[WaveView alloc] initWithFrame:self.waveContainer.frame];
    self.waveView.center = self.waveContainer.center;
    self.waveView.backgroundColor = [UIColor clearColor];
    self.waveView.waveColor = self.view.tintColor;
    self.waveView.idleAmplitude = 0.02;
    [self.view insertSubview:self.waveView belowSubview:self.playButton];
}

- (void)setupViews
{
    [self setupBlurredBackgroundView];
    [self setupControlButtons];
    [self setupStationImage];
}

- (void)setupStationImage
{
    self.stationImage.image = [UIImage imageNamed:self.stationImageNames[self.channelIndex]];
}

-(void)setupControlButtons
{
    UIImage *image = [UIImage imageNamed:@"play"];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    [self.playButton setBackgroundImage:image forState:UIControlStateNormal];
    self.playButton.tintColor = self.view.tintColor;
    
    image = [UIImage imageNamed:@"backward"];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.backwardsButton setBackgroundImage:image forState:UIControlStateNormal];
    
    image = [UIImage imageNamed:@"forward"];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.forwardsButton setBackgroundImage:image forState:UIControlStateNormal];
}

- (void)setupBlurredBackgroundView
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
}

- (void)setupGoogleAnalytics
{
    id tracker = [[GAI sharedInstance] defaultTracker];
    
    [tracker set:kGAIScreenName value:@"Main Screen"];
    
    // manual screen tracking
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)scheduleWaveAndAdTimers
{
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateWaveView) userInfo:nil repeats:YES];
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(changeAdBanner) userInfo:nil repeats:YES];
}

- (void)setupChannels
{
    self.channels = @[@"http://media.gtc.edu:8000/stream", @"http://199.255.3.11:88/broadwave.mp3?src=1&rate=1&ref=http%3A%2F%2Fwww.wgtd.org%2Fhd2.asp",
                      @"http://199.255.3.11:88/broadwave.mp3?src=4&rate=1&ref=http%3A%2F%2Fwww.wgtd.org%2Freading.asp",
                      @"http://sportsweb.gtc.edu:8000/Sportsweb"];
    self.channelLabelTexts = @[@"Classical Radio", @"Jazz Radio", @"Reading Service", @"Sportsweb Radio"];
    self.skipButtonLabelText = @[@"Classical", @"Jazz", @"Reading", @"Sportsweb"];
    self.stationImageNames = @[@"Classical", @"Jazz", @"Reading", @"Sports"];
    
    if(![[NSUserDefaults standardUserDefaults] integerForKey:@"Channel Index"])
    {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"Channel Index"];
        self.channelIndex = 0;
    } else
    {
        self.channelIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"Channel Index"];
    }
}

- (void)setupAudioPlayers
{
    self.stkPlayer = [[STKAudioPlayer alloc] init];
    STKAudioPlayerOptions options = self.stkPlayer.options;
    options.enableVolumeMixer = YES;
    
    self.stkPlayer = [[STKAudioPlayer alloc] initWithOptions:options];
    self.stkPlayer.meteringEnabled = YES;
    self.stkPlayer.volume = 0.0;
    
    self.audioPlayer = [[FSAudioStream alloc] init];
    self.audioPlayer.url = [NSURL URLWithString:self.channels[self.channelIndex]];
    
    BlockWeakSelf weakSelf = self;
    
    self.audioPlayer.onStateChange = ^ (FSAudioStreamState state)
    {
        NSLog(@"%u", state);
        if(state == kFsAudioStreamBuffering)
        {
            weakSelf.streamReady = NO;
            
            if(weakSelf.notification)
            {
                [weakSelf.notification dismiss];
            }
            
            weakSelf.notification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleWarning title:@"" subTitle:@"Your stream is loading....."];
            weakSelf.notification.presentFromTop = YES;
            
            [weakSelf.view addSubview: weakSelf.notification];
            
            if(weakSelf.notification.superview)
            {
                [weakSelf.notification show];
            }
            
        } else if(state == kFsAudioStreamPlaying)
        {
            weakSelf.streamReady = YES;
            
            if(weakSelf.notification)
            {
                [weakSelf.notification dismiss];
            }
            
            weakSelf.notification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleSuccess title:@"" subTitle:@"Your stream is now playing!" dismissalDelay:1];
            weakSelf.notification.presentFromTop = YES;
            [weakSelf.view sendSubviewToBack:weakSelf.notification];
            
            [weakSelf.view addSubview: weakSelf.notification];
            
            if(weakSelf.notification.superview)
            {
                [weakSelf.notification show];
            }
            
        } else if(state == kFsAudioStreamFailed)
        {
            weakSelf.streamReady = NO;
            
            if(weakSelf.notification.currentStyle != JFMinimalNotificationStyleError)
            {
                [weakSelf.notification dismiss];
                weakSelf.notification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleError title:@"" subTitle:@"There was an error!" dismissalDelay:1];
                weakSelf.notification.presentFromTop = YES;
                
                [weakSelf.view addSubview: weakSelf.notification];
                
                if(weakSelf.notification.superview)
                {
                    [weakSelf.notification show];
                }
            }
        }
    };
}

#pragma mark - Button Action Handlers
- (void) dropDownChosenWithChannel:(NSString*)channelName
{
    int index = [self.stationImageNames indexOfObject:channelName];
    
    self.channelIndex = index;
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.channelIndex forKey:@"Channel Index"];
    self.stationImage.image = [UIImage imageNamed:self.stationImageNames[self.channelIndex]];
    
    self.audioPlayer.url = [NSURL URLWithString:self.channels[self.channelIndex]];
    
    if(self.playing)
    {
        [self.audioPlayer stop];
        [self.stkPlayer stop];
        
        UIImage *image = [UIImage imageNamed:@"play"];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.playButton setBackgroundImage:image forState:UIControlStateNormal];
        
        self.playing = NO;
        self.streamReady = NO;
        
        
    }
    
    if(self.notification)
    {
        [self.notification dismiss];
    }
    
    self.navigationController.navigationItem.title = self.channelLabelTexts[self.channelIndex];
    [self setSkipButtonLabels];
}

- (IBAction)infoButtonPressed:(UIBarButtonItem *)sender
{
    [self performSegueWithIdentifier:@"showInfo" sender:self];
}

- (IBAction)playPressed:(UIButton *)sender
{
    if(self.channelIndex == 2)
    {
        if(![self checkScheduleForReading])
        {
            return;
        }
    }
    
    if(!self.playing)
    {
        [self checkInternetWithPossibleAlert];
        
        NSLog(@"%@", self.channels[self.channelIndex]);
        [self.audioPlayer play];
        [self.stkPlayer play: self.channels[self.channelIndex]];
        UIImage *image = [UIImage imageNamed:@"pause"];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.playButton setBackgroundImage:image forState:UIControlStateNormal];
        
        self.playing = YES;
        
    } else
    {
        [self.audioPlayer stop];
        [self.stkPlayer stop];
        UIImage *image = [UIImage imageNamed:@"play"];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.playButton setBackgroundImage:image forState:UIControlStateNormal];
        
        self.playing = NO;
        self.streamReady = NO;
        
        if(self.notification)
        {
            [self.notification dismiss];
        }
    }
}

- (IBAction)skipButtonsPressed:(UIButton *)sender
{
    if(sender == self.forwardsButton)
    {
        self.channelIndex += 1;
        
        if(self.channelIndex > 3)
        {
            self.channelIndex = 0;
        }
    } else
    {
        self.channelIndex -= 1;
        
        if(self.channelIndex < 0)
        {
            self.channelIndex = 3;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:self.channelIndex forKey:@"Channel Index"];
    self.stationImage.image = [UIImage imageNamed:self.stationImageNames[self.channelIndex]];

    self.audioPlayer.url = [NSURL URLWithString:self.channels[self.channelIndex]];
    
    if(self.playing)
    {
        [self.audioPlayer stop];
        [self.stkPlayer stop];
        
        UIImage *image = [UIImage imageNamed:@"play"];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.playButton setBackgroundImage:image forState:UIControlStateNormal];
        
        self.playing = NO;
        self.streamReady = NO;
    }
    
    if(self.notification)
    {
        [self.notification dismiss];
    }
    
    self.dropdown.titleText.text = self.stationImageNames[self.channelIndex];
    [self setSkipButtonLabels];
}

#pragma mark - Update Views
- (void)setSkipButtonLabels
{
    int forwardLabelIndex;
    int backwardLabelIndex;
    
    forwardLabelIndex = self.channelIndex + 1;
    backwardLabelIndex = self.channelIndex - 1;
    
    if(forwardLabelIndex > 3)
    {
        forwardLabelIndex = 0;
    } else if(backwardLabelIndex < 0)
    {
        backwardLabelIndex = 3;
    }
    
    self.forwardLabel.text = self.skipButtonLabelText[forwardLabelIndex];
    self.backwardLabel.text = self.skipButtonLabelText[backwardLabelIndex];
}

- (void)changeAdBanner
{
    if(self.bannerAdArray.count > 0)
    {
        self.bannerNumber += 1;
        
        if(self.bannerNumber == self.bannerAdArray.count)
        {
            self.bannerNumber = 0;
        }
        
        self.bannerImage.image = self.bannerAdArray[self.bannerNumber];
    }
}

- (void)updateWaveView
{
    CGFloat level = (([self.stkPlayer averagePowerInDecibelsForChannel:1] + 60) / 60);

    if(self.streamReady)
    {
        if(self.stkPlayer.state == STKAudioPlayerStateError)
        {
//            NSLog(@"STK broken");
            [self.waveView updateWithLevel: 0.5];
            [self.stkPlayer stop];
            [self.stkPlayer play:self.channels[self.channelIndex]];
        } else
        {
//            NSLog(@"STK not broken");
            [self.waveView updateWithLevel: level];
        }
    } else
    {
        [self.waveView updateWithLevel: 0.01];
    }
}

#pragma mark - Network Code
- (BOOL)checkScheduleForReading
{
    NSDate *now = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"cccc"];
    NSString *weekday = [[dateFormatter stringFromDate:now] lowercaseString];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *currComp = [calendar components:(NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit) fromDate:now];
    
    NSInteger currentHour = [currComp hour];

    if([weekday isEqualToString:@"saturday"] || [weekday isEqualToString:@"sunday"] || currentHour < 10 || currentHour > 16)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Station Not Available" message:@"This station is only available from 10AM to 4PM on weekdays." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:nil];
        
        return NO;
    }
    
    return YES;
}

- (void)checkInternetWithPossibleAlert
{
    dispatch_queue_t background = dispatch_queue_create("Internet Check", NULL);
    dispatch_async(background, ^{
        if(![Reachability connectedToInternet])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Internet Error" message:@"You have no internet connection!" preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
                [alert addAction:action];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
    });
}

- (void)grabBannerImagesFromServer
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        self.bannerAdArray = [Networking requestBannerImagesFromServer];
    }];
}

# pragma mark - Other
-(void)didReceiveMemoryWarning
{
    [self.stkPlayer stop];
}

@end
