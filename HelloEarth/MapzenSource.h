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

static const MapnikStyleType MapnikJSONStyle = 3;

typedef enum {MapzenSourceGeoJSON, MapzenSourcePBF } MapzenSourceType;


/**
 Mapzen Source type.  Handles fetching from Mapzen.
 
 Implements a paging delegate that can fetch Mapzen vector tile data.
 */
@interface MapzenSource : NSObject <MaplyPagingDelegate>

@property (nonatomic, assign) int minZoom;
@property (nonatomic, assign) int maxZoom;

// From the style sheet
@property (nonatomic) UIColor *backgroundColor;

/**
 Initialize with the base URL and the layers we want to fetch.
 */
- (instancetype)initWithBase:(NSString *)inBaseURL
					  layers:(NSArray *)inLayers
					  apiKey:(NSString *)apiKey
				  sourceType:(MapzenSourceType)inType
				   styleData:(NSData *)styleData
				   styleType:(MapnikStyleType)styleType
					   viewC:(MaplyBaseViewController *)viewC;

@end
