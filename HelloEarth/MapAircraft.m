//
//  MapAircraft.m
//  RocketEarth
//
//  Created by Dmytro Yaropovetsky on 10/20/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import "MapAircraft.h"
#import "ActiveMarker.h"

@interface MapAircraft ()

@property (nonatomic, strong) ActiveMarker *activeMarker;

@end

@implementation MapAircraft

- (instancetype)initWithActiveMarker:(ActiveMarker *)activeMarker {
	self = [self init];
	if (self) {
		self.activeMarker = activeMarker;
		self.speed = 100 + (rand() % 100 - 50) / 100.0;
		self.turnDirection = 0;
	}
	return self;
}

- (void)fly {
	MaplyCoordinate coordinate = self.activeMarker.coordinate;
	
	self.turnDirection = MAX(-50, MIN(50, self.turnDirection + (rand() % 10 - 5) / 10.0));
	
	double rotation = self.activeMarker.rotation;
	[self.activeMarker setRotation:rotation + self.turnDirection / 180 * M_PI withDuration:2.5];
	
	coordinate.x += (-sin(rotation)) / 100.0 / 180.0 * M_PI;
	coordinate.y += (cos(rotation)) / 100.0 / 180.0 * M_PI;
	
	[self.activeMarker setCoordinate:coordinate withDuration:2.5];
}

@end
