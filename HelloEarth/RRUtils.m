//
//  RRUtils.m
//  RRMapView
//
//  Created by Yuriy Levytskyy on 28.09.13.
//  Copyright (c) 2013 Yuriy Levytskyy. All rights reserved.
//

#import "RRUtils.h"

@implementation RRUtils

+ (UIImage *)imageFromText:(NSString *)text
				  fontName:(NSString *)fontName
				  fontSize:(CGFloat)fontSize
					 color:(UIColor *)color
			   strokeColor:(UIColor *)strokeColor {
	NSAssert(text.length > 0, @"Invalid text specified");

	UIImage *image = nil;
	if (text.length > 0) {
		UIFont *font = [UIFont fontWithName:fontName size:lroundf(fontSize)];
		
		strokeColor = strokeColor ?: [UIColor clearColor];
		NSDictionary *attributes = @{NSFontAttributeName: font,
									 NSStrokeWidthAttributeName: @4,
									 NSStrokeColorAttributeName: strokeColor};
		
		CGSize size = [text sizeWithAttributes:attributes];
		
		size = CGSizeMake(ceil(size.width), ceil(size.height));

		CGFloat scale = [UIScreen mainScreen].scale;
		UIGraphicsBeginImageContextWithOptions(size, NO, scale);

		[text drawAtPoint:CGPointZero withAttributes:attributes];

		[text drawAtPoint:CGPointZero withAttributes:@{NSFontAttributeName: font,
													   NSForegroundColorAttributeName: color}];

		// transfer image
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}

	return image;
}

+ (CGSize)statusBarFrameViewSize {
	CGSize statusBarSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 20);
	return statusBarSize;
}

+ (double)calculateAngleFrom:(CLLocationCoordinate2D)from
						  to:(CLLocationCoordinate2D)to
					location:(CLLocationCoordinate2D)location {
	double ux = location.longitude - from.longitude;
	double uy = location.latitude - from.latitude;
	double du = sqrt(ux * ux + uy * uy);

	double vx = to.longitude - from.longitude;
	double vy = to.latitude - from.latitude;
	double dv = sqrt(vx * vx + vy * vy);

	double dot = ux * vx + uy * vy;

	double angle = acos(dot / (du * dv));
	return angle;
}

+ (void)startRotationAnimation:(UIView *)view allowUserInteraction:(BOOL)allowUserInteraction {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIViewAnimationOptions options = UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear |
		(allowUserInteraction ? UIViewAnimationOptionAllowUserInteraction : 0);
		[UIView animateWithDuration:1.0
							  delay:0.0
							options:options
						 animations:^{
							 CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI - 0.001);
							 view.transform = transform;
						 }
						 completion:NULL];
	});
}

+ (void)stopRotationAnimation:(UIView *)view {
	dispatch_async(dispatch_get_main_queue(), ^{
		[view.layer removeAllAnimations];
		view.transform = CGAffineTransformMakeRotation(0);
	});
}

+ (UIImage *)rectangleImageForText:(NSString *)text
						 textColor:(UIColor *)textColor
						 fillColor:(UIColor *)fillColor
						  fontName:(NSString *)fontName
						  fontSize:(CGFloat)fontSize
						  xPadding:(CGFloat)xPadding {
	// Generate a text label bitmap.
	CGFloat scale = [UIScreen mainScreen].scale;
	UIImage * textImage =
		[RRUtils imageFromText:text fontName:fontName fontSize:fontSize color:textColor strokeColor:nil];

	CGFloat xMargin = 4 + xPadding;
	CGFloat yMargin = 1;
	float labelWidth = textImage.size.width + 2 * xMargin;
	float labelHeight = textImage.size.height + 2 * yMargin;

	CGSize contextSize = CGSizeMake(labelWidth, labelHeight);
	UIGraphicsBeginImageContextWithOptions(contextSize, NO, scale);
	CGContextRef context = UIGraphicsGetCurrentContext();
	//
	// Draw background rectangle
	CGMutablePathRef pathRef = CGPathCreateMutable();

	CGPathMoveToPoint(pathRef, NULL, 0, 0);
	CGPathAddLineToPoint(pathRef, NULL, labelWidth - 1, 0);
	CGPathAddLineToPoint(pathRef, NULL, labelWidth - 1, labelHeight - 1);
	CGPathAddLineToPoint(pathRef, NULL, 0, labelHeight - 1);
	CGPathAddLineToPoint(pathRef, NULL, 0, 0);

	CGPathCloseSubpath(pathRef);

	CGContextAddPath(context, pathRef);
	CGContextFillPath(context);

	CGContextAddPath(context, pathRef);
	CGContextStrokePath(context);

	CGPathRelease(pathRef);

	//
	// Draw label text
	CGFloat x = (labelWidth - textImage.size.width) / 2.0f;
	CGFloat y = (labelHeight - textImage.size.height) / 2.0f;
	if (!RRIsRetina()) {
		// Brutal hack!
		y -= 1.0f;
	}
	[textImage drawInRect:CGRectMake(x, y, textImage.size.width, textImage.size.height)];

	UIImage * labelImage = UIGraphicsGetImageFromCurrentImageContext();

	UIGraphicsEndImageContext();

	return labelImage;
}

