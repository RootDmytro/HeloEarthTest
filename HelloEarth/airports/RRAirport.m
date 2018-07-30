//
//  Airports.m
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 16.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import "RRAirport.h"
#import "RRAirportsDatabase.h"
#import "NSString+Crypto.h"
#import "RRKitUtils.h"

static NSString *const kUserDefaultsFavoriteAirportsKey = @"favoriteAirports";
static NSString *const kUserDefaultsInstalledAirportsWithoutDocumentsKey = @"installedAirportsWithoutDocuments";


@implementation RRAirport {
	NSString * _fullName; // KVO/KVC compliant. Instance variable with the `_` enough to make the class KVC complaint. Not necessary to create a separate setter.
}

+ (RRAirport *)defaultZZZZAirportWithName:(NSString *)name atCoordinate:(CLLocationCoordinate2D)coordinate {
	RRAirport *zzzz = nil;
	
	if (CLLocationCoordinate2DIsValid(coordinate)) {
		zzzz = [self new];
		
		zzzz.filez = @(YES).stringValue;
		zzzz.icao = RRFileZIcaoIdentifier;
		zzzz.lon = @(coordinate.longitude);
		zzzz.latitude = @(coordinate.latitude);
		zzzz.name = name;
	}
	
	return zzzz;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"[%@ - 0x%lX\n"
			"\tadescription: %@,\n"
			"\talt_name: %@,\n"
			"\tcivmil: %@,\n"
			"\tcountry: %@,\n"
			"\tfilez: %@,\n"
			"\tiata: %@,\n"
			"\ticao: %@,\n"
			"\tlatitude: %@,\n"
			"\tlon: %@,\n"
			"\tname: %@,\n"
			"\trowid: %@]",
			NSStringFromClass(self.class), (unsigned long)self,
			self.adescription, self.alt_name, self.civmil,
			self.country, self.filez, self.iata, self.icao, self.latitude, self.lon, self.name, self.rowid];
}

- (CLLocation *)location {
	return [[CLLocation alloc] initWithLatitude:self.latitude.doubleValue longitude:self.lon.doubleValue];
}

- (NSString *)fullName {
	if (!_fullName) {
		if (self.icao.isValidAirportCode && self.name.length > 0) {
			_fullName = [NSString stringWithFormat:@"%@ %@", self.icao, self.name];
		} else {
			_fullName = self.name;
		}
	}
	
	return _fullName;
}

#pragma mark - DB Searches

+ (RRAirport *)airportWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate {
	RRAirport * airport = [RRAirportsDatabase.sharedInstance airportWithName:name location:coordinate];
	
	if (!airport) {
		static NSUInteger const idx = 4;
		static NSString * const separator = @" ";
		BOOL hasIcaoSeparator = [name rangeOfString:separator].location == 4;
		BOOL hasAcceptableLength = name.length > idx + separator.length;
		if (hasAcceptableLength && hasIcaoSeparator) {
			airport = [RRAirportsDatabase.sharedInstance airportWithName:[name substringFromIndex:idx + separator.length] location:coordinate icao:[name substringToIndex:idx]];
		}
	}
	
	if (!airport) {
		airport = [RRAirport defaultZZZZAirportWithName:name atCoordinate:coordinate];
	}
	
	return airport;
}


+ (RRAirport *)airportWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate icao:(NSString *)icao {
	RRAirport * airport = [RRAirportsDatabase.sharedInstance airportWithName:name location:coordinate icao:icao];
	
	if (!airport) {
		airport = [RRAirport defaultZZZZAirportWithName:name atCoordinate:coordinate];
	}
	
	return airport;
}

+ (RRAirport *)findNearestAirportToLocation:(CLLocation *)location withinProximityRadius:(NSArray *)radiuses {
	RRAirport * airport = nil;
	
	for (NSNumber * radiusNumber in radiuses) {
		CLLocationDistance radius = RRMetersFromNauticalMiles(radiusNumber.doubleValue);
		
		airport = [RRAirportsDatabase.sharedInstance nearestAirportAtLocation:location
														  withinMetersSearchRadius:radius icaoOnly:NO];
		
		if (airport) {
			break;
		}
	}
	
	return airport;
}

#pragma mark - Installed

#pragma mark - NSUserDefaults Favorite Airports
#pragma mark

