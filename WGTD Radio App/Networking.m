//
//  Networking.m
//  WGTD Radio App
//
//  Created by Kyle Zawacki on 9/17/15.
//  Copyright © 2015 University Of Wiscosnin Parkside. All rights reserved.
//

#import "Networking.h"

@implementation Networking

+ (BOOL)registerWithImageServer
{
    NSURL *url=[NSURL URLWithString:@"http://appfactoryuwp.com/imageserver/api/yum/key/104"];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"b5d4af3cfb232c01311b183d42d05648" forHTTPHeaderField:@"X-API-KEY"];
    [request addValue:@"73509e2f8981fd1247f400de53c60b0f8053fbb5" forHTTPHeaderField:@"X-SHHH-ITS-A-SECRET"];
    NSHTTPURLResponse *response;
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error: NULL];
    NSString *myString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
    
    NSString *apiKey = [myString componentsSeparatedByString:@"<"][3];
    apiKey = [apiKey componentsSeparatedByString:@">"][1];
    
    [[NSUserDefaults standardUserDefaults] setValue:apiKey forKey:@"Api Key"];
    
    NSLog(@":)");

    return ([response statusCode]==200)?YES:NO;
}

@end