+ (UIView *)subviewForView:(UIView *)view class:(Class)aClass {
	UIView * classView;
	for (UIView * subview in view.subviews) {
		if ([subview isKindOfClass:aClass]) {
			classView = subview;
		} else {
			classView = [RRUtils subviewForView:subview class:aClass];
		}

		if (classView) {
			break;
		}
	}
	return classView;
}

+ (UIColor *)getColorWithRed:(CGFloat)red Greeen:(CGFloat)green Blue:(CGFloat)blue alpha:(CGFloat)alpha {
	UIColor * color = [UIColor colorWithRed:red / 255.f green:green / 255.f blue:blue / 255.f alpha:alpha];

	return color;
}

@end


double RRComputeParameters(CLLocationCoordinate2D initial, CLLocationCoordinate2D destination, CLLocationDistance *distance, CLLocationDirection *bearing, CLLocationDirection *destinationBearing) {
	// Based on http://www.ngs.noaa.gov/PUBS_LIB/inverse.pdf
	// using the "Inverse Formula" (section 4)
	double lat1 = RRRadiansFromDegrees(initial.latitude);
	double lon1 = RRRadiansFromDegrees(initial.longitude);
	double lat2 = RRRadiansFromDegrees(destination.latitude);
	double lon2 = RRRadiansFromDegrees(destination.longitude);
	
	const int MAXITERS = 20;
	
	double a = 6378137.0; // WGS84 major axis
	double b = 6356752.3142; // WGS84 semi-major axis
	double f = (a - b) / a;
	double aSqMinusBSqOverBSq = (a * a - b * b) / (b * b);
	
	double L = lon2 - lon1;
	double A = 0.0;
	double U1 = atan((1.0 - f) * tan(lat1));
	double U2 = atan((1.0 - f) * tan(lat2));
	
	double cosU1 = cos(U1);
	double cosU2 = cos(U2);
	double sinU1 = sin(U1);
	double sinU2 = sin(U2);
	double cosU1cosU2 = cosU1 * cosU2;
	double sinU1sinU2 = sinU1 * sinU2;
	
	double sigma = 0.0;
	double deltaSigma = 0.0;
	double cosSqAlpha = 0.0;
	double cos2SM = 0.0;
	double cosSigma = 0.0;
	double sinSigma = 0.0;
	double cosLambda = 0.0;
	double sinLambda = 0.0;
	
	double delta = 0;
	double lambda = L; // initial guess
	for (int iter = 0; iter < MAXITERS; iter++) {
		double lambdaOrig = lambda;
		cosLambda = cos(lambda);
		sinLambda = sin(lambda);
		double t1 = cosU2 * sinLambda;
		double t2 = cosU1 * sinU2 - sinU1 * cosU2 * cosLambda;
		double sinSqSigma = t1 * t1 + t2 * t2; // (14)
		sinSigma = sqrt(sinSqSigma);
		cosSigma = sinU1sinU2 + cosU1cosU2 * cosLambda; // (15)
		sigma = atan2(sinSigma, cosSigma); // (16)
		double sinAlpha = (sinSigma == 0) ? 0.0 : cosU1cosU2 * sinLambda / sinSigma; // (17)
		cosSqAlpha = 1.0 - sinAlpha * sinAlpha;
		cos2SM = (cosSqAlpha == 0) ? 0.0 : cosSigma - 2.0 * sinU1sinU2 / cosSqAlpha; // (18)
		
		double uSquared = cosSqAlpha * aSqMinusBSqOverBSq; // defn
		
		A = 1 + (uSquared / 16384.0) * // (3)
		(4096.0 + uSquared * (-768 + uSquared * (320.0 - 175.0 * uSquared)));
		
		double B = (uSquared / 1024.0) * // (4)
		(256.0 + uSquared * (-128.0 + uSquared * (74.0 - 47.0 * uSquared)));
		double C = (f / 16.0) * cosSqAlpha * (4.0 + f * (4.0 - 3.0 * cosSqAlpha)); // (10)
		double cos2SMSq = cos2SM * cos2SM;
		
		deltaSigma = B * sinSigma * // (6)
		(cos2SM + (B / 4.0) * (cosSigma * (-1.0 + 2.0 * cos2SMSq) - (B / 6.0) * cos2SM * (-3.0 + 4.0 * sinSigma * sinSigma) * (-3.0 + 4.0 * cos2SMSq)));
		
		lambda = L + (1.0 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SM + C * cosSigma * (-1.0 + 2.0 * cos2SM * cos2SM))); // (11)
		
		delta = (lambda - lambdaOrig) / lambda;
		if (fabs(delta) < 1.0e-12) {
			break;
		}
	}
	
	if (distance) {
		*distance = b * A * (sigma - deltaSigma);
	}
	
	if (bearing) {
		float initialBearing = atan2(cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda);
		*bearing = RRNormalizeDegrees(RRDegreesFromRadians(initialBearing));
	}
	
	if (destinationBearing) {
		float finalBearing = atan2(cosU1 * sinLambda, -sinU1 * cosU2 + cosU1 * sinU2 * cosLambda);
		*destinationBearing = RRNormalizeDegrees(RRDegreesFromRadians(finalBearing));
	}
	
	return delta;
}

