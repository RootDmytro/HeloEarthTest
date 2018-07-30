//
//  RRMBTileFileReader.h
//  RocketRoute
//
//  Created by Dmytro Yaropovetsky on 4/30/18.
//  Copyright © 2018 Rocket Route. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

extern NSString * const RRMBTileMetadataProfileKey;
extern NSString * const RRMBTileMetadataScaleKey;
extern NSString * const RRMBTileMetadataDescriptionKey;
extern NSString * const RRMBTileMetadataFormatKey;
extern NSString * const RRMBTileMetadataBoundsKey;
extern NSString * const RRMBTileMetadataMinZoomKey;
extern NSString * const RRMBTileMetadataVersionKey;
extern NSString * const RRMBTileMetadataMaxZoomKey;
extern NSString * const RRMBTileMetadataTypeKey;
extern NSString * const RRMBTileMetadataNameKey;


@interface RRMBTileFileReader : NSObject

- (instancetype)initWithFilePath:(NSString *)filePath;

- (NSDictionary<NSString *, NSString *> *)metadata;

- (BOOL)fixMetadataBoundsFormat;

- (NSData *)dataForTileAtZoomLevel:(int)zoomLevel column:(int)column row:(int)row;

@end

NS_ASSUME_NONNULL_END
