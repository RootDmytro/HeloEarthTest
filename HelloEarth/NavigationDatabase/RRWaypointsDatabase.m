//
//  RRWaypointsDatabase.m
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 18.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import "RRWaypointsDatabase.h"
#import "RRKitUtils.h"
#import "RRLocationFormatter.h"
#import <FMDB.h>
#import <sqlite3.h>

#define ENABLE_VRP 0

typedef void(^RRSqliteFunctionBlock)(void * context, int argc, void ** argv);

@interface RRWaypointsDatabase ()

@property (nonatomic, copy, readonly) RRSqliteFunctionBlock locationDistanceFunction;
@property (nonatomic, copy, readonly) RRSqliteFunctionBlock waypointPriorityFunction;

@end

@implementation RRWaypointsDatabase

NSString *RRWaypointsTableName = @"waypoints";
NSString *RRWaypointsVRPTableName = @"vrp_points";

+ (instancetype)sharedInstance {
	static dispatch_once_t once;
	static RRWaypointsDatabase * instance;
	dispatch_once(&once, ^{
		NSAssert(PathToResourceNamed(@"waypoints.sqlite", ^(NSString *path) {
			instance = [[RRWaypointsDatabase alloc] initWithDBPath:path];
		}), @"Could not open waypoints.sqlite");
	});

	return instance;
}

+ (instancetype)sharedVRP {
    static dispatch_once_t once;
    static RRWaypointsDatabase * instance;
	dispatch_once(&once, ^{
		NSAssert(PathToResourceNamed(@"vrp_points.sqlite", ^(NSString *path) {
			instance = [[RRWaypointsDatabase alloc] initWithDBPath:path];
		}), @"Could not open waypoints.sqlite");
    });
    
    return instance;
}

- (RRSqliteFunctionBlock)locationDistanceFunction {
	RRSqliteFunctionBlock function = ^(void * context, int argc, void ** argv) {
		if (argc != 4) {
			NSLog(@"Wrong parameter count for the custom SQLite function.");
			sqlite3_result_null(context);
		} else {
			double firstLat = sqlite3_value_double(argv[0]);
			double firstLon = sqlite3_value_double(argv[1]);
			double secondLat = sqlite3_value_double(argv[2]);
			double secondLon = sqlite3_value_double(argv[3]);
			
			CLLocation * first = [[CLLocation alloc] initWithLatitude:firstLat longitude:firstLon];
			CLLocation * second = [[CLLocation alloc] initWithLatitude:secondLat longitude:secondLon];
			
			sqlite3_result_double(context, [first distanceFromLocation:second]);
		}
	};
	return function;
}

- (RRSqliteFunctionBlock) waypointPriorityFunction {
    __weak typeof (self) myself = self;
	RRSqliteFunctionBlock function = ^(void * context, int argc, void ** argv) {
		if (argc != 1) {
			NSLog(@"Wrong parameter count for the custom SQLite function.");
			sqlite3_result_null(context);
		} else {
			const unsigned char * waypointType = sqlite3_value_text(argv[0]);
            NSString * waypointTypeString = [NSString stringWithFormat:@"%s", waypointType];
			
            NSUInteger idx = [myself.sortedWaypointTypes indexOfObject:waypointTypeString];
            if (idx == NSNotFound) {
                NSLog(@"Skip waypoint type : %@", waypointTypeString);
            }
			
			sqlite3_result_int(context, (int)idx);
		}
	};
    return function;
}

- (Waypoints *)waypointWithUrnFromSQLite:(NSString *)urn {
	__block Waypoints * waypoint;
	[self.queue inDatabase:^(FMDatabase * database) {
		NSString * sqlStatement = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE urn=\'%@\'", RRWaypointsTableName, urn];

		// Search for the waypoint
		FMResultSet * resultSet = [database executeQuery:sqlStatement];

		BOOL found = [resultSet next];
		//       NSAssert(found, @"Waypoint not found");
		if (found) {
			waypoint = [RRWaypointsDatabase waypointFromResultSet:resultSet];
		} else {
			// TODO:Remove after tests!!!
			waypoint = nil;
		}
		[resultSet close];
	}];

	return waypoint;
}

