//
//  RRAirwaysDatabase.m
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 19.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import "RRAirwaysDatabase.h"
#import "RRKitUtils.h"
#import <FMDB.h>

@implementation RRAirwaysDatabase

NSString *RRAirwaysTableName = @"Airways";

+ (RRAirwaysDatabase *)sharedInstance
{
   static dispatch_once_t once;
   static RRAirwaysDatabase *instance;
   dispatch_once(&once, ^{
	   PathToResourceNamed(@"Airways.sqlite", ^(NSString *path) {
		   instance = [[RRAirwaysDatabase alloc] initWithDBPath:path];
	   });
   });

   return instance;
}

- (NSArray<Airways *> *)airwaysWithIdent:(NSString *)ident
{
   RRAirwaysDatabase *receiver = self;
   __block NSMutableArray<Airways *> *airways = [NSMutableArray array];
   [receiver.queue inDatabase:^(FMDatabase *database)
   {
      NSString *sqlStatement = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE ident=\'%@\' ORDER BY sequence ASC", RRAirwaysTableName, ident];

      // Search for the airport
      FMResultSet *resultSet = [database executeQuery:sqlStatement];
	   if (!resultSet) {
		   NSLog(@"%@", database.lastErrorMessage);
	   }

      while ([resultSet next])
      {
         Airways *airway = [RRAirwaysDatabase airwayFromResultSet:resultSet];
         [airways addObject:airway];
      }
      [resultSet close];
   }];
   return airways;
}

- (NSArray<Airways *> *)airwaysWithIdent:(NSString *)ident toWaypoint:(NSString *)toIdent reversable:(BOOL)isReversable
{
	RRAirwaysDatabase *receiver = self;
	__block NSMutableArray<Airways *> *airways = [NSMutableArray array];
	[receiver.queue inDatabase:^(FMDatabase *database) {
		NSString *searchQuery = !isReversable
		? [NSString stringWithFormat:@"SELECT * FROM %@ WHERE `ident` = ? AND `source` = ? ORDER BY `sequence` ASC", RRAirwaysTableName]
		: [NSString stringWithFormat:@"SELECT * FROM %@ WHERE `ident` = ? AND (`source` = ? OR `dest` = ?) ORDER BY `sequence` ASC", RRAirwaysTableName];
		
		FMResultSet *resultSet = [database executeQuery:searchQuery, ident, toIdent, toIdent];
		if (!resultSet) {
			NSLog(@"%@", database.lastErrorMessage);
		}
		
		while ([resultSet next]) {
			Airways *airway = [RRAirwaysDatabase airwayFromResultSet:resultSet];
			[airways addObject:airway];
		}
	}];
	return airways;
}

- (NSArray<Airways *> *)airwaysWithIdent:(NSString *)ident fromWaypoint:(NSString *)fromIdent toWaypoint:(NSString *)toIdent reversable:(BOOL)isReversable
{
	RRAirwaysDatabase *receiver = self;
	__block NSMutableArray<Airways *> *airways = [NSMutableArray array];
	[receiver.queue inDatabase:^(FMDatabase *database) {
		NSString *searchQuery = !isReversable
		? [NSString stringWithFormat:@"SELECT * FROM %@ WHERE `ident` = ? AND `source` = ? AND `dest` = ? ORDER BY `sequence` ASC", RRAirwaysTableName]
		: [NSString stringWithFormat:@"SELECT * FROM %@ WHERE `ident` = ? AND (`source` = ? AND `dest` = ? OR `dest` = ? AND `source` = ?) ORDER BY `sequence` ASC", RRAirwaysTableName];
		
		FMResultSet *resultSet = [database executeQuery:searchQuery, ident, fromIdent, toIdent, fromIdent, toIdent];
		if (!resultSet) {
			NSLog(@"%@", database.lastErrorMessage);
		}
		
		while ([resultSet next]) {
			Airways *airway = [RRAirwaysDatabase airwayFromResultSet:resultSet];
			[airways addObject:airway];
		}
	}];
	return airways;
}

