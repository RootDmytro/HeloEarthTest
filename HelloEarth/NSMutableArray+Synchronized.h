//
//  NSMutableArray+Synchronized.h
//  RocketEarth
//
//  Created by Dmytro Yaropovetsky on 11/3/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray<ObjectType> (Synchronized)

- (NSUInteger)countSync;
- (NSArray<ObjectType> *)copySync;

@end

@interface NSMutableArray<ObjectType> (Synchronized)

- (NSUInteger)countSync;
- (void)addObjectSync:(ObjectType)object;
- (void)removeObjectSync:(ObjectType)object;
- (NSArray<ObjectType> *)copySync;

@end