- (Waypoints *)waypointWithURN:(NSString *)urn {
    Waypoints *waypoint = [self waypointWithUrnFromSQLite:urn];
    return waypoint;
}

- (NSArray<Waypoints *> *)waypointsFromSQLiteWithIdent:(NSString *)ident {
    NSString *sqlRequest = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE ident=?", RRWaypointsTableName];
    return [self waypointsWithSQLRequest:sqlRequest argument:ident];
}

- (NSArray<Waypoints *> *)VRPointsFromSQLiteWithName:(NSString *)name {
	NSString *sqlRequest = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE name=?", RRWaypointsVRPTableName];
	return [self VRPointsWithSQLRequest:sqlRequest argument:name];
}

- (NSArray<Waypoints *> *)VRPointsWithSQLRequest:(NSString *)sqlRequest argument:(NSString *)argument {
	// Fetch all waypoints
	__block NSMutableArray * waypoints = [NSMutableArray array];
	
	[self.queue inDatabase:^(FMDatabase * database) {
		
		// Search for the waypoint
		FMResultSet * resultSet = [database executeQuery:sqlRequest, argument];
		
		while ([resultSet next]) {
			Waypoints * waypoint = [RRWaypointsDatabase VRPointsFromResultSet:resultSet];
			[waypoints addObject:waypoint];
		}
		[resultSet close];
	}];
	
	return waypoints;
}

- (NSArray<Waypoints *> *)waypointsWithSQLRequest:(NSString *)sqlRequest argument:(NSString *)argument {
    // Fetch all waypoints
    __block NSMutableArray * waypoints = [NSMutableArray array];
    
    [self.queue inDatabase:^(FMDatabase * database) {
        
        // Search for the waypoint
        FMResultSet * resultSet = [database executeQuery:sqlRequest, argument];
        
        while ([resultSet next]) {
            Waypoints * waypoint = [RRWaypointsDatabase waypointFromResultSet:resultSet];
            [waypoints addObject:waypoint];
        }
        [resultSet close];
    }];
    
    return waypoints;
}

- (NSArray<Waypoints *> *)waypointsWithIdent:(NSString *)ident {
    NSArray<Waypoints *> *waypoints = @[];
	if (![ident hasPrefix:@"\""] && ![ident hasPrefix:@"\'"]) {
		waypoints = [self waypointsFromSQLiteWithIdent:ident];
    }
#if ENABLE_VRP
	if (!waypoints.count) {
		ident = [ident stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"'"]];
		waypoints = [[RRWaypointsDatabase sharedVRP] VRPointsFromSQLiteWithName:ident];
	}
#endif
	return waypoints;
}

- (Waypoints *)defaultWaypointFromCoordinate:(CLLocationCoordinate2D)location {
	NSString * waypointName = [RRLocationFormatter formattedLocationFromCoordinate:location];
	Waypoints * waypoint = [Waypoints new];
	waypoint.latitude = @(location.latitude);
	waypoint.lon = @(location.longitude);
	waypoint.name = waypointName;
	waypoint.type = @"DPN";
	waypoint.ident = waypointName;
	return waypoint;
}

- (Waypoints *)anyWaypointAtLocation:(CLLocationCoordinate2D)location {
	Waypoints * waypoint = [[self waypointsAtLocation:location] firstObject];
	if (!waypoint) {
		waypoint = [self defaultWaypointFromCoordinate:location];
	}
	return waypoint;
}

