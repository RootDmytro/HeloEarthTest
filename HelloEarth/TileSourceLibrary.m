//
//  TileSourceLibrary.m
//  HelloEarth
//
//  Created by Dmytro Yaropovetsky on 1/23/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import "TileSourceLibrary.h"
#import "NSString+Crypto.h"

@interface TileSourceItem ()

@property (nonatomic, strong) NSString *sourceUrl;
@property (nonatomic, strong) NSString *ext;
@property (nonatomic, strong) NSString *sourceDescription;
@property (nonatomic, strong) NSString *sourceDetails;
@property (nonatomic, assign) int maxZoom;
@property (nonatomic, assign) NSTimeInterval delay;

@end

@implementation TileSourceItem

+ (NSDateFormatter *)dateFormatter {
	static NSDateFormatter *dateFormatter = nil;
	if (!dateFormatter) {
		dateFormatter = [NSDateFormatter new];
		dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
		dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		dateFormatter.dateFormat = @"yyyy-MM-dd";
	}
	return dateFormatter;
}

+ (instancetype)itemWithSourceUrl:(NSString *)sourceUrl ext:(NSString *)ext maxZoom:(int)maxZoom sourceDescription:(NSString *)sourceDescription sourceDetails:(NSString *)sourceDetails delay:(NSTimeInterval)delay {
	TileSourceItem *item = [self new];
	item.sourceUrl = sourceUrl;
	item.ext = ext;
	item.maxZoom = maxZoom;
	item.sourceDescription = sourceDescription;
	item.sourceDetails = sourceDetails;
	item.delay = delay;
	return item;
}

- (NSObject<MaplyTileSource> *)makeSource {
	// Because this is a remote tile set, we'll want a cache directory
	NSString *baseCacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
	NSString *tilesCacheDir = [baseCacheDir stringByAppendingPathComponent:@"stamentiles"];
	tilesCacheDir = [baseCacheDir stringByAppendingPathComponent:self.sourceUrl.md5];
	
	// Stamen Terrain Tiles, courtesy of Stamen Design under the Creative Commons Attribution License.
	// Data by OpenStreetMap under the Open Data Commons Open Database License.
	
	NSString *today = [self.class.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-self.delay]];
	NSString *sourceUrl = [NSString stringWithFormat:self.sourceUrl, today];
	MaplyRemoteTileSource *tileSource = [[MaplyRemoteTileSource alloc] initWithBaseURL:sourceUrl
																				   ext:self.ext
																			   minZoom:0
																			   maxZoom:self.maxZoom];
	tileSource.cacheDir = tilesCacheDir;
	
	return tileSource;
}

@end

@interface NASASourceItem : TileSourceItem

+ (instancetype)NASAItemWithExt:(NSString *)ext level:(int)level layer:(NSString *)layer;
+ (instancetype)NASAItemWithExt:(NSString *)ext level:(int)level layer:(NSString *)layer delay:(NSTimeInterval)delay;

@end

@implementation NASASourceItem

+ (instancetype)NASAItemWithExt:(NSString *)ext level:(int)level layer:(NSString *)layer {
	return [self NASAItemWithExt:ext level:level layer:layer delay:0];
}

+ (instancetype)NASAItemWithExt:(NSString *)ext level:(int)level layer:(NSString *)layer delay:(NSTimeInterval)delay {
	NSMutableArray<NSString *> *components = [layer componentsSeparatedByString:@"_"].mutableCopy;
	NSString *instrument = components.firstObject;
	if (components.count > 0) {
		[components removeObjectAtIndex:0];
	}
	
	return [self itemWithSourceUrl:[NSString stringWithFormat:@"http://map1.vis.earthdata.nasa.gov/wmts-webmerc/%@/default/%%@/GoogleMapsCompatible_Level%i/{z}/{y}/{x}", layer, level]
							   ext:ext
						   maxZoom:level
				 sourceDescription:[components componentsJoinedByString:@" "]
					 sourceDetails:[NSString stringWithFormat:@"nasa.gov/ %@ / %@", instrument, ext]
							 delay:delay];
}

@end


@interface TileSourceLibrary ()

@property (nonatomic, strong) NSArray<TileSourceItem *> *sources;
@property (nonatomic, strong) NSArray<TileSourceItem *> *overlays;
@property (nonatomic, strong) NSObject<MaplyTileSource> *baseTileSource;

@end

@implementation TileSourceLibrary

TileSourceLibrary *tileSourceLibrary;

+ (TileSourceLibrary *)sharedInstance {
	if (!tileSourceLibrary) {
		tileSourceLibrary = [self new];
	}
	return tileSourceLibrary;
}

+ (NSObject<MaplyTileSource> *)baseTileSource {
	return self.sharedInstance.baseTileSource;
}

+ (NSArray<TileSourceItem *> *)sources {
	return self.sharedInstance.sources;
}

+ (NSArray<TileSourceItem *> *)overlays {
	return self.sharedInstance.overlays;
}

- (NSObject<MaplyTileSource> *)baseTileSource {
	if (!_baseTileSource) {
		self.baseTileSource = [[MaplyMBTileSource alloc] initWithMBTiles:@"geography-class_medres"];
	}
	return _baseTileSource;
}

/// http://map1.vis.earthdata.nasa.gov/{Projection}/{ProductName}/default/{Time}/{TileMatrixSet}/{ZoomLevel}/{TileRow}/{TileCol}.png

- (NSArray<TileSourceItem *> *)sources {
	if (!_sources) {
		self.sources = @[[TileSourceItem itemWithSourceUrl:@"http://tile.stamen.com/terrain/" ext:@"png" maxZoom:18
										 sourceDescription:@"Terrain" sourceDetails:@"stamen.com" delay:0],
						 [NASASourceItem NASAItemWithExt:@"jpg" level:9 layer:@"MODIS_Terra_CorrectedReflectance_TrueColor" delay:1 * 24 * 60 * 60],
						 [NASASourceItem NASAItemWithExt:@"jpg" level:8 layer:@"VIIRS_CityLights_2012" delay:1 * 24 * 60 * 60]];
	}
	return _sources;
}

- (NSArray<TileSourceItem *> *)overlays {
	if (!_overlays) {
		self.overlays = @[[NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"GHRSST_L4_MUR_Sea_Surface_Temperature" delay:2 * 24 * 60 * 60],
						  [NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"GHRSST_L4_G1SST_Sea_Surface_Temperature" delay:2 * 24 * 60 * 60],
						  [NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"MODIS_Terra_Land_Surface_Temp_Day"],
						  [NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"MODIS_Terra_Land_Surface_Temp_Day" delay:1 * 24 * 60 * 60],
						  [NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"MODIS_Terra_Chlorophyll_A" delay:25 * 24 * 60 * 60],
						  [NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"MODIS_Aqua_Chlorophyll_A" delay:25 * 24 * 60 * 60],
						  [NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"MODIS_Terra_Cloud_Optical_Thickness" delay:1 * 24 * 60 * 60],
						  [NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"MODIS_Terra_Cloud_Optical_Thickness_PCL" delay:1 * 24 * 60 * 60],
						  [NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"MODIS_Aqua_Cloud_Optical_Thickness" delay:1 * 24 * 60 * 60],
						  [NASASourceItem NASAItemWithExt:@"png" level:7 layer:@"MODIS_Aqua_Cloud_Optical_Thickness_PCL" delay:1 * 24 * 60 * 60],];
	}
	return _overlays;
}

@end
