//
// Created by Yuriy Levytskyy on 20.02.14.
// Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import <objc/runtime.h>

#import "RRDatabaseObjectBase.h"
#import "RRKitUtils.h"
#import "RRDatabaseBase.h"
#import <FMDB.h>

static const char * getPropertyType(objc_property_t property) {
	const char * attributes = property_getAttributes(property);

	size_t length = strlen(attributes);
	char buffer[1 + length];
	memmove(buffer, attributes, length);
	
	char *state = buffer, *attribute;
	while ((attribute = strsep(&state, ",")) != NULL) {
		if (attribute[0] == 'T' && attribute[1] != '@') {
			// it's a C primitive type:
			/*
			 if you want a list of what will be returned for these primitives, search online for
			 "objective-c" "Property Attribute Description Examples"
			 apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.
			 */
			NSString * name = [[NSString alloc] initWithBytes:attribute + 1
													   length:strlen(attribute) - 1
													 encoding:NSUTF8StringEncoding];
			return name.UTF8String;
		} else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
			// it's an ObjC id type:
			return "id";
		} else if (attribute[0] == 'T' && attribute[1] == '@') {
			// it's another ObjC object type:
			NSString * name = [[NSString alloc] initWithBytes:attribute + 3
													   length:strlen(attribute) - 4
													 encoding:NSUTF8StringEncoding];
			return name.UTF8String;
		}
	}
	return "";
}

@implementation RRDatabaseObjectBase

- (void)setupTableWithKey:(NSString *)key indexedFields:(NSArray *)indexedFields {
	NSString * databasePath = [self databasePath];
	[self createTable:key databasePath:databasePath];

	[self queue];

	[self createIndices:indexedFields];
}

- (NSDictionary *)properties {
	unsigned count = 0;
	objc_property_t * propertyList = class_copyPropertyList([self class], &count);

	NSMutableDictionary * properties = [NSMutableDictionary dictionary];

	for (unsigned i = 0; i < count; i++) {
		objc_property_t property = propertyList[i];
		const char * propertyName = property_getName(property);
		if (propertyName) {
			const char * propertyType = getPropertyType(property);

			NSString * name = [NSString stringWithUTF8String:propertyName];
			NSString * type = [NSString stringWithUTF8String:propertyType];

			properties[name] = type;
		}
	}

	free(propertyList);

	return properties;
}

- (NSString *)createTableCommand:(NSString *)key {
	static NSDictionary * objectiveCToSQLite = nil;
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		objectiveCToSQLite = @{NSStringFromClass([NSString class]): @"TEXT", NSStringFromClass([NSNumber class]): @"INT", NSStringFromClass([NSDate class]): @"TIMESTAMP"};
	});
	
	NSString * entityName = [self entityName];
	NSString * sqlCommand = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@", entityName];

	NSMutableArray * columns = [NSMutableArray array];

	NSDictionary * properties = [self properties];
	for (NSString * name in properties) {
		NSString * type = properties[name];
		type = objectiveCToSQLite[type];
		if (NSOrderedSame == [key caseInsensitiveCompare:name]) {
			type = [NSString stringWithFormat:@"%@ UNIQUE", type];
		}
		NSString * column = [NSString stringWithFormat:@"\'%@\' %@", name, type];

		[columns addObject:column];
	}

	NSString * columnsString = [columns componentsJoinedByString:@", "];
	sqlCommand = [NSString stringWithFormat:@"%@ (%@)", sqlCommand, columnsString];
	return sqlCommand;
}

- (NSString *)entityName {
	NSString * entityName = [RRDatabaseObjectBase entityName:[self class]];
	return entityName;
}

+ (NSString *)entityName:(Class)aClass {
	NSString * entityName = NSStringFromClass(aClass);
	return entityName;
}

- (FMDatabaseQueue *)queue {
	return [RRDatabaseObjectBase queue:[self class]];
}

