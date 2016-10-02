//
//  Tweet.h
//  TwitterSpy
//
//  Created by William on 28/09/16.
//  Copyright © 2016 William. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

//could also be an NSManagedObject, but since we do not need to store tweets
//no need to save the tweet to a backing store

@interface Tweet : NSObject

@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *poster;

@property (nonatomic) CLLocationCoordinate2D coordinate;

@property (strong, nonatomic) MKPointAnnotation *annotation;

- (instancetype)initWithPoster:(NSString *)poster Text:(NSString *)text Coordinates:(CLLocationCoordinate2D)coordinate;

@end
