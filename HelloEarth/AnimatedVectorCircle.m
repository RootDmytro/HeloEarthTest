//
//  AnimatedVectorCircle.m
//  QuadEarth
//
//  Created by Dmytro Yaropovetsky on 10/20/17.
//  Copyright © 2017 HW Corporation. All rights reserved.
//

#import "AnimatedVectorCircle.h"
#import <MaplyScreenLabel.h>
#import "ActiveObjectAnimator.h"
#import "RRUtils.h"
//#import <WhirlyGlobe/SceneRendererES.h>
#import "NSMutableArray+Synchronized.h"
#import "MaplyVectorObject+Circle.h"

#define InterpolationLinear(initial, final, fraction) (initial * (1 - fraction) + final * fraction)

@class WhirlyKitRendererFrameInfo;

@interface AnimatedVectorCircle () <ActiveObjectAnimatorDelegate>

@property (nonatomic, assign) BOOL needsRecreation;

@property (nonatomic, strong) UIColor *colorObject;
@property (nonatomic, assign) CLLocationDistance radiusDistance;
@property (nonatomic, assign) CLLocationCoordinate2D centerCoordinate2D;

@property (nonatomic, strong, readwrite) MaplyComponentObject *vectorComponentObject;
@property (nonatomic, strong) NSMutableArray<ActiveObjectAnimator *> *animators;

@end

@implementation AnimatedVectorCircle

+ (instancetype)animatedVectorCircleWithRadius:(CLLocationDistance)radius
							centerCoordinate2D:(CLLocationCoordinate2D)centerCoordinate2D
								displayOptions:(NSDictionary *)displayOptions
							  inViewController:(MaplyBaseViewController *)inViewController {
	
	AnimatedVectorCircle *activeObject = [[self alloc] initWithViewController:inViewController];
	activeObject.radiusDistance = radius;
	activeObject.centerCoordinate2D = centerCoordinate2D;
	[activeObject recreateVector];
	activeObject.needsUpdate = YES; //so it gets added to the next frame
	
	activeObject.vectorDisplayOptions = displayOptions ?: @{kMaplyColor: [UIColor blueColor],
															kMaplySubdivType: kMaplySubdivStatic,
															kMaplySubdivEpsilon: @(0.001),
															kMaplyVecWidth: @(5),
															kMaplyFilled: kMaplyFilled,
															kMaplyDrawPriority: @(kMaplyVectorDrawPriorityDefault + 200)};
	
	return activeObject;
}

- (instancetype)initWithViewController:(MaplyBaseViewController *)viewC {
	self = [super initWithViewController:viewC];
	if (self != nil) {
		self.animators = [NSMutableArray new];
	}
	return self;
}

- (void)addAnimatorWithDuration:(NSTimeInterval)duration
			  modificationBlock:(void (^)(AnimatedVectorCircle *this, double fraction))modificationBlock
					animatedKey:(NSString *)animatedKey {
	
	__weak typeof(self) wself = self;
	ActiveObjectAnimator *newAnimator = [[ActiveObjectAnimator alloc] initWithDelegate:self
																			  duration:duration
																	 modificationBlock:^(double fraction) {
																		 modificationBlock(wself, fraction);
																	 }
																		   animatedKey:animatedKey];
	
	@synchronized (self.animators) {
		if (animatedKey != nil) {
			for (ActiveObjectAnimator *animator in self.animators.copy) {
				if ([animator.animatedKey isEqualToString:animatedKey]) {
					[animator complete];
				}
			}
		}
		
		[self.animators addObject:newAnimator];
	}
}

- (void)recreateVector {
	self.vector = [MaplyVectorObject circleVectorWithRadius:self.radiusDistance centerCoordinate:self.centerCoordinate2D];
	self.needsRecreation = NO;
}

- (void)setVectorDisplayOptions:(NSDictionary *)vectorDisplayOptions {
	_vectorDisplayOptions = vectorDisplayOptions;
	self.colorObject = vectorDisplayOptions[kMaplyColor] ?: self.colorObject;
}

#pragma mark - Color

- (UIColor *)color {
	return self.colorObject;
}

- (void)setColor:(UIColor *)color {
	self.color_ = color;
	self.needsUpdate = YES;
}

- (void)setColor_:(UIColor *)color {
	self.colorObject = color;
}

- (void)setColor:(UIColor *)color withDuration:(NSTimeInterval)duration {
	UIColor *initialColor = self.colorObject;
	
	CGFloat initialRed, initialGreen, initialBlue, initialAlpha;
	if (![initialColor getRed:&initialRed green:&initialGreen blue:&initialBlue alpha:&initialAlpha]) {
		NSAssert(!initialColor, @"could not convert color %@", initialColor);
	}
	
	CGFloat red, green, blue, alpha;
	if (![color getRed:&red green:&green blue:&blue alpha:&alpha]) {
		NSAssert(!color, @"could not convert color %@", color);
	}
	
	[self addAnimatorWithDuration:duration
				modificationBlock:^(AnimatedVectorCircle *this, double fraction) {
					CGFloat newRed = InterpolationLinear(initialRed, red, fraction);
					CGFloat newGreen = InterpolationLinear(initialGreen, green, fraction);
					CGFloat newBlue = InterpolationLinear(initialBlue, blue, fraction);
					CGFloat newAlpha = InterpolationLinear(initialAlpha, alpha, fraction);
					this.color_ = [UIColor colorWithRed:newRed green:newGreen blue:newBlue alpha:newAlpha];
					this.needsUpdate = YES;
				}
					  animatedKey:@"coordinate"];
}