- (NSArray<Airways *> *)airwaysFromWaypoint:(NSString *)fromIdent toWaypoint:(NSString *)toIdent reversable:(BOOL)isReversable
{
	RRAirwaysDatabase *receiver = self;
	__block NSMutableArray<Airways *> *airways = [NSMutableArray array];
	[receiver.queue inDatabase:^(FMDatabase *database) {
		NSString *searchQuery = !isReversable
		? [NSString stringWithFormat:@"SELECT * FROM %@ WHERE `source` = ? AND `dest` = ? ORDER BY `sequence` ASC", RRAirwaysTableName]
		: [NSString stringWithFormat:@"SELECT * FROM %@ WHERE `source` = ? AND `dest` = ? OR `dest` = ? AND `source` = ? ORDER BY `sequence` ASC", RRAirwaysTableName];
		
		FMResultSet *resultSet = [database executeQuery:searchQuery, fromIdent, toIdent, fromIdent, toIdent];
		if (!resultSet) {
			NSLog(@"%@", database.lastErrorMessage);
		}
		
		while ([resultSet next]) {
			Airways *airway = [RRAirwaysDatabase airwayFromResultSet:resultSet];
			[airways addObject:airway];
		}
	}];
	
	return airways;
}

- (NSArray<Airways *> *)airwaysWithWaypoint:(NSString *)ident
{
	RRAirwaysDatabase *receiver = self;
	__block NSMutableArray<Airways *> *airways = [NSMutableArray array];
	[receiver.queue inDatabase:^(FMDatabase *database) {
		NSString *searchQuery = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE `source` = ? OR `dest` = ? ORDER BY `sequence` ASC", RRAirwaysTableName];
		FMResultSet *resultSet = [database executeQuery:searchQuery, ident, ident];
		
		while ([resultSet next]) {
			Airways *airway = [RRAirwaysDatabase airwayFromResultSet:resultSet];
			[airways addObject:airway];
		}
	}];
	
	return airways;
}

- (NSArray<Airways *> *)airwaysWithSource:(NSString *)ident
{
	RRAirwaysDatabase *receiver = self;
	__block NSMutableArray<Airways *> *airways = [NSMutableArray array];
	[receiver.queue inDatabase:^(FMDatabase *database) {
		NSString *searchQuery = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE `source` = ? ORDER BY `sequence` ASC", RRAirwaysTableName];
		FMResultSet *resultSet = [database executeQuery:searchQuery, ident];
		
		while ([resultSet next]) {
			Airways *airway = [RRAirwaysDatabase airwayFromResultSet:resultSet];
			[airways addObject:airway];
		}
	}];
	
	return airways;
}

- (NSArray<Airways *> *)airwaysWithDest:(NSString *)ident
{
	RRAirwaysDatabase *receiver = self;
	__block NSMutableArray<Airways *> *airways = [NSMutableArray array];
	[receiver.queue inDatabase:^(FMDatabase *database) {
		NSString *searchQuery = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE `dest` = ? ORDER BY `sequence` ASC", RRAirwaysTableName];
		FMResultSet *resultSet = [database executeQuery:searchQuery, ident];
		
		while ([resultSet next]) {
			Airways *airway = [RRAirwaysDatabase airwayFromResultSet:resultSet];
			[airways addObject:airway];
		}
	}];
	
	return airways;
}

+ (Airways *)airwayFromResultSet:(FMResultSet *)resultSet
{
   Airways *airway = [Airways new];
	
   airway.dest = [resultSet stringForColumn:@"dest"];
   airway.desturn = [resultSet stringForColumn:@"desturn"];
   airway.ident = [resultSet stringForColumn:@"ident"];
   airway.sequence = @([resultSet intForColumn:@"sequence"]);
   airway.source = [resultSet stringForColumn:@"source"];
   airway.srcurn = [resultSet stringForColumn:@"srcurn"];
   airway.state = [resultSet stringForColumn:@"state"];

   return airway;
}

@end
