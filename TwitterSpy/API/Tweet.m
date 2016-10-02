//
//  Tweet.m
//  TwitterSpy
//
//  Created by William on 28/09/16.
//  Copyright © 2016 William. All rights reserved.
//

#import "Tweet.h"

@implementation Tweet

- (instancetype)initWithPoster:(NSString *)poster Text:(NSString *)text Coordinates:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    if (self) {
        _poster = poster;
        _text = text;
        _coordinate = coordinate;
    }
    return self;
}

@end
