//
//  MapAircraft.h
//  RocketEarth
//
//  Created by Dmytro Yaropovetsky on 10/20/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ActiveMarker;

@interface MapAircraft : NSObject

@property (nonatomic, assign) double turnDirection;
@property (nonatomic, assign) double speed;

- (instancetype)initWithActiveMarker:(ActiveMarker *)activeMarker;

- (void)fly;

@end
