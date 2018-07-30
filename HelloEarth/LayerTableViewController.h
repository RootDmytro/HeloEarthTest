//
//  LayerTableViewController.h
//  HelloEarth
//
//  Created by Dmytro Yaropovetsky on 1/23/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TileSourceLibrary.h"

@class LayerTableViewController;

@protocol LayerTableViewControllerDelegate <NSObject>

- (void)layerTable:(LayerTableViewController *)layerTable didSelectSource:(NSObject<MaplyTileSource> *)source isOverlay:(BOOL)isOverlay;
- (void)layerTable:(LayerTableViewController *)layerTable didDeselectSource:(NSObject<MaplyTileSource> *)source isOverlay:(BOOL)isOverlay;

@end

@interface LayerTableViewController : UIViewController

@property (nonatomic, weak) id<LayerTableViewControllerDelegate> delegate;

@property (nonatomic, weak) TileSourceItem *selectedLayer;
@property (nonatomic, weak) TileSourceItem *selectedOverlay;

- (void)reloadData;

@end
