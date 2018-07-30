//
//  RRMBTileFileReader.m
//  RocketRoute
//
//  Created by Dmytro Yaropovetsky on 4/30/18.
//  Copyright © 2018 Rocket Route. All rights reserved.
//

#import "RRMBTileFileReader.h"
//#import "RRAdditions.h"
#import <FMDB.h>


#define RR_VALUE @"value"
#define RR_NAME @"name"
#define RR_ZOOM_LEVEL @"zoom_level"
#define RR_TILE_COLUMN @"tile_column"
#define RR_TILE_ROW @"tile_row"
#define RR_TILE_DATA @"tile_data"

NSString * const RRMBTileMetadataProfileKey = @"profile";
NSString * const RRMBTileMetadataScaleKey = @"scale";
NSString * const RRMBTileMetadataDescriptionKey = @"description";
NSString * const RRMBTileMetadataFormatKey = @"format";
NSString * const RRMBTileMetadataBoundsKey = @"bounds";
NSString * const RRMBTileMetadataMinZoomKey = @"minzoom";
NSString * const RRMBTileMetadataVersionKey = @"version";
NSString * const RRMBTileMetadataMaxZoomKey = @"maxzoom";
NSString * const RRMBTileMetadataTypeKey = @"type";
NSString * const RRMBTileMetadataNameKey = @"name";


@implementation FMDatabase (FetchConvenience)

- (BOOL)executeFetch:(NSString *)sqlStatement withParameters:(NSDictionary * _Nullable)parameters resultsIterator:(void(^)(FMResultSet *resultSet))resultsIterator {
	FMResultSet *resultSet = [self executeQuery:sqlStatement withParameterDictionary:parameters];
	
	if (!resultSet) {
		int lastErrorCode = self.lastErrorCode;
		NSString *lastErrorMessage = self.lastErrorMessage;
		NSLog(@"Failed to execute SQL statement: %@\n%@ (%d)", sqlStatement, lastErrorMessage, lastErrorCode);
		
		return NO;
	}
	
	while ([resultSet next]) {
		resultsIterator(resultSet);
	}
	
	[resultSet close];
	
	return YES;
}

@end


@interface RRMBTileFileReader ()

@property (nonatomic, strong) FMDatabaseQueue *queue;

@end

@implementation RRMBTileFileReader

- (instancetype)initWithFilePath:(NSString *)filePath {
	self = [super init];
	if (self) {
		self.queue = [FMDatabaseQueue databaseQueueWithPath:filePath];
	}
	return self;
}

- (NSDictionary<NSString *, NSString *> *)metadata {
	NSMutableDictionary * __block metadata = nil;
	
	[self inDatabase:^(FMDatabase *database) {
		metadata = [NSMutableDictionary new];
		
		[database executeFetch:@"SELECT "RR_NAME", "RR_VALUE" FROM metadata;"
				withParameters:nil
			   resultsIterator:^(FMResultSet *resultSet) {
				   NSString *name = [resultSet stringForColumn:RR_NAME];
				   NSString *value = [resultSet stringForColumn:RR_VALUE];
				   
				   if (name) {
					   metadata[name] = value ?: [NSNull null];
				   }
			   }];
	}];
	
	return metadata;
}

- (BOOL)fixMetadataBoundsFormat {
	return [self editMetadataForField:@"bounds"
							editBlock:^(NSString * __autoreleasing *value) {
								NSArray<NSString *> *tokens = [*value componentsSeparatedByString:@","];
								tokens = [tokens valueForKey:@"trimmWhitespaces"];
								*value = [tokens componentsJoinedByString:@","];
							}];
}

- (BOOL)editMetadataForField:(NSString *)fieldName editBlock:(void(^)(NSString **value))editBlock {
	__block BOOL succeeded = NO;
	
	[self inDatabase:^(FMDatabase *database) {
		[database beginTransaction];
		
		NSString * __block value = nil;
		[database executeFetch:@"SELECT "RR_VALUE" FROM metadata WHERE "RR_NAME" = :name;"
				withParameters:@{@"name" : fieldName}
			   resultsIterator:^(FMResultSet *resultSet) {
				   value = [resultSet stringForColumn:RR_VALUE];
			   }];
		
		if ([value isEqual:[NSNull null]]) {
			value = nil;
		}
		
		NSString *original = value;
		editBlock(&value);
		
		if ([value isEqual:[NSNull null]]) {
			value = nil;
		}
		
		if (original != value) {
			succeeded = [database executeUpdate:@"UPDATE metadata SET "RR_VALUE" = :value WHERE "RR_NAME" = :name;"
						withParameterDictionary:@{@"value" : value ?: [NSNull null],
												  @"name" : fieldName}];
		}
		
		[database commit];
	}];
	
	return succeeded;
}

- (NSData *)dataForTileAtZoomLevel:(int)zoomLevel column:(int)column row:(int)row {
	NSData * __block tileData = nil;
	
	[self inDatabase:^(FMDatabase *database) {
		NSDictionary<NSString *, NSNumber *> *parameters = @{@"level" : @(zoomLevel), @"column" : @(column), @"row" : @(row)};
		
		[database executeFetch:@"SELECT "RR_TILE_DATA" FROM tiles WHERE "RR_ZOOM_LEVEL" = :level AND "RR_TILE_COLUMN" = :column AND "RR_TILE_ROW" = :row;"
				withParameters:parameters
			   resultsIterator:^(FMResultSet *resultSet) {
				   NSAssert(!tileData, @"second tile found for parameters: %@", parameters);
				   tileData = [resultSet dataForColumn:RR_TILE_DATA];
			   }];
	}];
	
	return tileData;
}

- (void)inDatabase:(void (^)(FMDatabase *db))block {
	
	[self.queue inDatabase:^(FMDatabase *database) {
#ifdef DEBUG
		database.logsErrors = YES;
		database.crashOnErrors = YES;
#else
		database.logsErrors = NO;
#endif
		block(database);
	}];
}

@end
