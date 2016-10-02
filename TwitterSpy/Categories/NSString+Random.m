//
//  NSString+Random.m
//  TwitterSpy
//
//  Created by William on 28/09/16.
//  Copyright © 2016 William. All rights reserved.
//

#import "NSString+Random.h"

@implementation NSString (Random)

+ (NSString *)randomString //taken from STTwitter library
{
    CFUUIDRef cfuuid = CFUUIDCreate (kCFAllocatorDefault);
    NSString *uuid = (__bridge_transfer NSString *)(CFUUIDCreateString (kCFAllocatorDefault, cfuuid));
    CFRelease (cfuuid);
    return uuid;
}

@end
