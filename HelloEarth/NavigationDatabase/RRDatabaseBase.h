//
//  RRDatabaseBase.h
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 19.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

@interface RRDatabaseBase : NSObject

@property(readonly) FMDatabaseQueue *queue;

- (id)initWithDBPath:(NSString *)dbPath;

@end