/// azimuth˚
CLLocationDirection RRBearingIfHeadingTo(CLLocationCoordinate2D current, CLLocationCoordinate2D next) {
	if (!CLLocationCoordinate2DIsValid(current) || !CLLocationCoordinate2DIsValid(next)) {
		return -1;
	}
	
	double lat1 = RRRadiansFromDegrees(current.latitude);
	double lat2 = RRRadiansFromDegrees(next.latitude);
	double dLon = RRRadiansFromDegrees(next.longitude - current.longitude);
	
	double y = sin(dLon) * cos(lat2);
	double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
	CLLocationDirection bearing = atan2(y, x);
	
	return RRNormalizeDegrees(RRDegreesFromRadians(bearing));
}

/// azimuth˚
CLLocationDirection RRBearingIfMovingFrom(CLLocationCoordinate2D current, CLLocationCoordinate2D previous) {
	if (!CLLocationCoordinate2DIsValid(previous) || !CLLocationCoordinate2DIsValid(current)) {
		return -1;
	}
	return RRNormalizeDegrees(RRBearingIfHeadingTo(current, previous) + 180);
}

RRCartesianCoordinate3D RRCartesianCoordinate3DMake(double x, double y, double z) {
	RRCartesianCoordinate3D coord;
	coord.x = x;
	coord.y = y;
	coord.z = z;
	return coord;
}

RRCartesianCoordinate3D RRCartesianFromCoordinate2D(CLLocationCoordinate2D coord) {
	CLLocationCoordinate2D radianCoord = CLLocationCoordinate2DMake(RRRadiansFromDegrees(coord.latitude), RRRadiansFromDegrees(coord.longitude));
	return RRCartesianCoordinate3DMake(cos(radianCoord.latitude) * cos(radianCoord.longitude),
									   cos(radianCoord.latitude) * sin(radianCoord.longitude),
									   sin(radianCoord.latitude));
}

