//
//  NSMutableArray+Synchronized.m
//  RocketEarth
//
//  Created by Dmytro Yaropovetsky on 11/3/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import "NSMutableArray+Synchronized.h"

@implementation NSArray (Synchronized)

- (NSUInteger)countSync {
	return [self count];
}

- (NSArray<id> *)copySync {
	return [self copy];
}

@end

@implementation NSMutableArray (Synchronized)

- (NSUInteger)countSync {
	@synchronized (self) {
		return [self count];
	}
}

- (void)addObjectSync:(id)object {
	@synchronized (self) {
		[self addObject:object];
	}
}

- (void)removeObjectSync:(id)object {
	@synchronized (self) {
		[self removeObject:object];
	}
}

- (NSArray<id> *)copySync {
	@synchronized (self) {
		return [self copy];
	}
}

@end
