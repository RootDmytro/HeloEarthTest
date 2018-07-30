//
//  LayerTableViewController.m
//  HelloEarth
//
//  Created by Dmytro Yaropovetsky on 1/23/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import "LayerTableViewController.h"

@interface LayerTableViewController ()

@property (nonatomic, strong) NSArray<NSArray<TileSourceItem *> *> *sections;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

typedef enum : NSUInteger {
	LayerTableSectionLayers = 0,
	LayerTableSectionOverlays,
} LayerTableSection;

@implementation LayerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self reloadData];
	[self.tableView reloadData];
}

- (void)reloadData {
	self.sections = @[[TileSourceLibrary sources], [TileSourceLibrary overlays]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return @[@"Layers", @"Overlays"][section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
	
	TileSourceItem *item = self.sections[indexPath.section][indexPath.row];
	cell.textLabel.text = item.sourceDescription;
	cell.detailTextLabel.text = item.sourceDetails;
	
	cell.accessoryType = (item == self.selectedLayer || item == self.selectedOverlay) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
    return cell;
}

- (void)reloadSelections {
	for (NSIndexPath *visibleIndexPath in self.tableView.indexPathsForVisibleRows) {
		NSUInteger index = NSNotFound;
		
		if (visibleIndexPath.section == LayerTableSectionOverlays && self.selectedOverlay) {
			index = [self.sections[visibleIndexPath.section] indexOfObject:self.selectedOverlay];
		} else if (visibleIndexPath.section == LayerTableSectionLayers && self.selectedLayer) {
			index = [self.sections[visibleIndexPath.section] indexOfObject:self.selectedLayer];
		}
		
		if (index != NSNotFound) {
			[self.tableView cellForRowAtIndexPath:visibleIndexPath].accessoryType =
			visibleIndexPath.row == index ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
		}
	}
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	BOOL isSelected = cell.accessoryType == UITableViewCellAccessoryCheckmark;
	
	NSArray<TileSourceItem *> *section = self.sections[indexPath.section];
	TileSourceItem *item = section[indexPath.row];
	
	BOOL isOverlay = indexPath.section == LayerTableSectionOverlays;
	
	UITableViewCellAccessoryType accessoryType = UITableViewCellAccessoryNone;
	if (isSelected) {
		accessoryType = UITableViewCellAccessoryNone;
		[self.delegate layerTable:self didDeselectSource:[item makeSource] isOverlay:isOverlay];
		
		if (isOverlay) {
			self.selectedOverlay = nil;
		} else {
			self.selectedLayer = nil;
		}
	} else {
		accessoryType = UITableViewCellAccessoryCheckmark;
		[self.delegate layerTable:self didSelectSource:[item makeSource] isOverlay:isOverlay];
		
		if (isOverlay) {
			self.selectedOverlay = item;
		} else {
			self.selectedLayer = item;
		}
	}
	cell.accessoryType = accessoryType;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self reloadSelections];
	});
}

@end
