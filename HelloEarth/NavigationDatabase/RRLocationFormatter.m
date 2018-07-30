
#import "RRLocationFormatter.h"

@implementation RRLocationFormatter

NSString * stringFromDoubleWithDegreesCount(double value, int degreesCount) {

	value = ABS(value);
	const int kMinutesAndSecondsCount = 4;
	int count = log10(value);
	int normalizedCount = count - degreesCount;
	NSString * resultString = nil;
	if (normalizedCount >= 0) {
		value = value * pow(10, -normalizedCount);
	}

	resultString =
		[NSString stringWithFormat:@"%0*.*f", kMinutesAndSecondsCount + degreesCount, kMinutesAndSecondsCount, value];
	return [resultString stringByReplacingOccurrencesOfString:@"." withString:@""];
}

+ (CLLocationDegrees)ABSDegreesFromDecimal:(CLLocationDegrees)decimal {
	int seconds = (int)(decimal * 3600);
	int degrees = seconds / 3600;
	seconds = ABS(seconds % 3600);
	int minutes = seconds / 60;
	seconds %= 60;
	BOOL probleem = (seconds > 60 || minutes > 60 || degrees > 180 || degrees < -180);
	if (probleem) {
		;
	}
	return ABS(degrees) + minutes * 0.01 + seconds * 0.0001;
}

+ (NSString *)formattedLatitudeFromFloat:(CGFloat)floatValue isDecimal:(BOOL)isDecimal {
	NSString * suffix = floatValue >= 0 ? @"N" : @"S";
	if (isDecimal) {
		floatValue = [self ABSDegreesFromDecimal:floatValue];
	}
	NSString * resultString = stringFromDoubleWithDegreesCount(floatValue, 3);

	return resultString ? [resultString stringByAppendingString:suffix] : nil;
}

+ (NSString *)formattedLongitudeFromFloat:(CGFloat)floatValue isDecimal:(BOOL)isDecimal {
	NSString * suffix = floatValue >= 0 ? @"E" : @"W";
	if (isDecimal) {
		floatValue = [self ABSDegreesFromDecimal:floatValue];
	}
	NSString * resultString = stringFromDoubleWithDegreesCount(floatValue, 4);

	return resultString ? [resultString stringByAppendingString:suffix] : nil;
}

+ (NSString *)formattedLocationFromCoordinate:(CLLocationCoordinate2D)coordinate {
	NSString *lat = [self formattedLatitudeFromFloat:coordinate.latitude isDecimal:YES];
	NSString *lng = [self formattedLongitudeFromFloat:coordinate.longitude isDecimal:YES];
	
	return [NSString stringWithFormat:@"%@%@", lat, lng];
}

+ (NSString *)shortFormattedLocationFromCoordinate:(CLLocationCoordinate2D)coordinate {
	NSString * lat = [self formattedLatitudeFromFloat:coordinate.latitude isDecimal:YES];
	NSString * lon = [self formattedLongitudeFromFloat:coordinate.longitude isDecimal:YES];
	NSString * shortLat =
		[NSString stringWithFormat:@"%@%c", [lat substringToIndex:4], [lat characterAtIndex:lat.length - 1]];
	NSString * shortLon =
		[NSString stringWithFormat:@"%@%c", [lon substringToIndex:5], [lon characterAtIndex:lon.length - 1]];
	return [NSString stringWithFormat:@"%@%@", shortLat, shortLon];
}

//+ (CLLocationCoordinate2D)coordinateFromFormattedString:(NSString *)formattedString {
//	return [RRRouteParser parseEncodedLocation:formattedString];
//}
//
//+ (CLLocationCoordinate2D)coordinateFromFormattedLatitude:(NSString *)formattedLatitude
//									   formattedLongitude:(NSString *)formattedLongitude {
//	NSString * formattedCoordinate = [NSString stringWithFormat:@"%@%@", formattedLatitude, formattedLongitude];
//	return [RRRouteParser parseEncodedLocation:formattedCoordinate];
//}
//
//+ (CLLocationDegrees)latitudeFromFormattedLatitude:(NSString *)formattedLatitude {
//	return [RRRouteParser parseLatitude:formattedLatitude];
//}
//
//+ (CLLocationDegrees)longitudeFromFormattedLongitude:(NSString *)formattedLongitude {
//	NSString * suffix = [formattedLongitude substringFromIndex:formattedLongitude.length - 1];
//	formattedLongitude = [formattedLongitude substringToIndex:formattedLongitude.length - 1];
//	NSInteger lon = [formattedLongitude integerValue];
//	double power = log10(lon);
//	double requiredPower = 7;
//	lon *= pow(10, requiredPower - (int)power);
//	CLLocationDegrees longitude = 0;
//	if ([suffix isEqualToString:@"E"] || [suffix isEqualToString:@"W"]) {
//		longitude = [RRRouteParser parseLongitude:[NSString stringWithFormat:@"%ld", (long)lon]];
//	}
//	return longitude;
//}

+ (NSString *)textFromBearing:(CLLocationDegrees)bearing {
	NSArray * bearings = @[
		@"NORTH",
		@"NNE",
		@"NE",
		@"ENE",
		@"EAST",
		@"ESE",
		@"SE",
		@"SSE",
		@"SOUTH",
		@"SSW",
		@"SW",
		@"WSW",
		@"WEST",
		@"WNW",
		@"NW",
		@"NNW"
	];

	int directionIdx = (int)lroundf(bearing / 22.5) % bearings.count;
	return bearings[directionIdx];
}

@end