+ (FMDatabaseQueue *)queue:(Class)aClass {
	static NSMutableDictionary * queues = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		queues = [NSMutableDictionary dictionary];
	});
	
	NSString * entityName = [RRDatabaseObjectBase entityName:aClass];
	FMDatabaseQueue * __block queue = queues[entityName];
	if (!queue) {
		PathToResourceNamed(NSStringFromClass(aClass), ^(NSString *path) {
			queue = [FMDatabaseQueue databaseQueueWithPath:path];
			
			queues[entityName] = queue;
		});
	}
	return queue;
}

- (NSString *)databasePath {
	NSString * __block databasePath;
	NSAssert(PathToResourceNamed([NSStringFromClass(self.class) stringByAppendingPathExtension:@"sqlite"], ^(NSString *path) {
		databasePath = path;
	}), @"could not load db");
	return databasePath;
}

- (BOOL)createTable:(NSString *)key databasePath:(NSString *)databasePath {
	FMDatabase * database = [FMDatabase databaseWithPath:databasePath];

	if (![database open]) {
		NSLog(@"Could not open/create database");
	}
	
	database.traceExecution = NO;

	__block BOOL succeeded = NO;
	NSString * sqlCommand = [self createTableCommand:key];
	[self.queue inDatabase:^(FMDatabase * database) {
		[database beginTransaction];

		succeeded = [database executeUpdate:sqlCommand];
		NSAssert1(succeeded, @"Failed to create database %@", [self entityName]);
		if (!succeeded) {
			NSError * error = [database lastError];
			NSLog(@"Failed to create database %@ : %@", self.entityName, error);
		}

		[database commit];
	}];

	return succeeded;
}

