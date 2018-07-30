//
// Created by Yuriy Levytskyy on 20.02.14.
// Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

@interface RRDatabaseObjectBase : NSObject

- (void)setupTableWithKey:(NSString *)key indexedFields:(NSArray *)indexedFields;

- (NSDictionary *)properties;

+ (instancetype)objectForKey:(NSString *)key forValue:(NSString *)value andClass:(Class)aClass searchPrefix:(BOOL)searchPrefix;

- (BOOL)updateObjectForKey:(NSString *)key forValue:(NSString *)value;

+ (NSMutableArray *)objectsForClass:(Class)aClass;
+ (NSMutableArray *)objectsForKey:(NSString *)key
                  forValue:(NSString *)value
                  andClass:(Class)aClass;

+ (void)removeAll:(Class)aClass;

+ (BOOL)executeSqlStatement:(NSString *)sqlStatement aClass:(Class)aClass;

- (void)update;

+ (void)remove:(NSString *)key
         value:(NSString *)value
      andClass:(Class)aClass;

// TODO: Make protected!
+ (NSString *)entityName:(Class)aClass;

+ (FMDatabaseQueue *)queue:(Class)aClass;

+ (NSMutableArray *)objectsForSqlStatement:(NSString *)sqlStatement
                           andClass:(Class)aClass;

@end