- (BOOL)is5LNCComplaintWaypoint:(Waypoints *)waypoint {
	BOOL is5LNC = NO;
	NSString * name = waypoint.ident;
	BOOL containsNumbers = [name rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound;
	if (!containsNumbers/* && [name length] != 4 */) {
		is5LNC = YES;
	}
	return is5LNC;
}

static NSArray * _sortedWaypointTypes;

- (NSArray *)sortedWaypointTypes {
    if (!_sortedWaypointTypes) {
        _sortedWaypointTypes = @[@"TACAN", @"VORTAC", @"VOR", @"DPN", @"NDB"];
    }
    return _sortedWaypointTypes;
}

- (NSSortDescriptor *)priorityDescriptor {
	NSSortDescriptor * descriptor =
		[[NSSortDescriptor alloc] initWithKey:@"type"
									ascending:YES
								   comparator:^NSComparisonResult(id obj1, id obj2) {
									   NSInteger firstPriority = [self.sortedWaypointTypes indexOfObject:obj1];
									   NSInteger secondPriority = [self.sortedWaypointTypes indexOfObject:obj2];
									   return [@(firstPriority) compare:@(secondPriority)];
								   }];
	return descriptor;
}

- (NSSortDescriptor *)distanceDescriptorWithLocation:(CLLocation *)location {
	NSSortDescriptor * descriptor =
		[[NSSortDescriptor alloc] initWithKey:@"location"
									ascending:YES
								   comparator:^NSComparisonResult(CLLocation * obj1, CLLocation * obj2) {
									   CLLocationDistance distance1 = [location distanceFromLocation:obj1];
									   CLLocationDistance distance2 = [location distanceFromLocation:obj2];
									   return [@(distance1) compare:@(distance2)];
								   }];
	return descriptor;
}

- (Waypoints *)waypointWithCoordinate:(CLLocationCoordinate2D)coordinate snapRadius:(CLLocationDegrees)radius {
	NSMutableArray * waypoints = @[].mutableCopy;
	
	__weak typeof(self) myself = self;
	CLLocationBounds bounds = [RRKitUtils boundsWithCenter:coordinate radius:radius];
	
	[self.queue inDatabase:^(FMDatabase *db) {
		[db makeFunctionNamed:@"LocationDistance"
			 maximumArguments:4
					withBlock:myself.locationDistanceFunction];
		
		NSString * selectQuery = @"SELECT * FROM waypoints WHERE latitude < ? AND latitude > ? AND lon < ? AND lon > ? "
		@"AND type IN ('TACAN', 'VORTAC', 'VOR', 'DPN', 'NDB') "
		@"ORDER BY LocationDistance(latitude, lon, ?, ?) ASC";
		FMResultSet * rs = [db executeQuery:selectQuery, @(bounds.bottomRight.latitude), @(bounds.topLeft.latitude), @(bounds.bottomRight.longitude), @(bounds.topLeft.longitude), @(coordinate.latitude), @(coordinate.longitude)];
		
		while ([rs next]) {
			Waypoints * waypoint = [myself.class waypointFromResultSet:rs];
			BOOL shallSkip = (![myself is5LNCComplaintWaypoint:waypoint]);
			if (waypoint && !shallSkip) {
				[waypoints addObject:waypoint];
			}
		}
	}];
	return [waypoints firstObject];
}

- (NSArray<Waypoints *> *)waypointsWithCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSUInteger)limit {
	NSMutableArray<Waypoints *> * waypoints = @[].mutableCopy;
	
	__weak typeof(self) myself = self;
	
	[self.queue inDatabase:^(FMDatabase *db) {
		[db makeFunctionNamed:@"LocationDistance"
			 maximumArguments:4
					withBlock:myself.locationDistanceFunction];
		
		NSString * selectQuery = @"SELECT * FROM waypoints "
		@"ORDER BY LocationDistance(latitude, lon, ?, ?) ASC "
		@"LIMIT ?";
		FMResultSet *rs = [db executeQuery:selectQuery, @(coordinate.latitude), @(coordinate.longitude), @(limit)];
		
		while ([rs next]) {
			Waypoints * waypoint = [myself.class waypointFromResultSet:rs];
			BOOL shallSkip = (![myself is5LNCComplaintWaypoint:waypoint]);
			if (waypoint && !shallSkip) {
				[waypoints addObject:waypoint];
			}
		}
	}];
	return waypoints;
}