- (void)createIndices:(NSArray *)fields {


	for (NSString * field in fields) {
		NSString * entityName = [self entityName];
		FMDatabaseQueue * queue = [self queue];

		NSString * sqlStatement =
			[NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS RRIndexFor%@ ON %@ (%@)", field, entityName, field];
		[queue inDatabase:^(FMDatabase * database) {
			[database beginTransaction];

			BOOL succeeded = [database executeUpdate:sqlStatement];
			NSAssert(succeeded, @"Failed to update DB object\n%@", sqlStatement);
			if (!succeeded) {
				NSError * error = [database lastError];
				NSLog(@"Failed to update DB object\n%@\n%@", sqlStatement, error);
			}

			[database commit];
		}];
	}
}

+ (NSMutableArray *)objectsForClass:(Class)aClass {


	NSString * sqlStatement = [self sqlSelectStatement:aClass];

	NSMutableArray * objects = [RRDatabaseObjectBase objectsForSqlStatement:sqlStatement andClass:aClass];

	return objects;
}

+ (instancetype)objectForKey:(NSString *)key forValue:(NSString *)value andClass:(Class)aClass searchPrefix:(BOOL)searchPrefix {
    NSString *sqlStatement;
    if (!searchPrefix) {
        sqlStatement = [self sqlSelectStatement:key value:value limit:1 andClass:aClass];
    } else {
        sqlStatement = [self sqlSelectPrefixStatement:key value:value limit:1 andClass:aClass];
    }

	return [RRDatabaseObjectBase objectForSqlStatement:sqlStatement andClass:aClass];
}

- (BOOL)updateObjectForKey:(NSString *)key forValue:(NSString *)value {


	Class aClass = [self class];
	NSString * sqlStatement = [RRDatabaseObjectBase sqlSelectStatement:key value:value limit:1 andClass:aClass];

	BOOL succeeded = [RRDatabaseObjectBase updateObjectsForSqlStatement:sqlStatement andClass:aClass object:self];
	return succeeded;
}

+ (NSMutableArray *)objectsForKey:(NSString *)key forValue:(NSString *)value andClass:(Class)aClass {
	NSString * sqlStatement = [self sqlSelectStatement:key value:value andClass:aClass];

	return [RRDatabaseObjectBase objectsForSqlStatement:sqlStatement andClass:aClass];
}

+ (NSMutableArray *)objectsForSqlStatement:(NSString *)sqlStatement andClass:(Class)aClass {
	__block NSMutableArray * objects = [NSMutableArray array];

	FMDatabaseQueue * queue = [RRDatabaseObjectBase queue:aClass];
	[queue inDatabase:^(FMDatabase * database) {
		FMResultSet * resultSet = [database executeQuery:sqlStatement];
		while ([resultSet next]) {
			RRDatabaseObjectBase * databaseObject = (RRDatabaseObjectBase *)[aClass new];
			[databaseObject setValuesWithResultSet:resultSet];

			[objects addObject:databaseObject];
		}
		[resultSet close];
	}];

	return objects;
}

+ (RRDatabaseObjectBase *)objectForSqlStatement:(NSString *)sqlStatement andClass:(Class)aClass {


	__block RRDatabaseObjectBase * object;

	FMDatabaseQueue * queue = [RRDatabaseObjectBase queue:aClass];
	[queue inDatabase:^(FMDatabase * database) {
		FMResultSet * resultSet = [database executeQuery:sqlStatement];
		NSAssert1(resultSet, @"Failed to execute SQL statement: %@", sqlStatement);
		BOOL succeeded = [resultSet next];
		if (succeeded) {
			object = [aClass new];
			[object setValuesWithResultSet:resultSet];

			[resultSet close];
		}
	}];

	return object;
}

+ (BOOL)updateObjectsForSqlStatement:(NSString *)sqlStatement
							andClass:(Class)aClass
							  object:(RRDatabaseObjectBase *)object {


	__block BOOL succeeded;
	FMDatabaseQueue * queue = [RRDatabaseObjectBase queue:aClass];
	[queue inDatabase:^(FMDatabase * database) {
		FMResultSet * resultSet = [database executeQuery:sqlStatement];
		NSAssert1(resultSet, @"Failed to execute SQL statement: %@", sqlStatement);
		succeeded = [resultSet next];
		if (succeeded) {
			[object setValuesWithResultSet:resultSet];

			[resultSet close];
		}
	}];

	return succeeded;
}

+ (void)removeAll:(Class)aClass {
	NSString * entityName = [RRDatabaseObjectBase entityName:aClass];
	NSString * sqlStatement = [NSString stringWithFormat:@"DELETE FROM %@", entityName];

	[self executeSqlStatement:sqlStatement aClass:aClass];
}

+ (BOOL)executeSqlStatement:(NSString *)sqlStatement aClass:(Class)aClass {
	__block BOOL succeeded;
	
	FMDatabaseQueue * queue = [RRDatabaseObjectBase queue:aClass];
	[queue inDatabase:^(FMDatabase * database) {
		
		[database beginTransaction];
#ifdef DEBUG
		database.logsErrors = YES;
#else
		database.logsErrors = NO;
#endif
		succeeded = [database executeUpdate:sqlStatement];

		[database commit];
	}];

	return succeeded;
}

- (void)update {
	NSMutableArray * fieldNames = [NSMutableArray array];
	NSMutableArray * fieldValues = [NSMutableArray array];

	NSDictionary * properties = [self properties];
	for (NSString * name in properties) {
		id value = [self valueForKey:name];
		if (value) {
			[fieldNames addObject:name];
			[fieldValues addObject:value];
		}
	}

	NSString * fieldsString = [fieldNames componentsJoinedByString:@"\', \'"];
	fieldsString = [NSString stringWithFormat:@"\'%@\'", fieldsString];

	NSString * valuesString = [@"" stringByPaddingToLength:fieldNames.count * 2 - 1 withString:@"?," startingAtIndex:0];

	NSString * sqlStatement = [NSString
		stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@) VALUES (%@)", self.entityName, fieldsString, valuesString];

	FMDatabaseQueue * queue = [self queue];
	[queue inDatabase:^(FMDatabase * database) {
		[database beginTransaction];

		BOOL succeeded = [database executeUpdate:sqlStatement withArgumentsInArray:fieldValues];
		if (!succeeded) {
			NSError * error = [database lastError];
			NSLog(@"Failed to update DB object\n%@\n%@\n%@", sqlStatement, error, fieldValues);
		}

		[database commit];
	}];
}

+ (void)remove:(NSString *)key value:(NSString *)value andClass:(Class)aClass {
	NSString * entityName = [RRDatabaseObjectBase entityName:aClass];
	NSString * sqlStatement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", entityName, key];

	FMDatabaseQueue * queue = [RRDatabaseObjectBase queue:aClass];
	[queue inDatabase:^(FMDatabase * database) {
		[database beginTransaction];

		BOOL succeeded = [database executeUpdate:sqlStatement, value];
		NSAssert1(succeeded, @"Failed to update DB object\n%@", sqlStatement);
		if (!succeeded) {
			NSError * error = [database lastError];
			NSLog(@"Failed to update DB object\n%@\n%@", sqlStatement, error);
		}

		[database commit];
	}];
}

+ (NSString *)sqlSelectStatement:(NSString *)key value:(NSString *)value andClass:(Class)aClass {
	NSString * entityName = [RRDatabaseObjectBase entityName:aClass];

	return [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=\'%@\'", entityName, key, value];
}

+ (NSString *)sqlSelectStatement:(NSString *)key value:(NSString *)value limit:(int)limit andClass:(Class)aClass {
	NSString * entityName = [RRDatabaseObjectBase entityName:aClass];
	NSString * sqlStatement = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=\'%@\' LIMIT %d", entityName, key, value, limit];
	return sqlStatement;
}

+ (NSString *)sqlSelectPrefixStatement:(NSString *)key value:(NSString *)value limit:(int)limit andClass:(Class)aClass {
    NSString *entityName = [RRDatabaseObjectBase entityName:aClass];
    NSString *sqlStatement = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ LIKE \'%@%%\' LIMIT %d", entityName, key, value, limit];
    return sqlStatement;
}

+ (NSString *)sqlSelectStatement:(Class)aClass {


	NSString * entityName = [RRDatabaseObjectBase entityName:aClass];
	NSString * sqlStatement = [NSString stringWithFormat:@"SELECT * FROM %@", entityName];
	return sqlStatement;
}

- (void)setValuesWithResultSet:(FMResultSet *)resultSet {


	NSMutableDictionary * values = [NSMutableDictionary dictionary];

	// Gather values from DB result set
	NSDictionary * properties = [self properties];
	for (NSString * name in properties) {
		NSString * type = properties[name];
		id value;
		if ([type isEqualToString:NSStringFromClass([NSString class])]) {
			value = [resultSet stringForColumn:name];
		} else if ([type isEqualToString:NSStringFromClass([NSDate class])]) {
			value = [resultSet dateForColumn:name];
		} else if ([type isEqualToString:NSStringFromClass([NSNumber class])]) {
			value = [NSNumber numberWithInt:[resultSet intForColumn:name]];
		}

		if (value) {
			values[name] = value;
		}
	}

	// Set values to properties
	[self setValuesForKeysWithDictionary:values];
}

#pragma mark Comparison

- (BOOL)isEqual:(id)other {
	if (other == self) {
		return YES;
	}
	if (!other || ![[other class] isEqual:[self class]]) {
		return NO;
	}

	return [self isEqualToBase:other];
}

- (BOOL)isEqualToBase:(RRDatabaseObjectBase *)base {
	if (self == base) {
		return YES;
	}
	if (base == nil) {
		return NO;
	}

	NSDictionary * properties = self.properties;
	for (NSString * name in properties) {
		NSObject * value = [self valueForKey:name];
		NSObject * baseValue = [base valueForKey:name];

		if ((nil == value) && (nil == baseValue)) {
			return YES;
		}
		if ((nil != value) || (nil != baseValue)) {
			if (![value isEqual:baseValue]) {
				return NO;
			}
		}
	}

	return YES;
}

@end
