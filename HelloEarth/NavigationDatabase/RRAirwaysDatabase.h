//
//  RRAirwaysDatabase.h
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 19.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RRDatabaseBase.h"
#import "Airways.h"

@interface RRAirwaysDatabase : RRDatabaseBase

+ (RRAirwaysDatabase *)sharedInstance;

- (NSArray<Airways *> *)airwaysWithIdent:(NSString *)ident;
- (NSArray<Airways *> *)airwaysWithIdent:(NSString *)ident toWaypoint:(NSString *)toIdent reversable:(BOOL)isReversable;
- (NSArray<Airways *> *)airwaysWithIdent:(NSString *)ident fromWaypoint:(NSString *)fromIdent toWaypoint:(NSString *)toIdent reversable:(BOOL)isReversable;
- (NSArray<Airways *> *)airwaysFromWaypoint:(NSString *)fromIdent toWaypoint:(NSString *)toIdent reversable:(BOOL)isReversable;
- (NSArray<Airways *> *)airwaysWithWaypoint:(NSString *)ident;
- (NSArray<Airways *> *)airwaysWithSource:(NSString *)ident;
- (NSArray<Airways *> *)airwaysWithDest:(NSString *)ident;

@end
