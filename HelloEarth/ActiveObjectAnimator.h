//
//  ActiveObjectAnimator.h
//  RocketEarth
//
//  Created by Dmytro Yaropovetsky on 10/23/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ActiveObjectAnimatorDelegate;

@interface ActiveObjectAnimator : NSObject

@property (nonatomic, copy) NSString *animatedKey;
@property (nonatomic, copy) void (^completionBlock)(void);

- (instancetype)initWithDelegate:(id<ActiveObjectAnimatorDelegate>)delegate
						duration:(NSTimeInterval)duration
			   modificationBlock:(void (^)(double fraction))modificationBlock;

- (instancetype)initWithDelegate:(id<ActiveObjectAnimatorDelegate>)delegate
						duration:(NSTimeInterval)duration
			   modificationBlock:(void (^)(double fraction))modificationBlock
					 animatedKey:(NSString *)animatedKey;

- (void)animateFrame;

- (void)complete;

@end


@protocol ActiveObjectAnimatorDelegate

- (void)activeObjectAnimatorDidFinishAnimation:(ActiveObjectAnimator *)animator;

@end