CLLocationCoordinate2D RRCoordinate2DFromCartesian(RRCartesianCoordinate3D coord) {
	double lon = atan2(coord.y, coord.x);
	double hyp = sqrt(coord.x * coord.x + coord.y * coord.y);
	double lat = atan2(coord.z, hyp);
	return CLLocationCoordinate2DMake(RRDegreesFromRadians(lat), RRDegreesFromRadians(lon));
}

CLLocationCoordinate2D RRMidpointCoordinate(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2) {
	RRCartesianCoordinate3D cartesianCoord1 = RRCartesianFromCoordinate2D(coord1);
	RRCartesianCoordinate3D cartesianCoord2 = RRCartesianFromCoordinate2D(coord2);
	
	RRCartesianCoordinate3D cartesianMidpoint = RRCartesianCoordinate3DMake((cartesianCoord1.x + cartesianCoord2.x) / 2,
																			(cartesianCoord1.y + cartesianCoord2.y) / 2,
																			(cartesianCoord1.z + cartesianCoord2.z) / 2);
	
	CLLocationCoordinate2D midpointCoord = RRCoordinate2DFromCartesian(cartesianMidpoint);
	return midpointCoord;
}

CLLocationCoordinate2D RRTranslateCoordinate(CLLocationCoordinate2D fromCoord, CLLocationDistance distance, CLLocationDirection bearing) {
	double distanceRadians = distance / RREarthRadiusMeters;
	// 6,371 = Earth's radius in km
	double bearingRadians = RRRadiansFromDegrees(bearing);
	double fromLatRadians = RRRadiansFromDegrees(fromCoord.latitude);
	double fromLonRadians = RRRadiansFromDegrees(fromCoord.longitude);
	
	double toLatRadians = asin(sin(fromLatRadians) * cos(distanceRadians) +
							   cos(fromLatRadians) * sin(distanceRadians) * cos(bearingRadians));
	
	double toLonRadians = fromLonRadians + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(fromLatRadians),
												 cos(distanceRadians) - sin(fromLatRadians) * sin(toLatRadians));
	
	// adjust toLonRadians to be in the range -180 to +180...
	toLonRadians = fmod(toLonRadians + 3 * M_PI, 2 * M_PI) - M_PI;
	
	return CLLocationCoordinate2DMake(RRDegreesFromRadians(toLatRadians), RRDegreesFromRadians(toLonRadians));
}


RRLocationBounds RRLocationBoundsMakeWithMinMax(CLLocationCoordinate2D min, CLLocationCoordinate2D max) {
	RRLocationBounds bounds;
	bounds.min = min;
	bounds.max = max;
	return bounds;
}

RRLocationBounds RRLocationBoundsMake(CLLocationDegrees minLatitude, CLLocationDegrees minLongitude, CLLocationDegrees maxLatitude, CLLocationDegrees maxLongitude) {
	CLLocationCoordinate2D min;
	min.latitude = minLatitude;
	min.longitude = minLongitude;
	
	CLLocationCoordinate2D max;
	max.latitude = maxLatitude;
	max.longitude = maxLongitude;
	
	return RRLocationBoundsMakeWithMinMax(min, max);
}

RRLocationBounds RRLocationBoundsInset(RRLocationBounds bounds, CLLocationDegrees dLatitude, CLLocationDegrees dLongitude) {
	bounds.min.latitude += dLatitude;
	bounds.max.latitude -= dLatitude;
	bounds.min.longitude += dLongitude;
	bounds.max.longitude -= dLongitude;
	return bounds;
}

RRLocationBounds RRLocationBoundsIncludeCoordinate(RRLocationBounds bounds, CLLocationCoordinate2D coordinate) {
	bounds.max.latitude = MAX(coordinate.latitude, bounds.max.latitude);
	bounds.max.longitude = MAX(coordinate.longitude, bounds.max.longitude);
	bounds.min.latitude = MIN(coordinate.latitude, bounds.min.latitude);
	bounds.min.longitude = MIN(coordinate.longitude, bounds.min.longitude);
	return bounds;
}


CGFloat RRPointDistance(CGPoint point1, CGPoint point2) {
	return sqrt(pow(point1.x - point2.x, 2) +
				pow(point1.y - point2.y, 2));
}

CGPoint RRSizeGetCenter(CGSize size) {
	return CGPointMake(size.width / 2, size.height / 2);
}

