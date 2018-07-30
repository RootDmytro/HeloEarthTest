//
//  TileSourceLibrary.h
//  HelloEarth
//
//  Created by Dmytro Yaropovetsky on 1/23/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MaplyMBTileSource.h>
#import <MaplyRemoteTileSource.h>

@interface TileSourceItem : NSObject

@property (nonatomic, strong, readonly) NSString *sourceUrl;
@property (nonatomic, strong, readonly) NSString *ext;
@property (nonatomic, strong, readonly) NSString *sourceDescription;
@property (nonatomic, strong, readonly) NSString *sourceDetails;
@property (nonatomic, assign, readonly) int maxZoom;

+ (instancetype)itemWithSourceUrl:(NSString *)sourceUrl ext:(NSString *)ext maxZoom:(int)maxZoom sourceDescription:(NSString *)sourceDescription sourceDetails:(NSString *)sourceDetails delay:(NSTimeInterval)delay;

- (NSObject<MaplyTileSource> *)makeSource;

@end

@interface TileSourceLibrary : NSObject

+ (NSObject<MaplyTileSource> *)baseTileSource;

+ (NSArray<TileSourceItem *> *)sources;
+ (NSArray<TileSourceItem *> *)overlays;

@end
