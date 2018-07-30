#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface RRLocationFormatter : NSObject

+ (NSString *)formattedLocationFromCoordinate:(CLLocationCoordinate2D)coordinate;
+ (NSString *)shortFormattedLocationFromCoordinate:(CLLocationCoordinate2D)coordinate;

+ (CLLocationDegrees)latitudeFromFormattedLatitude:(NSString *)formattedLatitude;
+ (CLLocationDegrees)longitudeFromFormattedLongitude:(NSString *)formattedLongitude;

+ (NSString *)formattedLatitudeFromFloat:(CGFloat)floatValue isDecimal:(BOOL)isDecimal;

//+ (NSString *)formattedLatitudeFromNumber:(NSNumber *)number;
//+ (NSString *)formattedLongitudeFromNumber:(NSNumber *)number;

+ (NSString *)textFromBearing:(CLLocationDegrees)bearing;

@end