CGPoint RRTruncatePointInBounds(CGPoint point, CGRect bounds) {
	return CGPointMake(MIN(MAX(bounds.origin.x, point.x), CGRectGetMaxX(bounds)),
					   MIN(MAX(bounds.origin.y, point.y), CGRectGetMaxY(bounds)));
}

NSComparisonResult RRCompareInteger(NSInteger left, NSInteger right) {
	return left == right ? NSOrderedSame : left < right ? NSOrderedAscending : NSOrderedDescending;
}

NSString * NSStringFromBOOL(BOOL boolValue) { return boolValue ? @"YES" : @"NO"; }

double RRRadiansFromDegrees(CLLocationDirection degrees) { return degrees * M_PI / 180; }

CLLocationDirection RRDegreesFromRadians(double radians) { return radians * 180 / M_PI; }

double RRMinorAngleBetweenDirections(double degreesA, double degreesB) { return 180.0 - fabs(RRNormalizeDegrees(degreesA - degreesB) - 180.0); }

CLLocationDirection RRNormalizeDegrees(CLLocationDirection degrees) { return fmod(degrees + 360.0, 360.0); }

NSString *RRWarningMessage(NSString *localizedString) {
	return [NSString stringWithFormat:@"⚠️ %@", localizedString];
}


NSString * RRAppInstanceUDID() {
	static NSString * RRCustomUDIDKey = @"RRCustomUDID";
	static NSString * udid = nil;
	
	udid = [[NSUserDefaults standardUserDefaults] objectForKey:RRCustomUDIDKey];
	
	if (!udid) {
		udid = NSUUID.UUID.UUIDString;
		
		[[NSUserDefaults standardUserDefaults] setObject:udid forKey:RRCustomUDIDKey];
	}

	return udid;
}

float RRGetStatusBarHeight() {
	CGSize size = [RRUtils statusBarFrameViewSize];
	return size.height;
}

BOOL RRIsiPhone() {
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

BOOL RRIsiPad() {
	return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

BOOL RRIsRetina() {
	return UIScreen.mainScreen.scale >= 2;
}

NSString * RRNilIfNull(NSString * string) { return [string isEqual:[NSNull null]] ? nil : string; }
NSString * RRNotNull(NSString * string) { return string != nil && ![string isEqual:[NSNull null]] ? string : @""; }
NSString * RRNotEmpty(NSString * string) { return string.length > 0 ? string : @" "; }

NSInteger RRGetPersistentInteger(NSString * key, int defaultValue) {
	NSInteger value = defaultValue;

	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	id object = [userDefaults objectForKey:key];
	if (object) {
		value = [userDefaults integerForKey:key];
	}
	return value;
}

void RRSetPersistentInteger(NSString * key, NSInteger value) {
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:value forKey:key];
}
	
BOOL RRGetPersistentBool(NSString * key) {
	return [[NSUserDefaults.standardUserDefaults objectForKey:key] boolValue];
}
	
void RRSetPersistentBool(NSString * key, BOOL value) {
	[NSUserDefaults.standardUserDefaults setBool:value forKey:key];
}

void RRSignalCompletion(NSCondition * condition) {
	[condition lock];
	[condition signal];
	[condition unlock];
}

void RRWaitForCompletion(NSCondition * condition) {
	[condition lock];
	[condition wait];
	[condition unlock];
}

NSString * RRGetInnerXml(NSString * xmlString, NSString * xmlTag) {
	NSString * openTag = [NSString stringWithFormat:@"<%@>", xmlTag];
	NSString * closeTag = [NSString stringWithFormat:@"</%@>", xmlTag];

	// Parse inner XML
	NSString * innerXml = nil;
	NSRange startRange = [xmlString rangeOfString:openTag options:NSCaseInsensitiveSearch];
	if (NSNotFound != startRange.location) {
		NSRange endRange = [xmlString rangeOfString:closeTag options:NSCaseInsensitiveSearch];
		if (NSNotFound != endRange.location) {
			NSRange range = NSMakeRange(NSMaxRange(startRange), endRange.location - NSMaxRange(startRange));
			innerXml = [xmlString substringWithRange:range];
		}
	}

	return innerXml;
}

