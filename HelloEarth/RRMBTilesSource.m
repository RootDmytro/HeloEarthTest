//
//  MapzenSource.m
//  WhirlyGlobeComponentTester
//
//  Created by Steve Gifford on 11/20/14.
//  Copyright © 2014-2017 mousebird consulting. All rights reserved.
//

#import "RRMBTilesSource.h"
#import "RRMBTileFileReader.h"
#import <WhirlyGlobeComponent.h>


const CLLocationDistance RRSpecialEarthRadiusMeters = 6378137.0; // for MapboxVectorTileParser


@interface RRMBTilesSource ()

@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) RRMBTileFileReader *reader;
@property (nonatomic, strong) MapboxVectorTileParser *tileParser;

@end

@implementation RRMBTilesSource

- (instancetype)initWithFilePath:(NSString *)filePath {
	
	self = [self init];
	if (!self)
		return nil;
	
	self.minZoom = 0;
	self.maxZoom = 24;
	self.filePath = filePath;
	self.reader = [[RRMBTileFileReader alloc] initWithFilePath:self.filePath];
	
	return self;
}

- (instancetype)initWithFilePath:(NSString *)filePath viewC:(MaplyBaseViewController *)viewC {
	
	self = [self initWithFilePath:filePath];
	if (!self)
		return nil;
	
	NSString *minZoom = self.reader.metadata[RRMBTileMetadataMinZoomKey];
	if (minZoom) {
		self.minZoom = minZoom.intValue;
	}
	
	NSString *maxZoom = self.reader.metadata[RRMBTileMetadataMaxZoomKey];
	if (maxZoom) {
		self.maxZoom = maxZoom.intValue;
	}
	
	NSString *jsonStyle = self.reader.metadata[@"json"];
	NSData *styleData = [jsonStyle dataUsingEncoding:NSUTF8StringEncoding];
	
	styleData = [self fixStyle:styleData];
	
	if (styleData) {
		self.styleSet = [[MapnikStyleSet alloc] initForViewC:viewC];
		[self.styleSet loadJsonData:styleData];
		[self.styleSet generateStyles];
	}
	
	if (self.styleSet) {
		self.tileParser = [[MapboxVectorTileParser alloc] initWithStyle:self.styleSet viewC:viewC];
		self.tileParser.debugLabel = YES;
		self.tileParser.debugOutline = YES;
	}
	
	return self;
}

- (NSData *)fixStyle:(NSData *)data {
	NSError *error = nil;
	NSMutableDictionary *styleDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
	
	if (!styleDictionary && error) {
		NSLog(@"error: %@\n%@", error.localizedDescription, error);
		return data;
	}
	
	styleDictionary[@"styles"] = [self styles];
	
	NSMutableArray<NSMutableDictionary<NSString *, id> *> *layers = [styleDictionary[@"Layer"] mutableCopy];
	[self addStylesToLayers:layers];
	styleDictionary[@"layers"] = layers;
	
	NSData *fixedData = [NSJSONSerialization dataWithJSONObject:styleDictionary options:NSJSONWritingPrettyPrinted error:&error];
	
	if (!fixedData && error) {
		NSLog(@"error: %@\n%@", error.localizedDescription, error);
		return data;
	}
	
	return fixedData;
}

- (void)addStylesToLayers:(NSArray<NSMutableDictionary<NSString *, id> *> *)layers {
	for (NSMutableDictionary<NSString *, id> *layer in layers) {
		NSMutableArray<NSString *> *styles = layer[@"styles"];
		
		if (!styles || [styles isKindOfClass:NSMutableArray.class]) {
			styles = [NSMutableArray new];
		}
		
		[styles addObject:@"style_name1"];
		
		layer[@"styles"] = styles;
	}
}

- (NSArray<NSDictionary *> *)styles {
	NSArray<NSDictionary *> *symbolizers = [self symbolizers];
	NSDictionary *style = [self styleWithName:@"style_name1" symbolizers:symbolizers];
	
	return @[style];
}

- (NSDictionary *)styleWithName:(NSString *)styleName symbolizers:(NSArray<NSDictionary *> *)symbolizers {
	return @{
			 @"name": styleName,
			 @"rules": @[@{
							 @"symbolizers": symbolizers,
							 }],
			 };
}

- (NSArray<NSDictionary *> *)symbolizers {
	NSMutableArray<NSDictionary *> *symbolizers = [NSMutableArray new];
	
	NSArray<NSString *> *symbolizerTypes = @[@"LineSymbolizer", @"PolygonSymbolizer", @"TextSymbolizer", @"MarkersSymbolizer"];
	for (NSString *symbolizerType in symbolizerTypes) {
		[symbolizers addObject:[self symbolizerOfType:symbolizerType]];
	}
	
	return symbolizers;
}

- (NSDictionary *)symbolizerOfType:(NSString *)type {
	return @{@"type": type};
}

#pragma mark - MaplyPagingDelegate

- (void)startFetchForTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self fetchTile:tileID forLayer:layer];
	});
}

#pragma mark -

- (void)fetchTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer {
	NSData *data = [self.reader dataForTileAtZoomLevel:tileID.level column:tileID.x row:tileID.y];
	
	MaplyBoundingBox bbox;
	MaplyBoundingBox geoBounds;
	
	// The tile parser wants bounds in meters(ish)
	[layer boundsforTile:tileID ll:&bbox.ll ur:&bbox.ur];
	geoBounds = bbox;
//	bbox.ll.x *= 20037508.342789244/M_PI;
//	bbox.ll.y *= 20037508.342789244/M_PI;
//	bbox.ur.x *= 20037508.342789244/M_PI;
//	bbox.ur.y *= 20037508.342789244/M_PI;
	bbox.ll.x *= RRSpecialEarthRadiusMeters;
	bbox.ll.y *= RRSpecialEarthRadiusMeters;
	bbox.ur.x *= RRSpecialEarthRadiusMeters;
	bbox.ur.y *= RRSpecialEarthRadiusMeters;
	
	data = data.mutableCopy;
	
	MaplyVectorTileData *tileData = [self.tileParser buildObjects:data tile:tileID bounds:bbox geoBounds:geoBounds];
	if (tileData.compObjs.count)
		[layer addData:tileData.compObjs forTile:tileID];
	
	[layer tileDidLoad:tileID];
}

@end
