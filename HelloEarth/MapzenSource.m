//
//  MapzenSource.m
//  WhirlyGlobeComponentTester
//
//  Created by Steve Gifford on 11/20/14.
//  Copyright © 2014-2017 mousebird consulting. All rights reserved.
//

#import "MapzenSource.h"
//#import <vector_tiles/MapnikStyleSet.h>
//#import "SLDStyleSet.h"
//#import "vector_tiles/MapboxVectorTiles.h"
#import <WhirlyGlobeComponent.h>


@interface MapzenSource ()

@property (nonatomic, copy) NSString *baseURL;
@property (nonatomic, copy) NSArray<NSString *> *layers;
@property (nonatomic, copy) NSString *apiKey;

@property (nonatomic, strong, readonly) NSOperationQueue *opQueue;

@property (nonatomic, copy) NSString *ext;
@property (nonatomic, strong) MapboxVectorTileParser *tileParser;
@property (nonatomic, strong) NSObject<MaplyVectorStyleDelegate> *styleSet;

@property (nonatomic, copy, readonly) NSString *cacheDirectory;

@end

@implementation MapzenSource

- (instancetype)init {
	self = [super init];
	if (!self)
		return nil;
	
	_opQueue = [[NSOperationQueue alloc] init];
	_cacheDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	
	return self;
}

- (instancetype)initWithBase:(NSString *)inBaseURL
					  layers:(NSArray *)inLayers
					  apiKey:(NSString *)inApiKey {
	
	self = [self init];
	if (!self)
		return nil;
	
	self.baseURL = inBaseURL;
	self.layers = inLayers;
	self.apiKey = inApiKey;
	
	return self;
}

- (instancetype)initGeoJSONSourceWithBaseURL:(NSString *)inBaseURL
									  layers:(NSArray *)inLayers
									  apiKey:(NSString *)inApiKey {
	self = [self initWithBase:inBaseURL layers:inLayers apiKey:inApiKey];
	if (!self)
		return nil;
	
	self.ext = @"json";
	
	return self;
}

- (instancetype)initPBFSourceWithBaseURL:(NSString *)inBaseURL
								  layers:(NSArray *)inLayers
								  apiKey:(NSString *)inApiKey
							   styleData:(NSData *)styleData
							   styleType:(MapnikStyleType)styleType
								   viewC:(MaplyBaseViewController *)viewC {
	
	self = [self initWithBase:inBaseURL layers:inLayers apiKey:inApiKey];
	if (!self)
		return nil;
	
	self.ext = @"mvt";
	
	switch (styleType)
	{
		case MapnikXMLStyle:
		{
			MapnikStyleSet *mapnikStyleSet = [[MapnikStyleSet alloc] initForViewC:viewC];
			[mapnikStyleSet loadXmlData:styleData];
			[mapnikStyleSet generateStyles];
			self.styleSet = mapnikStyleSet;
		}
			break;
			
		case MapnikJSONStyle:
		{
			MapnikStyleSet *mapnikStyleSet = [[MapnikStyleSet alloc] initForViewC:viewC];
			[mapnikStyleSet loadJsonData:styleData];
			[mapnikStyleSet generateStyles];
			self.styleSet = mapnikStyleSet;
		}
			break;
			
		case MapnikSLDStyle:
		{
			// The simple version will display everything
			//                    MaplyVectorStyleSimpleGenerator *simpleSet = [[MaplyVectorStyleSimpleGenerator alloc] initWithViewC:viewC];
			//                    styleSet = simpleSet;
			// This version uses an SLD
			SLDStyleSet *sldStyleSet = [[SLDStyleSet alloc] initWithViewC:viewC useLayerNames:NO relativeDrawPriority:0];
			[sldStyleSet loadSldData:styleData baseURL:[NSURL URLWithString:self.baseURL]];
			self.styleSet = sldStyleSet;
		}
			break;
	}
	
	// Create a tile parser for later
	self.tileParser = [[MapboxVectorTileParser alloc] initWithStyle:self.styleSet viewC:viewC];
	
	return self;
}

#pragma mark - MaplyPagingDelegate