+ (NSDictionary *)loadFromUserDefaultsFavoriteAirports {
    return [NSUserDefaults.standardUserDefaults dictionaryForKey:kUserDefaultsFavoriteAirportsKey];
}

+ (void)saveToUserDefaultsFavoriteAirports:(NSDictionary *)favoriteAirports {
    [NSUserDefaults.standardUserDefaults setObject:favoriteAirports forKey:kUserDefaultsFavoriteAirportsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}
// IS
- (BOOL)isUserDefaultsContainsIsFavourite {
    if (self.icao.isValidAirportCode) {
        return [RRAirport isUserDefaultsContainsIsFavouriteForAirportICAO:self.icao];
    } else {
        return [RRAirport isUserDefaultsContainsIsFavouriteForAirportName:self.name];
    }
}

+ (BOOL)isUserDefaultsContainsIsFavouriteForAirportICAO:(NSString *)airportICAO {
    return [self isUserDefaultsContainsIsFavouriteForAirportKey:airportICAO];
}

+ (BOOL)isUserDefaultsContainsIsFavouriteForAirportName:(NSString *)airportName {
    return [self isUserDefaultsContainsIsFavouriteForAirportKey:airportName];
}

+ (BOOL)isUserDefaultsContainsIsFavouriteForAirportKey:(NSString *)AirportKey {
    NSDictionary * favoriteAirports = [self loadFromUserDefaultsFavoriteAirports];
    
    if (favoriteAirports) return [favoriteAirports valueForKey:AirportKey] != nil;
    
    return NO;
}
// SAVE
- (void)saveToUserDefaultsIsFavourite:(BOOL)isFavourite {
    if (self.icao.isValidAirportCode) {
        [RRAirport saveToUserDefaultsIsFavourite:isFavourite forAirportICAO:self.icao];
    } else {
        [RRAirport saveToUserDefaultsIsFavourite:isFavourite forAirportName:self.name];
    }
}

+ (void)saveToUserDefaultsIsFavourite:(BOOL)isFavourite forAirportICAO:(NSString *)airporICAO {
    [self saveToUserDefaultsIsFavourite:isFavourite forAirportKey:airporICAO];
}

+ (void)saveToUserDefaultsIsFavourite:(BOOL)isFavourite forAirportName:(NSString *)airportName {
    [self saveToUserDefaultsIsFavourite:isFavourite forAirportKey:airportName];
}

+ (void)saveToUserDefaultsIsFavourite:(BOOL)isFavourite forAirportKey:(NSString *)airportKey {
    NSMutableDictionary * favoriteAirports = [NSMutableDictionary dictionaryWithDictionary:[self loadFromUserDefaultsFavoriteAirports]];
    
    if (!favoriteAirports) favoriteAirports = [NSMutableDictionary new];
    
    [favoriteAirports setValue:[NSNumber numberWithBool:isFavourite] forKey:airportKey];
    
    [self saveToUserDefaultsFavoriteAirports:favoriteAirports];
}
// LOAD
- (BOOL)loadFromUserDefaultsIsFavourite {
    if (self.icao.isValidAirportCode) {
        return [RRAirport loadFromUserDefaultsIsFavouriteForAirportICAO:self.icao];
    } else {
        return [RRAirport loadFromUserDefaultsIsFavouriteForAirportName:self.name];
    }
}

+ (BOOL)loadFromUserDefaultsIsFavouriteForAirportICAO:(NSString *)airportICAO {
    return [self loadFromUserDefaultsIsFavouriteForAirportKey:airportICAO];
}

+ (BOOL)loadFromUserDefaultsIsFavouriteForAirportName:(NSString *)airportName {
    return [self loadFromUserDefaultsIsFavouriteForAirportKey:airportName];
}

+ (BOOL)loadFromUserDefaultsIsFavouriteForAirportKey:(NSString *)airportKey {
    NSDictionary * favoriteAirports = [self loadFromUserDefaultsFavoriteAirports];
    
    return [[favoriteAirports valueForKey:airportKey] boolValue];
}
// REMOVE
- (void)removeFromUserDefaultsIsFavourite {
    if (self.icao.isValidAirportCode) {
        [RRAirport removeFromUserDefaultsIsFavouriteForAirportICAO:self.icao];
    } else {
        [RRAirport removeFromUserDefaultsIsFavouriteForAirportName:self.name];
    }
}

+ (void)removeFromUserDefaultsIsFavouriteForAirportICAO:(NSString *)airportICAO {
    [self removeFromUserDefaultsIsFavouriteForAirportKey:airportICAO];
}

+ (void)removeFromUserDefaultsIsFavouriteForAirportName:(NSString *)airportName {
    [self removeFromUserDefaultsIsFavouriteForAirportKey:airportName];
}

+ (void)removeFromUserDefaultsIsFavouriteForAirportKey:(NSString *)airportKey {
    if ([self isUserDefaultsContainsIsFavouriteForAirportKey:airportKey]) {
        NSMutableDictionary * favoriteAirports = [NSMutableDictionary dictionaryWithDictionary:[self loadFromUserDefaultsFavoriteAirports]];
        
        [favoriteAirports removeObjectForKey:airportKey];
        
        [self saveToUserDefaultsFavoriteAirports:favoriteAirports];
    }

}

#pragma mark - NSUserDefaults Installed Airports Without Documents
#pragma mark

+ (NSArray<NSString *> *)loadFromUserDefaultsInstalledAirportsWithoutDocuments {
    return [NSUserDefaults.standardUserDefaults arrayForKey:kUserDefaultsInstalledAirportsWithoutDocumentsKey];
}

+ (void)saveToUserDefaultsInstalledAirportsWithoutDocuments:(NSArray<NSString *> *)installedAirportsWithoutDocuments {
    [NSUserDefaults.standardUserDefaults setObject:installedAirportsWithoutDocuments
                                            forKey:kUserDefaultsInstalledAirportsWithoutDocumentsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}
// IS
- (BOOL)isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportKey {
    if (self.icao.isValidAirportCode) {
        return [RRAirport isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportICAO:self.icao];
    } else {
        return [RRAirport isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportName:self.name];
    }
}

+ (BOOL)isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportICAO:(NSString *)airportICAO {
    return [self isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportKey:airportICAO];
}

+ (BOOL)isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportName:(NSString *)airportName {
    return [self isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportKey:airportName];
}

+ (BOOL)isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportKey:(NSString *)airportKey {
    NSArray<NSString *> *installedAirportsWithoutDocuments = [self loadFromUserDefaultsInstalledAirportsWithoutDocuments];
    return [installedAirportsWithoutDocuments containsObject:airportKey];
}

// SAVE
- (void)saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportKey {
    if (self.icao.isValidAirportCode) {
        [RRAirport saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportICAO:self.icao];
    } else {
        [RRAirport saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportName:self.name];
    }
}

+ (void)saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportICAO:(NSString *)airportICAO {
    [self saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportKey:airportICAO];
}

+ (void)saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportName:(NSString *)airportName {
    [self saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportKey:airportName];
}

+ (void)saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportKey:(NSString *)airportKey {
	if (![self isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportKey:airportKey]) {
		NSMutableArray<NSString *> *installedAirportsWithoutDocuments = [NSMutableArray arrayWithArray:[self loadFromUserDefaultsInstalledAirportsWithoutDocuments]];
        [installedAirportsWithoutDocuments addObject:airportKey];
        [self saveToUserDefaultsInstalledAirportsWithoutDocuments:installedAirportsWithoutDocuments];
    }
}
// REMOVE
- (void)removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportKey {
    if (self.icao.isValidAirportCode) {
        [RRAirport removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportICAO:self.icao];
    } else {
        [RRAirport removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportName:self.name];
    }
}

+ (void)removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportICAO:(NSString *)airportICAO {
    [self removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportKey:airportICAO];
}

+ (void)removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportName:(NSString *)airportName {
    [self removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportKey:airportName];
}

+ (void)removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportKey:(NSString *)airportKey {
    NSMutableArray<NSString *> *installedAirportsWithoutDocuments = [NSMutableArray arrayWithArray:[self loadFromUserDefaultsInstalledAirportsWithoutDocuments]];
	
	[installedAirportsWithoutDocuments removeObject:airportKey];
	
    [self saveToUserDefaultsInstalledAirportsWithoutDocuments:installedAirportsWithoutDocuments];
}

@end

NSString * const RRFileZIcaoIdentifier = @"ZZZZ";
