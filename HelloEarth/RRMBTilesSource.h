//
//  MapzenSource.h
//  WhirlyGlobeComponentTester
//
//  Created by Steve Gifford on 11/20/14.
//  Copyright © 2014-2017 mousebird consulting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaplyBaseViewController.h>
#import <MaplyQuadPagingLayer.h>
#import <WhirlyGlobeComponent.h>


/**
 Mapzen Source type.  Handles fetching from Mapzen.
 
 Implements a paging delegate that can fetch Mapzen vector tile data.
 */
@interface RRMBTilesSource : NSObject <MaplyPagingDelegate>

@property (nonatomic, strong) MapnikStyleSet *styleSet;

@property (nonatomic, assign) int minZoom;
@property (nonatomic, assign) int maxZoom;

// From the style sheet
@property (nonatomic, strong) UIColor *backgroundColor;

- (instancetype)initWithFilePath:(NSString *)filePath viewC:(MaplyBaseViewController *)viewC;

@end