- (void)startFetchForTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		if (self.tileParser) {
			[self fetchMVTForTile:tileID forLayer:layer];
		} else {
			[self fetchGeoJSONForTile:tileID forLayer:layer];
		}
	});
}

#pragma mark -

- (void)fetchMVTForTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer {
	int y = (1<<tileID.level)-tileID.y-1;
	// We can fetch one vector.pbf
	NSString *allLayers = [self.layers componentsJoinedByString:@","];
	
	NSString *fullUrl = [NSString stringWithFormat:@"%@/%@/%d/%d/%d.%@", self.baseURL, allLayers, tileID.level, tileID.x, y, self.ext];
	if (self.apiKey)
		fullUrl = [NSString stringWithFormat:@"%@?api_key=%@", fullUrl, self.apiKey];
	
	NSString *fullPath = [NSString stringWithFormat:@"%@/%@_level%d_%d_%d.%@", self.cacheDirectory, allLayers, tileID.level, tileID.x, y, self.ext];
	
	//ADD APPROPRIATE FETCHING MECHANISM FROM SQLite MBTiles file
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
		
		NSData *data = [NSData dataWithContentsOfFile:fullPath];
		
		[self addData:data toLayer:layer forTile:tileID];
	} else {
		NSURL *url = [NSURL URLWithString:fullUrl];
		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
		
		[NSURLConnection sendAsynchronousRequest:urlRequest queue:self.opQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			if (!connectionError) {
				// Cache the file
				[data writeToFile:fullPath atomically:NO];
				
				[self addData:data toLayer:layer forTile:tileID];
			} else {
				[layer tileFailedToLoad:tileID];
			}
		}];
	}
}

- (void)addData:(NSData *)data toLayer:(MaplyQuadPagingLayer *)layer forTile:(MaplyTileID)tileID {
	MaplyBoundingBox bbox;
	// The tile parser wants bounds in meters(ish)
	[layer boundsforTile:tileID ll:&bbox.ll ur:&bbox.ur];
	bbox.ll.x *= 20037508.342789244/M_PI;
	bbox.ll.y *= 20037508.342789244/(M_PI);
	bbox.ur.x *= 20037508.342789244/M_PI;
	bbox.ur.y *= 20037508.342789244/(M_PI);
	
	MaplyVectorTileData *tileData = [self.tileParser buildObjects:data tile:tileID bounds:bbox geoBounds:bbox];
	if (tileData.compObjs)
		[layer addData:tileData.compObjs forTile:tileID];
	
	[layer tileDidLoad:tileID];
}

- (void)fetchGeoJSONForTile:(MaplyTileID)tileID forLayer:(MaplyQuadPagingLayer *)layer {
	int y = (1<<tileID.level)-tileID.y-1;
	// Fetch GeoJSON individually
	[layer tile:tileID hasNumParts:(int)[self.layers count]];
	
	// Work through the layers
	int partID = 0;
	for (NSString *layerName in self.layers)
	{
		NSString *fullUrl = [NSString stringWithFormat:@"%@/%@/%d/%d/%d.%@", self.baseURL, layerName, tileID.level, tileID.x, y, self.ext];
		NSString *fileName = [NSString stringWithFormat:@"%@_level%d_%d_%d.%@", layerName, tileID.level, tileID.x, y, self.ext];
		NSString *fullPath = [NSString stringWithFormat:@"%@/%@", self.cacheDirectory, fileName];
		NSURL *url = [NSURL URLWithString:fullUrl];
		NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
		
		[NSURLConnection sendAsynchronousRequest:urlRequest queue:self.opQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			if (!connectionError)
			{
				// Expecting GeoJSON
				MaplyVectorObject *vecObj = [[MaplyVectorObject alloc] initWithGeoJSON:data];
				
				if (vecObj)
				{
					// Save it to storage
					[data writeToFile:fullPath atomically:NO];
					
					// Display it
					MaplyComponentObject *compObj = [layer.viewC addVectors:@[vecObj]
																	   desc:@{kMaplyEnable: @(NO)}
																	   mode:MaplyThreadCurrent];
					if (compObj)
						[layer addData:@[compObj] forTile:tileID];
				}
			}
			
			[layer tileDidLoad:tileID part:partID];
		}];
		
		partID++;
	}
}

@end
