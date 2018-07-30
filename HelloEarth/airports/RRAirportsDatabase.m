//
//  AirportsDatabase.m
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 19.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import "RRAirportsDatabase.h"
#import "RRKitUtils.h"
#import "NSString+Crypto.h"

#import <sqlite3.h>

static NSString * RRICAOKey = @"icao";
static NSString * RRIATAKey = @"iata";
static NSString * RRNameKey = @"name";

typedef void(^LocationDistanceFunction)(void * context, int argc, void ** argv);


@interface RRDummySqlQuery : NSString
@property (copy, nonatomic) NSString *where, *orderBy;
@property (copy, nonatomic) NSDictionary *whereFields;
@property (nonatomic) NSUInteger limit;
@end

@implementation RRDummySqlQuery


- (instancetype)init
{
	self = [super init];
	if (self) {
		self.limit = NSNotFound;
	}
	return self;
}

- (NSString *)generateSql {
	NSMutableString *query = @"SELECT * FROM airports".mutableCopy;
	
	if (self.where.length > 0) {
		[query appendFormat:@" WHERE %@", self.where];
	}
	
	if (self.orderBy.length > 0) {
		[query appendFormat:@" %@", self.orderBy];
	}
	
	if (self.limit != NSNotFound) {
		[query appendFormat:@" LIMIT %ld", (unsigned long)self.limit];
	}
	
	return query;
}

@end


@interface RRAirportsDatabase ()
@property (copy, nonatomic, readonly) LocationDistanceFunction locationDistanceFunction;
@property (copy, nonatomic, readonly) LocationDistanceFunction regexpFunction;

@property (copy, readonly) NSString *dbPath;
@property (strong, readonly) FMDatabaseQueue *queue;
@end

@implementation RRAirportsDatabase
@synthesize queue = _queue;

+ (instancetype)sharedInstance {
	static id instance;
	
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		NSArray<NSString *> *allOutlines = [[NSBundle mainBundle] pathsForResourcesOfType:@"sqlite" inDirectory:nil];
		
		for (NSString *outlineFile in allOutlines) {
			if ([outlineFile.lastPathComponent isEqualToString:@"airports.sqlite"]) {
				instance = [[self alloc] initWithDBPath:outlineFile];
			}
		}
		NSAssert(instance, @"airports.sqlite was not found");
	});
	
	return instance;
}

