//
//  RRUtils.h
//  RRMapView
//
//  Created by Yuriy Levytskyy on 28.09.13.
//  Copyright (c) 2013 Yuriy Levytskyy. All rights reserved.
//

#import "RRKitUtils.h"
#import <UIKit/UIKit.h>

typedef struct RRCartesianCoordinate3D {
	double x;
	double y;
	double z;
} RRCartesianCoordinate3D;

typedef struct RRLocationBounds {
	CLLocationCoordinate2D min;
	CLLocationCoordinate2D max;
} RRLocationBounds;

@interface RRUtils : RRKitUtils

+ (UIImage *)imageFromText:(NSString *)text
				  fontName:(NSString *)fontName
				  fontSize:(CGFloat)fontSize
					 color:(UIColor *)color
			   strokeColor:(UIColor *)strokeColor;

+ (CGSize)statusBarFrameViewSize;

+ (double)calculateAngleFrom:(CLLocationCoordinate2D)from
						  to:(CLLocationCoordinate2D)to
					location:(CLLocationCoordinate2D)location;

+ (void)startRotationAnimation:(UIView *)view allowUserInteraction:(BOOL)allowUserInteraction;

+ (void)stopRotationAnimation:(UIView *)view;

+ (UIImage *)rectangleImageForText:(NSString *)text
						 textColor:(UIColor *)textColor
						 fillColor:(UIColor *)fillColor
						  fontName:(NSString *)fontName
						  fontSize:(CGFloat)fontSize
						  xPadding:(CGFloat)xPadding;

+ (UIView *)subviewForView:(UIView *)view class:(Class)aClass;

+ (UIColor *)getColorWithRed:(CGFloat)red Greeen:(CGFloat)green Blue:(CGFloat)blue alpha:(CGFloat)alpha;

@end

/**
 @function RRComputeParameters
 @arg @c initial - initial coordinate
 @arg @c destination - final coordinate
 @arg @c distance - pointer to distance result (optional)
 @arg @c bearing - pointer to initial bearing result (optional)
 @arg @c destinationBearing - pointer to final distance result (optional)
 @brief Precise distance and src/dest bearings between coordinates
 @return absolute error (delta)
 **/
double RRComputeParameters(CLLocationCoordinate2D initial, CLLocationCoordinate2D destination, CLLocationDistance *distance, CLLocationDirection *bearing, CLLocationDirection *destinationBearing);
/// @brief azimuth˚
CLLocationDirection RRBearingIfHeadingTo(CLLocationCoordinate2D current, CLLocationCoordinate2D next);
/// @brief azimuth˚
CLLocationDirection RRBearingIfMovingFrom(CLLocationCoordinate2D current, CLLocationCoordinate2D previous);

RRCartesianCoordinate3D RRCartesianCoordinate3DMake(double x, double y, double z);

RRCartesianCoordinate3D RRCartesianFromCoordinate2D(CLLocationCoordinate2D coord);
CLLocationCoordinate2D RRMidpointCoordinate(CLLocationCoordinate2D coord1, CLLocationCoordinate2D coord2);
CLLocationCoordinate2D RRTranslateCoordinate(CLLocationCoordinate2D fromCoord, CLLocationDistance distance, CLLocationDirection bearing);

RRLocationBounds RRLocationBoundsMakeWithMinMax(CLLocationCoordinate2D min, CLLocationCoordinate2D max);
RRLocationBounds RRLocationBoundsMake(CLLocationDegrees minLatitude, CLLocationDegrees minLongitude, CLLocationDegrees maxLatitude, CLLocationDegrees maxLongitude);
RRLocationBounds RRLocationBoundsInset(RRLocationBounds sourceBounds, CLLocationDegrees dLatitude, CLLocationDegrees dLongitude);
RRLocationBounds RRLocationBoundsIncludeCoordinate(RRLocationBounds bounds, CLLocationCoordinate2D coordinate);

CGFloat RRPointDistance(CGPoint point1, CGPoint point2);
CGPoint RRSizeGetCenter(CGSize size);
CGPoint RRTruncatePointInBounds(CGPoint point, CGRect bounds);
NSComparisonResult RRCompareInteger(NSInteger left, NSInteger right);

NSString * NSStringFromBOOL(BOOL boolValue);

double RRRadiansFromDegrees(CLLocationDirection degrees);
CLLocationDirection RRDegreesFromRadians(double radians);
double RRMinorAngleBetweenDirections(double degreesA, double degreesB);
/// @brief Converts negative or out-of-scale angles into corresponding positive angles (e.g. -1° to 359° and 362° to 2°)
CLLocationDirection RRNormalizeDegrees(CLLocationDirection degrees);

NSString * RRWarningMessage(NSString *localizedString);

NSString * RRAppInstanceUDID();

float RRGetStatusBarHeight();

BOOL RRIsiPhone();
BOOL RRIsiPad();
BOOL RRIsRetina();
	
NSString * RRNilIfNull(NSString * string);
NSString * RRNotNull(NSString * string);
NSString * RRNotEmpty(NSString * string);

NSInteger RRGetPersistentInteger(NSString * key, int defaultValue);
void RRSetPersistentInteger(NSString * key, NSInteger value);
	
BOOL RRGetPersistentBool(NSString * key);
void RRSetPersistentBool(NSString * key, BOOL value);

void RRSignalCompletion(NSCondition * condition);
void RRWaitForCompletion(NSCondition * condition);
	
static const CGFloat RRGoldenRatioCoef = 1.61803398875f;
	
static const float RRDefaultVerticalMargin = 5.0;
static const float RRDefaultHorizontalMargin = 5;

