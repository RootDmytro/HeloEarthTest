//
//  Airways.h
//  RocketRoute
//
//  Created by Yuriy Levytskyy on 19.01.14.
//  Copyright (c) 2014 Rocket Route. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Airways : NSObject

@property(nonatomic, strong) NSNumber *sequence;
@property(nonatomic, strong) NSString *ident;
@property(nonatomic, strong) NSString *dest;
@property(nonatomic, strong) NSString *srcurn;
@property(nonatomic, strong) NSString *desturn;
@property(nonatomic, strong) NSString *state;
@property(nonatomic, strong) NSString *source;

@end
