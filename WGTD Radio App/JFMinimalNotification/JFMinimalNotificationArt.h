//
//  JFMinimalNotificationArt.h
//  JFMinimalNotification
//
//  Created by Jeremy Fox on 11/17/14.
//  Copyright (c) 2014 Jeremy Fox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JFMinimalNotificationArt : NSObject

+ (UIImage*)imageOfCheckmarkWithColor:(UIColor*)color;

+ (UIImage*)imageOfCrossWithColor:(UIColor*)color;

+ (UIImage*)imageOfNoticeWithColor:(UIColor*)color;

+ (UIImage*)imageOfWarningWithBGColor:(UIColor*)backgroundColor forgroundColor:(UIColor*)forgroundColor;

+ (UIImage*)imageOfInfoWithColor:(UIColor*)color;

+ (UIImage*)imageOfEditWithColor:(UIColor*)color;

+ (void)drawCheckmarkWithColor:(UIColor*)color;

+ (void)drawCrossWithColor:(UIColor*)color;

+ (void)drawNoticeWithColor:(UIColor*)color;

+ (void)drawWarningWithBGColor:(UIColor*)backgroundColor forgroundColor:(UIColor*)forgroundColor;

+ (void)drawInfoWithColor:(UIColor*)color;

+ (void)drawEditWithColor:(UIColor*)color;

@end