- (NSArray *)waypointsAtLocation:(CLLocationCoordinate2D)coordinate {
	NSMutableArray * waypoints = @[].mutableCopy;
	__weak typeof(self) myself = self;
	CLLocationDegrees kDefaultWaypointsSearchDelta = .25;
	CLLocationDegrees minLat = coordinate.latitude - kDefaultWaypointsSearchDelta;
	CLLocationDegrees maxLat = coordinate.latitude + kDefaultWaypointsSearchDelta;
	CLLocationDegrees minLon = coordinate.longitude - kDefaultWaypointsSearchDelta;
	CLLocationDegrees maxLon = coordinate.longitude + kDefaultWaypointsSearchDelta;
	[self.queue inDatabase:^(FMDatabase * db) {
		db.logsErrors = YES;
		db.traceExecution = NO;
		
        [db makeFunctionNamed:@"LocationDistance" maximumArguments:4 withBlock:myself.locationDistanceFunction];
        [db makeFunctionNamed:@"TypePriority" maximumArguments:1 withBlock:myself.waypointPriorityFunction];
		NSString * searchQuery = [NSString
			stringWithFormat:@"SELECT * FROM %@ WHERE (latitude > ?) AND (latitude < ?) AND (lon > ?) AND (lon < ?) "
				@"AND type IN ('TACAN', 'VORTAC', 'VOR', 'DPN', 'NDB') "
				@"ORDER BY TypePriority(type) ASC, LocationDistance(latitude, lon, ?, ?) ASC",
							 RRWaypointsTableName];
		FMResultSet * rs = [db executeQuery:searchQuery, @(minLat), @(maxLat), @(minLon), @(maxLon), @(coordinate.latitude), @(coordinate.longitude)];

		while ([rs next]) {
			Waypoints * waypoint = [myself.class waypointFromResultSet:rs];
			BOOL shallSkip = (![myself is5LNCComplaintWaypoint:waypoint]);
			if (waypoint && !shallSkip) {
				[waypoints addObject:waypoint];
			}

		}
	}];
//	CLLocation * location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
//	NSArray * sortedByPriority = [waypoints
//		sortedArrayUsingDescriptors:@[[self priorityDescriptor], [self distanceDescriptorWithLocation:location]]];
	return waypoints;
}

+ (Waypoints *)waypointFromResultSet:(FMResultSet *)resultSet {
	Waypoints * waypoint = [Waypoints new];
	
	waypoint.freq = [resultSet stringForColumn:@"freq"];
	waypoint.ident = [resultSet stringForColumn:@"ident"];
	waypoint.latitude = @([resultSet doubleForColumn:@"latitude"]);
	waypoint.lon = @([resultSet doubleForColumn:@"lon"]);
	waypoint.name = [resultSet stringForColumn:@"name"];
	waypoint.rowid = @([resultSet intForColumn:@"rowid"]);
	waypoint.state = [resultSet stringForColumn:@"state"];
	waypoint.type = [resultSet stringForColumn:@"type"];
	waypoint.urn = [resultSet stringForColumn:@"urn"];
	waypoint.grid = @([resultSet intForColumn:@"grid"]);

	return waypoint;
}

+ (Waypoints *)VRPointsFromResultSet:(FMResultSet *)resultSet {
	Waypoints * waypoint = [Waypoints new];
	
	waypoint.VRP = YES;
	waypoint.rowid = @([resultSet intForColumn:@"id"]);
	waypoint.ident = [resultSet stringForColumn:@"ident"];
	waypoint.icao_coords = [resultSet stringForColumn:@"icao_coords"];
	waypoint.name = [resultSet stringForColumn:@"name"];
	waypoint.long_name = [resultSet stringForColumn:@"long_name"];
	waypoint.icao = [resultSet stringForColumn:@"icao"];
	waypoint.latitude = @([resultSet doubleForColumn:@"lat"]);
	waypoint.lon = @([resultSet doubleForColumn:@"lon"]);
	waypoint.elevation = [resultSet stringForColumn:@"elevation"];
	waypoint.urn = [resultSet stringForColumn:@"urn"] ?: waypoint.icao_coords ?: @"vrp";
	waypoint.grid = @([resultSet intForColumn:@"grid"]);
	
	waypoint.type = @"VRP";
	
	return waypoint;
}

@end
