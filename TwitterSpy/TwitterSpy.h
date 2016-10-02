//
//  Test.h
//  Farmis
//
//  Created by Vilmantas on 28/09/16.
//  Copyright © 2016 Rento Media. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tweet.h"

@protocol TwitterSpyDelegate;

//default 4 seconds
static const NSTimeInterval kTweetLifetime = 4;

@interface TwitterSpy : NSObject

@property (nonatomic) BOOL shouldGenerateCoordinates;

- (instancetype)initWithDelegate:(id <TwitterSpyDelegate>)delegate Map:(MKMapView *)map;

- (void)startSpying;
- (void)stopSpying;
- (void)setFilterText:(NSString *)text;

@end

@protocol TwitterSpyDelegate

- (void)TwitterSpy:(TwitterSpy *)twitterSpy didShowTweet:(Tweet *)tweet;
- (void)TwitterSpy:(TwitterSpy *)twitterSpy didRemoveTweet:(Tweet *)tweet;

@end
