//
//  ActiveObjectAnimator.m
//  RocketEarth
//
//  Created by Dmytro Yaropovetsky on 10/23/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import "ActiveObjectAnimator.h"

@interface ActiveObjectAnimator ()

@property (nonatomic, weak) id<ActiveObjectAnimatorDelegate> delegate;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, copy) void (^modificationBlock)(double fraction);
@property (nonatomic, copy) NSDate *animationEndDate;

@end

@implementation ActiveObjectAnimator

- (instancetype)initWithDelegate:(id<ActiveObjectAnimatorDelegate>)delegate
						duration:(NSTimeInterval)duration
			   modificationBlock:(void (^)(double fraction))modificationBlock {
	self = [self init];
	if (self) {
		self.delegate = delegate;
		self.animationEndDate = [NSDate dateWithTimeIntervalSinceNow:duration];
		self.duration = duration;
		self.modificationBlock = modificationBlock;
	}
	return self;
}

- (instancetype)initWithDelegate:(id<ActiveObjectAnimatorDelegate>)delegate
						duration:(NSTimeInterval)duration
			   modificationBlock:(void (^)(double fraction))modificationBlock
					 animatedKey:(NSString *)animatedKey {
	self = [self initWithDelegate:delegate duration:duration modificationBlock:modificationBlock];
	if (self) {
		self.animatedKey = animatedKey;
	}
	return self;
}

- (void)animateFrame {
	NSTimeInterval timeRemaining = MAX(0, self.animationEndDate.timeIntervalSinceNow);
	double fraction = 1 - (self.duration <= 0 ? 0 : timeRemaining / self.duration);
	self.modificationBlock(fraction);
	
	if (timeRemaining == 0) {
		[self complete];
	}
}

- (void)complete {
	if (self.completionBlock) {
		self.completionBlock();
	}
	
	[self.delegate activeObjectAnimatorDidFinishAnimation:self];
}

@end
