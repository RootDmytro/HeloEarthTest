//
//  AirportsDatabase.h
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 19.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import "RRAirport.h"

NS_ASSUME_NONNULL_BEGIN

@interface RRAirportsDatabase : NSObject

+ (instancetype)sharedInstance;

- (instancetype)initWithDBPath:(NSString *)dbPath;

- (nullable RRAirport *)airportWithName:(NSString *)name;
- (nullable RRAirport *)airportWithName:(NSString *)name location:(CLLocationCoordinate2D)location;
- (nullable RRAirport *)airportWithName:(NSString *)name location:(CLLocationCoordinate2D)location icao:(NSString *)icao;

- (nullable RRAirport *)airportWithICAO:(NSString *)icao;
- (nullable RRAirport *)airportWithIATA:(NSString *)iata;
- (nullable RRAirport *)airportWithId:(NSString *)airportId;

- (NSDictionary<NSString *, RRAirport *> *)airportsWithICAO:(NSSet * _Nullable)icaoSet orNamesSet:(NSSet * _Nullable)namesSet;

- (RRAirport *)nearestAirportAtLocation:(CLLocation *)location withinMetersSearchRadius:(CLLocationDistance)radius icaoOnly:(BOOL)icaoOnly;

- (NSArray<RRAirport *> *)performQuery:(NSString *)query withNamedFields:(NSDictionary *)fields;

- (NSArray<RRAirport *> *)filteredAirportsWithTerm:(NSString *)term limit:(NSUInteger)limit;
- (NSArray<RRAirport *> *)filteredIcaoAirportsWithTerm:(NSString *)term limit:(NSUInteger)limit;
- (NSArray<RRAirport *> *)filteredAirportsWithTerm:(NSString *)term nearestToCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSUInteger)limit;
- (NSArray<RRAirport *> *)filteredIcaoAirportsWithTerm:(NSString *)term nearestToCoordinate:(CLLocationCoordinate2D)coordinate limit:(NSUInteger)limit;

@end

NS_ASSUME_NONNULL_END
