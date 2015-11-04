//
//  Networking.h
//  WGTD Radio App
//
//  Created by Kyle Zawacki on 9/17/15.
//  Copyright © 2015 University Of Wiscosnin Parkside. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Networking : UIViewController

+ (NSArray*)requestBannerImagesFromServer;
+ (BOOL)registerWithImageServer;
+ (BOOL)imageserverAvailable;

@end
