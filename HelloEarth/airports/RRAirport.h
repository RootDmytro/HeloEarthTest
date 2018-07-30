//
//  Airports.h
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 16.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "FMDB.h"

NS_ASSUME_NONNULL_BEGIN

@interface RRAirport : NSObject
+ (RRAirport * _Nullable)defaultZZZZAirportWithName:(NSString *)name atCoordinate:(CLLocationCoordinate2D)coordinate;

@property (nonatomic, copy) NSString *adescription;
@property (nonatomic, copy) NSString *alt_name;
@property (nonatomic, copy) NSString *civmil;
@property (nonatomic, copy) NSString *continent;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *filez;
@property (nonatomic, copy) NSString *iata;
@property (nonatomic, copy) NSString *icao;
@property (nonatomic, copy) NSString *ifr;
@property (nonatomic, copy) NSNumber *latitude;
@property (nonatomic, copy) NSNumber *elevation;
@property (nonatomic, copy) NSNumber *lon;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSNumber *rowid;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSNumber *airport_of_entry;
@property (nonatomic, copy, nullable) NSString *alternativeNearestIcao;
@property (nonatomic, assign) double priority;

- (CLLocation *)location;

- (NSString *)fullName;

+ (RRAirport *)airportWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate;
+ (RRAirport *)airportWithName:(NSString *)name coordinate:(CLLocationCoordinate2D)coordinate icao:(NSString *)icao;

+ (nullable RRAirport *)findNearestAirportToLocation:(CLLocation *)location withinProximityRadius:(NSArray *)radiuses;

#pragma mark - NSUserDefaults Favorite Airports

+ (NSDictionary *)loadFromUserDefaultsFavoriteAirports;
+ (void)saveToUserDefaultsFavoriteAirports:(NSDictionary *)favoriteAirports;

- (BOOL)isUserDefaultsContainsIsFavourite;
+ (BOOL)isUserDefaultsContainsIsFavouriteForAirportICAO:(NSString *)airportICAO;
+ (BOOL)isUserDefaultsContainsIsFavouriteForAirportName:(NSString *)airportName;

- (void)saveToUserDefaultsIsFavourite:(BOOL)isFavourite;
+ (void)saveToUserDefaultsIsFavourite:(BOOL)isFavourite forAirportICAO:(NSString *)airporICAO;
+ (void)saveToUserDefaultsIsFavourite:(BOOL)isFavourite forAirportName:(NSString *)airportName;

- (BOOL)loadFromUserDefaultsIsFavourite;
+ (BOOL)loadFromUserDefaultsIsFavouriteForAirportICAO:(NSString *)airportICAO;
+ (BOOL)loadFromUserDefaultsIsFavouriteForAirportName:(NSString *)airportName;

- (void)removeFromUserDefaultsIsFavourite;
+ (void)removeFromUserDefaultsIsFavouriteForAirportICAO:(NSString *)airportICAO;
+ (void)removeFromUserDefaultsIsFavouriteForAirportName:(NSString *)airportName;

#pragma mark - NSUserDefaults Installed Airports Without Documents

+ (NSArray *)loadFromUserDefaultsInstalledAirportsWithoutDocuments;
+ (void)saveToUserDefaultsInstalledAirportsWithoutDocuments:(NSArray *)installedAirportsWithoutDocuments;

- (BOOL)isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportKey;
+ (BOOL)isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportICAO:(NSString *)airportICAO;
+ (BOOL)isUserDefaultsInstalledAirportsWithoutDocumentsContainsAirportName:(NSString *)airportName;

- (void)saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportKey;
+ (void)saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportICAO:(NSString *)airportICAO;
+ (void)saveToUserDefaultsInstalledAirportsWithoutDocumentsAirportName:(NSString *)airportName;

- (void)removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportKey;
+ (void)removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportICAO:(NSString *)airportICAO;
+ (void)removeFromUserDefaultsInstalledAirportsWithoutDocumentsAirportName:(NSString *)airportName;

@end

extern NSString * const RRFileZIcaoIdentifier;

NS_ASSUME_NONNULL_END