#pragma mark - Coordinate2D

- (CLLocationCoordinate2D)coordinate2D {
	return self.centerCoordinate2D;
}

- (void)setCoordinate2D:(CLLocationCoordinate2D)coordinate2D {
	self.coordinate2D_ = coordinate2D;
	[self recreateVector];
	self.needsUpdate = YES;
}

- (void)setCoordinate2D_:(CLLocationCoordinate2D)coordinate2D {
	self.centerCoordinate2D = coordinate2D;
	self.needsRecreation = YES;
}

- (void)setCoordinate2D:(CLLocationCoordinate2D)coordinate2D withDuration:(NSTimeInterval)duration {
	CLLocationCoordinate2D initialCoordinate = self.coordinate2D;
	
	CLLocationDistance distance;
	CLLocationDirection bearing;
	RRComputeParameters(initialCoordinate, coordinate2D, &distance, &bearing, NULL);
	
	[self addAnimatorWithDuration:duration
				modificationBlock:^(AnimatedVectorCircle *this, double fraction) {
					this.coordinate2D_ = RRTranslateCoordinate(initialCoordinate, distance * fraction, bearing);
					this.needsUpdate = YES;
				}
					  animatedKey:@"coordinate"];
}

#pragma mark - MaplyCoordinate

- (MaplyCoordinate)coordinate {
	return MaplyCoordinateMakeWithDegrees(self.coordinate2D.longitude, self.coordinate2D.latitude);
}

- (void)setCoordinate:(MaplyCoordinate)coordinate {
	self.coordinate2D_ = CLLocationCoordinate2DMake(RRDegreesFromRadians(coordinate.y), RRDegreesFromRadians(coordinate.x));
	[self recreateVector];
	self.needsUpdate = YES;
}

- (void)setCoordinate:(MaplyCoordinate)coordinate withDuration:(NSTimeInterval)duration {
	[self setCoordinate2D:CLLocationCoordinate2DMake(RRDegreesFromRadians(coordinate.y),
													 RRDegreesFromRadians(coordinate.x))
			 withDuration:duration];
}

#pragma mark - Rotation

- (CLLocationDistance)radius {
	return self.radiusDistance;
}

- (void)setRadius:(double)radius {
	self.radius_ = radius;
	[self recreateVector];
	self.needsUpdate = YES;
}

- (void)setRadius_:(double)radius {
	self.radiusDistance = radius;
	self.needsRecreation = YES;
}

- (void)setRadius:(double)radius withDuration:(NSTimeInterval)duration {
	double initialRadius = self.radiusDistance;
	
	[self addAnimatorWithDuration:duration
				modificationBlock:^(AnimatedVectorCircle *this, double fraction) {
					this.radius_ = initialRadius * (1 - fraction) + radius * fraction;
					this.needsUpdate = YES;
				}
					  animatedKey:@"rotation"];
}

#pragma mark - ActiveObjectAnimatorDelegate

- (void)activeObjectAnimatorDidFinishAnimation:(ActiveObjectAnimator *)animator {
	[self.animators removeObjectSync:animator];
}

#pragma mark -

- (void)updateForFrame:(WhirlyKitRendererFrameInfo *)frameInfo {
	NSArray<ActiveObjectAnimator *> *animators = self.animators.copySync;
	
	for (ActiveObjectAnimator *animator in animators) {
		[animator animateFrame];
	}
	
	if (self.needsRecreation) {
		[self recreateVector];
	}
	
	if (self.needsUpdate && self.vector) {
		self.needsUpdate = NO;
		
		MaplyComponentObject *oldVectorObject = self.vectorComponentObject;
		
		if (self.vector) {
			NSMutableDictionary *vectorDisplayOptions = self.vectorDisplayOptions.mutableCopy;
			if (self.colorObject) {
				vectorDisplayOptions[kMaplyColor] = self.colorObject;
			}
			self.vectorComponentObject = [self.viewC addVectors:@[self.vector] desc:vectorDisplayOptions mode:MaplyThreadCurrent];
		}
		
		if (oldVectorObject) {
			[self.viewC removeObjects:@[oldVectorObject] mode:MaplyThreadCurrent];
		}
	}
}

- (void)shutdown {
	if (self.vectorComponentObject) {
		[self.viewC removeObjects:@[self.vectorComponentObject]
							 mode:MaplyThreadCurrent];
		self.vectorComponentObject = nil;
	}
}

- (bool)hasUpdate {
	return self.needsUpdate || self.animators.countSync;
}

@end