- (instancetype)initWithDBPath:(NSString *)dbPath {
	self = [super init];
	if (self) {
		_dbPath = dbPath;
		_locationDistanceFunction = [self createLocationDistanceFunction];
		_regexpFunction = [self createRegexpFunction];
		
		[self.queue inDatabase:^(FMDatabase * db) {
			[db makeFunctionNamed:@"LocationDistance"
				 maximumArguments:4
						withBlock:self.locationDistanceFunction];
			[db makeFunctionNamed:@"regex"
				 maximumArguments:2
						withBlock:self.regexpFunction];
		}];
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

- (LocationDistanceFunction)createLocationDistanceFunction {
	LocationDistanceFunction function = ^(void * context, int argc, void ** argv) {
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

- (LocationDistanceFunction)createRegexpFunction {
	LocationDistanceFunction function = ^(void * context, int argc, void ** argv) {
		if (argc != 2) {
			NSLog(@"Wrong parameter count for the custom SQLite function.");
			sqlite3_result_null(context);
		} else {
			const char *str = (const char *)sqlite3_value_text(argv[0]);
			const char *patt = (const char *)sqlite3_value_text(argv[1]);
			NSString *string = [NSString stringWithUTF8String:str];
			NSString *pattern = [NSString stringWithUTF8String:patt];
			
			NSError *error = nil;
			NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
			NSUInteger count = [regex numberOfMatchesInString:string options:kNilOptions range:string.fullRange];
			if (error) {
				NSLog(@"RegexpFunction: Error: %@", error);
			}
			
			sqlite3_result_int(context, count > 0);
		}
	};
	return function;
}

#pragma mark - Public

- (NSDictionary<NSString *, RRAirport *> *)airportsWithICAO:(NSSet *)icaoSet orNamesSet:(NSSet *)namesSet {
    __block NSMutableDictionary<NSString *, RRAirport *> * airports = NSMutableDictionary.new;
    
    BOOL searchIcao = icaoSet != nil;
    
    NSString *identString = @"";
    for (NSString *icao in searchIcao ? icaoSet : namesSet) {
        if (icao.length > 0) {
            identString = [identString stringByAppendingFormat:@", \'%@\'", icao];
        }
    }
    if ([identString hasPrefix:@", "]) {
        identString = [identString substringFromIndex:2];
    }
    
    [self.queue inDatabase:^(FMDatabase * database) {
        database.logsErrors = YES;
        database.traceExecution = NO;
        
        NSString *sqlStatement;
        if (searchIcao) {
            sqlStatement = [NSString stringWithFormat:@"SELECT * FROM airports WHERE icao IN (%@)", identString];
        } else {
            sqlStatement = [NSString stringWithFormat:@"SELECT * FROM airports WHERE name IN (%@) OR alt_name IN (%@)", identString, identString];
        }
        
        FMResultSet *resultSet = [database executeQuery:sqlStatement];
        if (!resultSet) {
            int lastErrorCode = database.lastErrorCode;
            NSString * lastErrorMessage = database.lastErrorMessage;
            
            NSLog(@"Failed to execute SQL statement: %@\n%@ (%d)", sqlStatement, lastErrorMessage, lastErrorCode);
        }
        
        while ([resultSet next]) {
            RRAirport *airport = [RRAirportsDatabase airportFromResultSet:resultSet];
            if (searchIcao) {
                airports[airport.icao] = airport;
            } else {
                airports[airport.name ?: airport.alt_name] = airport;
            }
        }
        
        [resultSet close];
    }];
    
    return airports;
}

- (RRAirport *)airportWithICAO:(NSString *)icao {
	__block RRAirport * airport;

	if (!icao || [icao isEqualToString:@""] || [icao isEqual:[NSNull null]]) {
		return nil;
	}

	[self.queue inDatabase:^(FMDatabase * database) {
		database.logsErrors = YES;
		database.traceExecution = NO;
		
		NSString * sqlStatement =
			[NSString stringWithFormat:@"SELECT * FROM %@ WHERE icao=\'%@\' LIMIT 1", @"airports", icao];
		
		FMResultSet * resultSet = [database executeQuery:sqlStatement];
		if (!resultSet) {
			int lastErrorCode = database.lastErrorCode;
			NSString * lastErrorMessage = database.lastErrorMessage;
			
			NSLog(@"Failed to execute SQL statement: %@\n%@ (%d)", sqlStatement, lastErrorMessage, lastErrorCode);
		}
		
		if ([resultSet next]) {
			airport = [RRAirportsDatabase airportFromResultSet:resultSet];
		}
		
		[resultSet close];
	}];

	return airport;
}

- (RRAirport *)airportWithIATA:(NSString *)iata {
	__block RRAirport * airport = nil;
	
	[self.queue inDatabase:^(FMDatabase * database) {
		NSString * sqlStatement =
			[NSString stringWithFormat:@"SELECT * FROM %@ WHERE iata=\'%@\' LIMIT 1", @"airports", iata];
		
		FMResultSet * resultSet = [database executeQuery:sqlStatement];
		if (!resultSet) {
			int lastErrorCode = database.lastErrorCode;
			NSString * lastErrorMessage = database.lastErrorMessage;
			NSAssert3(resultSet, @"Failed to execute SQL statement: %@\n%@ (%d)", sqlStatement, lastErrorMessage,
					  lastErrorCode);
			if (lastErrorMessage) {
				NSLog(@"Failed to execute SQL statement: %@\n%@ (%d)", sqlStatement, lastErrorMessage, lastErrorCode);
			}
		}
		
		if ([resultSet next]) {
			airport = [RRAirportsDatabase airportFromResultSet:resultSet];
		}
		
		[resultSet close];
	}];

	return airport;
}

- (RRAirport *)airportWithId:(NSString *)airportId {
    __block RRAirport * airport = nil;
    
    [self.queue inDatabase:^(FMDatabase * database) {
        NSString * sqlStatement =
        [NSString stringWithFormat:@"SELECT * FROM %@ WHERE rowid=\'%@\' LIMIT 1", @"airports", airportId];
        
        FMResultSet * resultSet = [database executeQuery:sqlStatement];
        if (!resultSet) {
            int lastErrorCode = database.lastErrorCode;
            NSString * lastErrorMessage = database.lastErrorMessage;
            NSAssert3(resultSet, @"Failed to execute SQL statement: %@\n%@ (%d)", sqlStatement, lastErrorMessage,
                      lastErrorCode);
            if (lastErrorMessage) {
                NSLog(@"Failed to execute SQL statement: %@\n%@ (%d)", sqlStatement, lastErrorMessage, lastErrorCode);
            }
        }
        
        if ([resultSet next]) {
            airport = [RRAirportsDatabase airportFromResultSet:resultSet];
        }
        
        [resultSet close];
    }];
    
    return airport;
}

- (RRAirport *)nearestAirportAtLocation:(CLLocation *)location
			  withinMetersSearchRadius:(CLLocationDistance)radius
							  icaoOnly:(BOOL)icaoOnly {
	NSString * query;
	if (icaoOnly) {
		query = @"SELECT * FROM airports WHERE latitude < ? AND latitude > ? AND lon < ? AND lon > ? "
		@"AND icao IS NOT NULL AND icao <> 'ZZZZ'"
		@"ORDER BY LocationDistance(latitude, lon, ?, ?) ASC";
	} else {
		query = @"SELECT * FROM airports WHERE latitude < ? AND latitude > ? AND lon < ? AND lon > ? "
        @"ORDER BY LocationDistance(latitude, lon, ?, ?) ASC";
	}
	
    return [self firstAirportWithQuery:query atLocation:location withinMetersSearchRadius:radius icaoOnly:icaoOnly];
}

- (RRAirport *)firstAirportWithQuery:(NSString *)query atLocation:(CLLocation *)location withinMetersSearchRadius:(CLLocationDistance)searchRadius icaoOnly:(BOOL)icaoOnly {
	__block RRAirport *foundAirport = nil;
	CLLocationCoordinate2D coordinate = location.coordinate;
	
	NSParameterAssert(location);
	NSAssert(CLLocationCoordinate2DIsValid(coordinate), @"Invalid location coordinate");
	
	CLLocationBounds bounds = [RRKitUtils boundsWithCenter:coordinate radius:searchRadius];
	
	[self.queue inDatabase:^(FMDatabase * db) {
		NSString * selectQuery = query;
		FMResultSet * rs = [db executeQuery:selectQuery, @(bounds.bottomRight.latitude), @(bounds.topLeft.latitude), @(bounds.bottomRight.longitude), @(bounds.topLeft.longitude), @(coordinate.latitude), @(coordinate.longitude)];
		
        if (icaoOnly) {
            while ([rs next]) {
                if ([rs stringForColumn:@"icao"].isValidICAOCode) {
                    foundAirport = [RRAirportsDatabase airportFromResultSet:rs];
                    break;
                }
            }
        } else if ([rs next]) {
            foundAirport = [RRAirportsDatabase airportFromResultSet:rs];
        }
	}];
	
	return foundAirport;
}

- (RRAirport *)airportWithName:(NSString *)name {
	NSDictionary *fields = @{@"name": name};
	NSString *selectAirport = @"SELECT * FROM airports WHERE name = (:name) OR alt_name = (:name)";
	
	NSArray *airports = [self performQuery:selectAirport withNamedFields:fields];
	
	if (airports.count == 0) {
		NSArray<NSString *> *tokens = name.splitTokens;
		if (tokens.count > 1) {
			NSString *code = tokens.firstObject;
			if (code.isValidAirportCode) {
				name = [name substringFromIndex:NSMaxRange([name rangeOfString:code]) + 1].trimmWhitespaces;
				fields = @{@"name": name};
				airports = [self performQuery:selectAirport withNamedFields:fields];
				
				if (airports.count == 0) {
					fields = @{@"icao": code};
					selectAirport = @"SELECT * FROM airports WHERE icao = (:icao)";
					airports = [self performQuery:selectAirport withNamedFields:fields];
				}
			}
		}
	}
	
	return airports.firstObject;
}

- (RRAirport *)airportWithName:(NSString *)name location:(CLLocationCoordinate2D)location {
	NSDictionary *fields = @{@"name": name};
	NSString *selectAirport = @"SELECT * FROM airports WHERE name = (:name)";
	
	NSArray *airports = [self performQuery:selectAirport withNamedFields:fields];
	
	airports = [self filterAirports:airports closeToLocation:location inDistance:RRMetersFromNauticalMiles(1.0)];
	
	return airports.firstObject;
}

- (RRAirport *)airportWithName:(NSString *)name location:(CLLocationCoordinate2D)location icao:(NSString *)icao {
	NSDictionary *fields = @{@"name": name, @"icao": icao};
	NSString *selectAirport = @"SELECT * FROM airports WHERE icao = (:icao) AND name = (:name)";
	
	NSArray<RRAirport *> *airports = [self performQuery:selectAirport withNamedFields:fields];
	// INFO: However we need to check the coordinate of the airport, to ensure, that it is exactly the same place we're looking for.
	airports = [self filterAirports:airports closeToLocation:location inDistance:RRMetersFromNauticalMiles(1.0)];
	
	return airports.firstObject;
}

- (NSArray<RRAirport *> *)performQuery:(NSString *)query withNamedFields:(NSDictionary *)fields {
	__block NSMutableArray *airports = NSMutableArray.new;
	
	[self.queue inDatabase:^(FMDatabase * db) {
		FMResultSet * rs = [db executeQuery:query withParameterDictionary:fields];
		
		while ([rs next]) {
			[airports addObject:[RRAirportsDatabase airportFromResultSet:rs]];
		}
	}];
	
	return airports;
}

- (NSArray<RRAirport *> *)filterAirports:(NSArray *)airports closeToLocation:(CLLocationCoordinate2D)location inDistance:(double)distance {
	NSAssert(CLLocationCoordinate2DIsValid(location), @"invalid location coordinate");
	
	__block NSMutableArray *filteredAirports = NSMutableArray.new;
	CLLocation * expectedLocation = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
	
	for (RRAirport *airport in airports) {
		CLLocation * airportLocation = [[CLLocation alloc] initWithLatitude:airport.latitude.doubleValue longitude:airport.lon.doubleValue];
		
		if ([airportLocation distanceFromLocation:expectedLocation] <= distance) {
			[filteredAirports addObject:airport];
		}
	}
	
	return filteredAirports;
}

#pragma mark - Method argument binding

- (NSArray<RRAirport *> *)filteredAirportsWithTerm:(NSString *)term limit:(NSUInteger)limit {
	return [self filteredAirportsWithTerm:term nearestToCoordinate:kCLLocationCoordinate2DInvalid limit:limit];
}

- (NSArray<RRAirport *> *)filteredIcaoAirportsWithTerm:(NSString *)term limit:(NSUInteger)limit {
	return [self filteredIcaoAirportsWithTerm:term nearestToCoordinate:kCLLocationCoordinate2DInvalid limit:limit];
}

- (NSArray<RRAirport *> *)filteredAirportsWithTerm:(NSString *)term nearestToCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSUInteger)limit {
	return [self filteredAirportsWithTerm:term andWhereCondition:nil nearestToCoordinate:coordinate limit:limit];
}

- (NSArray<RRAirport *> *)filteredIcaoAirportsWithTerm:(NSString *)term nearestToCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSUInteger)limit {
	return [self filteredAirportsWithTerm:term andWhereCondition:@"length(icao) == 4" nearestToCoordinate:coordinate limit:limit];
}

#pragma mark - Filtering

- (NSArray<RRAirport *> *)filteredAirportsWithTerm:(NSString *)term andWhereCondition:(nullable NSString *)whereCondition nearestToCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSUInteger)limit {
	NSArray *airports = nil;
	RRDummySqlQuery *select = [self selectQueryMatchingAirportsWithTerm:term nearestToCoordinate:coordinate];
	
	if (select != nil) {
		select.limit = limit;
		
		if (whereCondition.length > 0) {
			select.where = [NSString stringWithFormat:@"(%@) AND (%@)", whereCondition, select.where];
		}
		
		NSString *query = [select generateSql];
		airports = [self performQuery:query withNamedFields:select.whereFields];
	}
	
	return airports;
}

- (nullable RRDummySqlQuery *)selectQueryMatchingAirportsWithTerm:(NSString *)term nearestToCoordinate:(CLLocationCoordinate2D)coordinate {
	RRDummySqlQuery *select = nil;
	
	term = [term stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    
    static const NSUInteger minCodeLength   = 2;
    static const NSUInteger iataCodeLength  = 3;
    static const NSUInteger icaoCodeLength  = 4;
	
	if (term.length >= minCodeLength) {
		term = term.uppercaseString;
		
		NSDictionary *whereFields = nil;
		NSString * orderBy = nil, *where = nil;
		
		NSString *beginsWithTerm = [term stringByAppendingString:@"%"];
		NSString *wordInSentenceBeginsWithTerm = [NSString stringWithFormat:@"%% %@%%", term];
		NSString *locationSortCondition = CLLocationCoordinate2DIsValid(coordinate) ? [NSString stringWithFormat:@" LocationDistance(`latitude`, `lon`, %f, %f) ASC,", coordinate.latitude, coordinate.longitude] : @"";
		
		if (term.length <= iataCodeLength) {
			where = @"name LIKE :name OR icao LIKE :icao OR iata LIKE :iata";
			whereFields = @{@"iata": beginsWithTerm, @"icao": beginsWithTerm, @"name": beginsWithTerm, @"word": wordInSentenceBeginsWithTerm, @"match": term};
			
			orderBy = [NSString stringWithFormat:@"ORDER BY iata LIKE :iata DESC, name LIKE :match DESC, %@ "
					   "CASE "
					   "WHEN length(icao) IS %ld AND type is 'L' THEN 10 "
					   "WHEN length(icao) IS %ld AND type is 'M' THEN 11 "
					   "WHEN length(icao) IS %ld AND type is 'S' THEN 12 "
					   "WHEN length(icao) IS %ld THEN 13 "
					   "WHEN length(iata) IS %ld THEN 20 "
					   "ELSE 30 END, "
					   
					   "CASE "
					   "WHEN iata LIKE :iata THEN iata "
					   "WHEN icao LIKE :icao THEN icao "
					   "ELSE name END, "
					   "icao, iata, name",
					   locationSortCondition,
					   
					   (unsigned long)icaoCodeLength,
					   (unsigned long)icaoCodeLength,
					   (unsigned long)icaoCodeLength,
					   (unsigned long)icaoCodeLength,
					   
					   (unsigned long)iataCodeLength];
			
		} else if (term.length == icaoCodeLength) {
			where = @"icao = :icao OR name LIKE :word OR name LIKE :name";
			whereFields = @{@"icao": term, @"name": beginsWithTerm, @"word": wordInSentenceBeginsWithTerm, @"match": term};
			
			orderBy = [NSString stringWithFormat:@"ORDER BY name LIKE :match DESC, %@ CASE "
					   "when icao is :icao then 0 "
					   
					   "WHEN length(icao) IS %ld AND type is 'L' THEN 10 "
					   "WHEN length(icao) IS %ld AND type is 'M' THEN 11 "
					   "WHEN length(icao) IS %ld AND type is 'S' THEN 12 "
					   "WHEN length(icao) IS %ld THEN 13 "
					   
					   "ELSE 20 END, "
					   "icao, iata, name",
					   locationSortCondition,
					   
					   (unsigned long)icaoCodeLength,
					   (unsigned long)icaoCodeLength,
					   (unsigned long)icaoCodeLength,
					   (unsigned long)icaoCodeLength];
			
		} else {
			where = @"name LIKE :word OR name LIKE :name";
			whereFields = @{@"name": beginsWithTerm, @"word" : wordInSentenceBeginsWithTerm, @"match": term};
			
			orderBy = [NSString stringWithFormat:@"ORDER BY name LIKE :match DESC, %@ CASE "
					   "WHEN length(icao) IS %ld AND type is 'L' THEN 0 "
					   "WHEN length(icao) IS %ld AND type is 'M' THEN 1 "
					   "WHEN length(icao) IS %ld AND type is 'S' THEN 2 "
					   "WHEN length(iata) IS %ld THEN 3 "
					   
					   "WHEN length(iata) IS %ld THEN 10 "
					   "ELSE 20 END, icao, iata, name",
					   locationSortCondition,
					   
					   (unsigned long)icaoCodeLength,
					   (unsigned long)icaoCodeLength,
					   (unsigned long)icaoCodeLength,
					   (unsigned long)iataCodeLength,
					   
					   (unsigned long)iataCodeLength];
		}
		
		
		select = RRDummySqlQuery.new;
		{
			select.where = where;
			select.orderBy = orderBy;
			select.whereFields = whereFields;
		}
	}
	
	return select;
}

#pragma mark - Internal

+ (RRAirport *)airportFromResultSet:(FMResultSet *)resultSet {
	RRAirport * airport = [RRAirport new];
	
	airport.adescription = [resultSet stringForColumn:@"description"];
	airport.alt_name = [resultSet stringForColumn:@"alt_name"];
	airport.civmil = [resultSet stringForColumn:@"civmil"];
	airport.continent = [resultSet stringForColumn:@"continent"];
	airport.country = [resultSet stringForColumn:@"country"];
	airport.filez = [resultSet stringForColumn:@"filez"];
	airport.iata = [resultSet stringForColumn:@"iata"];
	airport.icao = [resultSet stringForColumn:@"icao"];
	airport.ifr = [resultSet stringForColumn:@"ifr"];
	airport.latitude = @([resultSet doubleForColumn:@"latitude"]);
	airport.elevation = @([resultSet intForColumn:@"elevation"]);
	airport.lon = @([resultSet doubleForColumn:@"lon"]);
	airport.name = [resultSet stringForColumn:@"name"];
	airport.rowid = @([resultSet intForColumn:@"rowid"]);
	airport.type = [resultSet stringForColumn:@"type"];
	airport.airport_of_entry = @([resultSet intForColumn:@"airport_of_entry"]);
	
	int pr = 0;
	pr += [resultSet intForColumn:@"airport_of_entry"];
	pr *= 2;
	pr += [resultSet intForColumn:@"is_ifr"];
	pr *= 2;
	pr += [resultSet intForColumn:@"is_iata"];
	pr *= 2;
	pr += [resultSet intForColumn:@"is_icao"];
	pr *= 2;
	pr += [resultSet intForColumn:@"is_reg"];
	airport.priority = pr / 31.0;
	
	return airport;
}

@end
