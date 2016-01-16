//
//  WaveView.m
//  WGTD Radio App
//
//  Created by Kyle Zawacki on 3/22/15.
//  Copyright (c) 2015 University Of Wiscosnin Parkside. All rights reserved.
//
#import "WaveView.h"

static const CGFloat kDefaultFrequency          = 1.5f;
static const CGFloat kDefaultAplitude           = 1.0f;
static const CGFloat kDefaultIdleAmplitude      = 0.01f;
static const CGFloat kDefaultNumberOfWaves      = 5.0f;
static const CGFloat kDefaultPhaseShift         = -0.15f;
static const CGFloat kDefaultDensity            = 5.0f;
static const CGFloat kDefaultPrimaryLineWidth   = 3.0f;
static const CGFloat kDefaultSecondaryLineWidth = 1.0f;

@interface WaveView ()

@property (nonatomic, assign) CGFloat phase;
@property (nonatomic, assign) CGFloat amplitude;

@end

@implementation WaveView

- (instancetype)init
{
	if(self = [super init]) {
		[self setup];
	}
	
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		[self setup];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self setup];
}

- (void)setup
{
	self.waveColor = [UIColor whiteColor];
	
	self.frequency = kDefaultFrequency;
	
	self.amplitude = kDefaultAplitude;
	self.idleAmplitude = kDefaultIdleAmplitude;
	
	self.numberOfWaves = kDefaultNumberOfWaves;
	self.phaseShift = kDefaultPhaseShift;
	self.density = kDefaultDensity;
	
	self.primaryWaveLineWidth = kDefaultPrimaryLineWidth;
	self.secondaryWaveLineWidth = kDefaultSecondaryLineWidth;
}

- (void)updateWithLevel:(CGFloat)level
{
	self.phase += self.phaseShift;
	self.amplitude = fmax(level, self.idleAmplitude);
	
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, self.bounds);
	
	[self.backgroundColor set];
	CGContextFillRect(context, rect);
	
	for (int i = 0; i < self.numberOfWaves; i++) {
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		CGContextSetLineWidth(context, (i == 0 ? self.primaryWaveLineWidth : self.secondaryWaveLineWidth));
		
		CGFloat halfHeight = CGRectGetHeight(self.bounds) / 2.0f;
		CGFloat width = CGRectGetWidth(self.bounds);
		CGFloat mid = width / 2.0f;
		
		const CGFloat maxAmplitude = halfHeight - 4.0f;
		
		// Progress is a value between 1.0 and -0.5, determined by the current wave idx, which is used to alter the wave's amplitude.
		CGFloat progress = 1.0f - (CGFloat)i / self.numberOfWaves;
		CGFloat normedAmplitude = (1.5f * progress - 0.5f) * self.amplitude;
		
        CGFloat multiplier = MIN(1.0, (progress / 3.0f * 2.0f) + (1.0f / 3.0f));
		[[self.waveColor colorWithAlphaComponent:multiplier * CGColorGetAlpha(self.waveColor.CGColor)] set];
		
		for (CGFloat x = 0; x<width + self.density; x += self.density) {
			CGFloat scaling = -pow(1 / mid * (x - mid), 2) + 1;
			
			CGFloat y = scaling * maxAmplitude * normedAmplitude * sinf(2 * M_PI *(x / width) * self.frequency + self.phase) + halfHeight;
			
			if (x == 0) {
				CGContextMoveToPoint(context, x, y);
			} else {
				CGContextAddLineToPoint(context, x, y);
			}
		}
		
		CGContextStrokePath(context);
	}
}

@end
