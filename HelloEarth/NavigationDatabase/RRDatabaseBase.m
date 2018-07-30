//
//  RRDatabaseBase.m
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 19.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import "RRDatabaseBase.h"
#import <FMDB.h>

@implementation RRDatabaseBase {
	NSString * _dbPath;
	FMDatabaseQueue * _queue;
}

- (id)initWithDBPath:(NSString *)dbPath {
	self = [super init];
	if (self) {
		_dbPath = dbPath;
	}
	return self;
}

- (FMDatabaseQueue *)queue {
	NSAssert(_dbPath, @"database path can't be nil");
	
	if (!_queue && _dbPath) {
		if ([NSFileManager.defaultManager fileExistsAtPath:_dbPath]) {
			_queue = [FMDatabaseQueue databaseQueueWithPath:_dbPath];
		} else {
			NSLog(@"Database file does not exist. Download base data via Charts screen first.");
		}
	}
	return _queue;
}

@end
