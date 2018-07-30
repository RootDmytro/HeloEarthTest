//
//  ViewController.m
//  HelloEarth
//
//  Created by Dmytro Yaropovetsky on 1/20/17.
//  Copyright © 2017 yar. All rights reserved.
//

#import "ViewController.h"
#import <WhirlyGlobeViewController.h>
#import <MaplyViewController.h>
#import <MaplyMBTileSource.h>
#import <MaplyRemoteTileSource.h>
#import <MaplyScreenLabel.h>
#import <MaplyVectorObject.h>
#import "TileSourceLibrary.h"
#import "LayerTableViewController.h"
#import "RRAirportsDatabase.h"
#import "NSString+Crypto.h"
#import "ActiveMarker.h"
#import "MapAircraft.h"
#import "AnimatedVectorCircle.h"
#import "RRUtils.h"
#import "MapzenSource.h"
#import "RRMBTilesSource.h"


@interface ViewController () <LayerTableViewControllerDelegate, WhirlyGlobeViewControllerDelegate>

@property (nonatomic, strong) WhirlyGlobeViewController *globeViewController;
@property (nonatomic, strong) LayerTableViewController *layersMenuController;
@property (nonatomic, strong) NSLayoutConstraint *layersMenuConstraint;
@property (nonatomic, strong) NSDictionary *vectorParameters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MaplyComponentObject *> *components;
@property (nonatomic, assign) BOOL isMenuOpen;

@property (nonatomic, strong) MaplyQuadImageTilesLayer *baseLayer;
@property (nonatomic, strong) MaplyQuadImageTilesLayer *overlayLayer;

@property (nonatomic, strong) NSTimer *aircraftsAnimationTimer;
@property (nonatomic, strong) NSMutableArray<MapAircraft *> *aircrafts;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.components = [NSMutableDictionary new];
	self.aircrafts = [NSMutableArray new];
	
	self.globeViewController = [WhirlyGlobeViewController new];
	
	[self.globeViewController willMoveToParentViewController:self];
	
	self.globeViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.globeViewController.view.frame = self.view.bounds;
	[self.view addSubview:self.globeViewController.view];
	[self addChildViewController:self.globeViewController];
	
	[self.globeViewController didMoveToParentViewController:self];
	
	self.globeViewController.delegate = self;
	
	self.aircraftsAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(animationAircrafts:) userInfo:nil repeats:YES];
	
	[self setupMenuController];
	
	[self startup];
}

- (void)animationAircrafts:(NSTimer *)sender {
	for (MapAircraft *aircraft in self.aircrafts.copy) {
		[aircraft fly];
	}
}

- (void)loadMapzenSource:(NSString *)path {
	RRMBTilesSource *MBTilesSource = [[RRMBTilesSource alloc] initWithFilePath:path viewC:self.globeViewController];
	
	MaplyMBTileSource *tileSource = [[MaplyMBTileSource alloc] initWithMBTiles:path];
	NSObject<MaplyVectorStyleDelegate> *styleSet = MBTilesSource.styleSet;
	
	MapboxVectorTilesPagingDelegate *delegate = [[MapboxVectorTilesPagingDelegate alloc] initWithMBTiles:tileSource
																								   style:styleSet
																								   viewC:self.globeViewController];
	
	// Now for the paging layer itself
	MaplyQuadPagingLayer *pageLayer = [[MaplyQuadPagingLayer alloc] initWithCoordSystem:[[MaplySphericalMercator alloc] initWebStandard] delegate:delegate];
	pageLayer.numSimultaneousFetches = 8;
	pageLayer.flipY = false;
	pageLayer.importance = 512*512;
	pageLayer.useTargetZoomLevel = true;
	pageLayer.singleLevelLoading = true;
	[self.globeViewController addLayer:pageLayer];
}

- (void)startup {
	// we want a black background for a globe, a white background for a map.
	self.globeViewController.clearColor = [UIColor blackColor];
	
	// and thirty fps if we can get it ­ change this to 3 if you find your app is struggling
	self.globeViewController.frameInterval = 2;
	
	self.globeViewController.keepNorthUp = YES; // .tilt
	
//	{
//		const bool useLocalTiles = false;
//		// set up the data source
//		NSObject<MaplyTileSource> *tileSource;
//		if (useLocalTiles) {
//			tileSource = [[MaplyMBTileSource alloc] initWithMBTiles:@"geography-class_medres"];
//		} else {
//			tileSource = [[TileSourceLibrary sources][0] makeSource];
//		}
//		[self addLayerWithWithSource:tileSource forOverlay:false];
//	}
//
//	{
//		NSObject<MaplyTileSource> *tileSource = [[TileSourceLibrary overlays][1] makeSource];
//		[self addLayerWithWithSource:tileSource forOverlay:true];
//	}

	self.globeViewController.height = 0.8;
	[self.globeViewController animateToPosition:MaplyCoordinateMakeWithDegrees(32.4192, 49.7793) time:1.0];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		NSString *navdataPath = nil;
		NSString *basemapPath = nil;
		NSString *OFMAGermanyPath = nil;
		NSArray<NSString *> *allMBTiles = [[NSBundle mainBundle] pathsForResourcesOfType:@"mbtiles" inDirectory:nil];
		
		for (NSString *tilesFile in allMBTiles) {
			
			if ([tilesFile.lastPathComponent isEqualToString:@"navdata.mbtiles"]) {
				navdataPath = tilesFile;
			}
			
			if ([tilesFile.lastPathComponent isEqualToString:@"osmbasemap.mbtiles"]) {
				basemapPath = tilesFile;
			}
			
			if ([tilesFile.lastPathComponent isEqualToString:@"OFMA Germany Special ED.mbtiles"]) {
				OFMAGermanyPath = tilesFile;
			}
		}
		
		if (navdataPath) {
			[self loadMapzenSource:navdataPath];
		}
		
		[self addMBTiles:basemapPath
				priority:2
			 imageFormat:MaplyImage4Layer8Bit];
		
		[self addMBTiles:OFMAGermanyPath
				priority:kMaplyImageLayerDrawPriorityDefault
			 imageFormat:MaplyImage4Layer8Bit]; // MaplyImageUShort4444, MaplyImageUShort5551, MaplyImage4Layer8Bit
		
		[self addCountries];
		//[self addBars];
//		[self addRadios];
//		[self addAirports];
//
//		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//			[self addAircrafts];
//		});
//		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//			[self addVectors];
//		});
	});
}

// use the local tiles or remote tiles
- (MaplyQuadImageTilesLayer *)addLayerWithWithSource:(NSObject<MaplyTileSource> *)tileSource forOverlay:(bool)forOverlay {
	MaplyQuadImageTilesLayer *layer = [[MaplyQuadImageTilesLayer alloc] initWithCoordSystem:tileSource.coordSys
																				 tileSource:tileSource];
	if (forOverlay) {
		layer.coverPoles = false;
		layer.handleEdges = false;
		layer.drawPriority = kMaplyImageLayerDrawPriorityDefault + 1;
		self.overlayLayer = layer;
	} else {
		layer.coverPoles = true;
		layer.handleEdges = true;
		
		layer.requireElev = false;
		layer.waitLoad = false;
		layer.drawPriority = kMaplyImageLayerDrawPriorityDefault;
		layer.singleLevelLoading = false;
		self.baseLayer = layer;
	}
	[self.globeViewController addLayer:layer];
	return layer;
}

// use the local tiles or remote tiles
- (void)removeLayerForOverlay:(bool)forOverlay {
	MaplyQuadImageTilesLayer *layer = forOverlay ? self.overlayLayer : self.baseLayer;
	if (layer) {
		[self.globeViewController removeLayer:layer];
	}
}

#pragma mark - Actions

- (void)globeViewController:(WhirlyGlobeViewController *)viewC didTapAt:(MaplyCoordinate)coord
{
	NSString *title = @"Tap Location:";
	NSString *subtitle = [NSString stringWithFormat:@"(%.2fN, %.2fE)", coord.y*57.296,coord.x*57.296];
	[self addAnnotation:title withSubtitle:subtitle at:coord];
	
	[self addCircleAtCoordinate:coord];
}

// This is the version for a globe
- (void)globeViewController:(WhirlyGlobeViewController *)viewC didSelect:(NSObject *)selectedObj
{
	[self handleSelection:viewC selected:selectedObj];
}

- (void)handleSelection:(MaplyBaseViewController *)viewC selected:(NSObject *)selectedObj
{
	// ensure it's a MaplyVectorObject. It should be one of our outlines.
	if ([selectedObj isKindOfClass:[MaplyVectorObject class]]) {
		MaplyVectorObject *theVector = (MaplyVectorObject *)selectedObj;
		MaplyCoordinate location;
		
		if ([theVector centroid:&location]) {
			NSString *title = @"Selected:";
			NSString *subtitle = (NSString *)theVector.userObject;
			[self addAnnotation:title withSubtitle:subtitle at:location];
		}
	} else if ([selectedObj isKindOfClass:[MaplyScreenMarker class]]) {
		// or it might be a screen marker
		MaplyScreenMarker *theMarker = (MaplyScreenMarker *)selectedObj;
		
		if ([theMarker.userObject isKindOfClass:[RRAirport class]]) {
			RRAirport *airport = (RRAirport *)theMarker.userObject;
			
			[self addAnnotation:airport.iata.nonemptyString ?: airport.icao.nonemptyString withSubtitle:airport.fullName at:theMarker.loc];
		}
		
		if ([theMarker.userObject isKindOfClass:[NSString class]]) {
			NSString *string = (NSString *)theMarker.userObject;
			
			[self addAnnotation:string withSubtitle:@"Aircraft" at:theMarker.loc];
		}
	}
}

- (void)addAnnotation:(NSString *)title withSubtitle:(NSString *)subtitle at:(MaplyCoordinate)coord
{
	[self.globeViewController clearAnnotations];
	
	MaplyAnnotation *annotation = [[MaplyAnnotation alloc] init];
	annotation.title = title;
	annotation.subTitle = subtitle;
	[self.globeViewController addAnnotation:annotation forPoint:coord offset:CGPointZero];
}

#pragma mark - Items

- (void)addMBTiles:(NSString *)path priority:(int)priority imageFormat:(MaplyQuadImageFormat)imageFormat {
	MaplyMBTileSource *tileSource = [[MaplyMBTileSource alloc] initWithMBTiles:path];
	
	MaplyQuadImageTilesLayer *tilesLayer = [[MaplyQuadImageTilesLayer alloc] initWithCoordSystem:tileSource.coordSys
																					  tileSource:tileSource];
	tilesLayer.handleEdges = YES;
	tilesLayer.coverPoles = YES;
	tilesLayer.requireElev = NO;
	tilesLayer.waitLoad = NO;
	tilesLayer.drawPriority = priority;
	tilesLayer.imageFormat = imageFormat;
	
	[self.globeViewController addLayer:tilesLayer];
}

- (void)addCountries {
	self.vectorParameters = @{kMaplyColor: [UIColor whiteColor],
							  kMaplySelectable: @YES,
							  kMaplyVecWidth: @4};
	// handle this in another thread
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSArray<NSString *> *allOutlines = [[NSBundle mainBundle] pathsForResourcesOfType:@"geojson" inDirectory:nil];
		
		for (NSString *outlineFile in allOutlines)
		{
			NSData *jsonData = [NSData dataWithContentsOfFile:outlineFile];
			if (jsonData)
			{
				MaplyVectorObject *wgVecObj = [MaplyVectorObject VectorObjectFromGeoJSON:jsonData];
				
				NSString *vecName = [wgVecObj.attributes objectForKey:@"ADMIN"];
				if (!vecName) {
					continue;
				}
				wgVecObj.userObject = vecName;
				
				self.components[vecName] = [self.globeViewController addVectors:@[wgVecObj] desc:self.vectorParameters];
				
				if (vecName.length > 0)
				{
					MaplyScreenLabel *label = [[MaplyScreenLabel alloc] init];
					label.text = vecName;
					
					MaplyCoordinate location;
					if ([wgVecObj centroid:&location]) {
						label.loc = location;
					}
					
					label.selectable = true;
					label.layoutImportance = 10.0;
					[self.globeViewController addScreenLabels:@[label] desc:@{
					   kMaplyFont: [UIFont boldSystemFontOfSize:14.0],
					   kMaplyTextOutlineColor: [UIColor blackColor],
					   kMaplyTextOutlineSize: @2,
					   kMaplyColor: [UIColor whiteColor]
					   }];
				}
			}
		}
	});
}

- (void)addAirports {
	//NSDictionary *fields = @{@"name": name, @"icao": icao};
	//NSString *selectAirport = @"SELECT * FROM airports WHERE icao = (:icao) AND name = (:name)";
	NSString *selectAirport = @"select *, \
 ifr like 'IFR' as is_ifr, \
 length(iata) > 0 as is_iata, \
 regex(icao, '[A-Z]{4}') as is_icao, \
 length(icao) > 0 as is_reg, \
 length(icao) > 0 as is_reg \
 from airports \
 order by \
 airport_of_entry desc, \
 is_ifr desc, \
 is_iata desc, \
 is_icao desc, \
 is_reg desc limit 400";
	
	NSArray<RRAirport *> *airports = [[RRAirportsDatabase sharedInstance] performQuery:selectAirport withNamedFields:@{}];
	
	// get the image and create the markers
	UIImage *icon_ifr = [UIImage imageNamed:@"airport-civil-ifr"];
	UIImage *icon_vfr = [UIImage imageNamed:@"airport-civil-vfr"];
	NSMutableArray *markers = [NSMutableArray array];
	for (RRAirport *airport in airports)
	{
		int isVFR = [airport.ifr isEqualToString:@"VFR"];
		MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
		marker.image = isVFR ? icon_vfr : icon_ifr;
		marker.layoutImportance = 2.0 + airport.priority * 7;
		marker.loc = MaplyCoordinateMakeWithDegrees(airport.lon.doubleValue, airport.latitude.doubleValue);
		marker.selectable = true;
		marker.size = CGSizeMake(22, 22);
		marker.userObject = airport;
		[markers addObject:marker];
	}
	// add them all at once (for efficency)
	[self.globeViewController addScreenMarkers:markers desc:nil];
}

- (void)addAircrafts {
	UIImage *positionMarkerImage = [UIImage imageNamed:@"position-marker"];
	
	for (int i = 0; i < 20; i++)
	{
		MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
		marker.image = positionMarkerImage;
		marker.layoutImportance = 50;
		marker.loc = MaplyCoordinateMakeWithDegrees(rand() % 45 - 10, rand() % 60);
		marker.selectable = true;
		marker.size = CGSizeMake(22, 22);
		marker.userObject = [NSString stringWithFormat:@"%c%c%03i", 'A' + rand() % 26, 'A' + rand() % 26, rand() % 1000];
		
		ActiveMarker *activeMarker = [ActiveMarker activeMarkerForMarker:marker
														  displayOptions:nil
																 inViewC:self.globeViewController];
		activeMarker.rotation = (rand() % 365) / 180.0 * M_PI;
		
		[self.globeViewController addActiveObject:activeMarker];
		
		MapAircraft *aircraft = [[MapAircraft alloc] initWithActiveMarker:activeMarker];
		
		[self.aircrafts addObject:aircraft];
	}
	
}

- (void)addVectors {
	for (int i = 0; i < 20; i++)
	{
		MaplyCoordinate nodes[] = {
			MaplyCoordinateMakeWithDegrees(rand() % 45 - 10, rand() % 60),
			MaplyCoordinateMakeWithDegrees(rand() % 45 - 10, rand() % 60),
			MaplyCoordinateMakeWithDegrees(rand() % 45 - 10, rand() % 60),
			MaplyCoordinateMakeWithDegrees(rand() % 45 - 10, rand() % 60)
		};
		MaplyVectorObject *vector = [[MaplyVectorObject alloc] initWithLineString:nodes numCoords:4 attributes:@{}];
		[vector subdivideToGlobe:0.001];
		
		[self.globeViewController addWideVectors:@[vector] desc:@{kMaplyColor: [UIColor blueColor],
																  kMaplyVecWidth: @9,
																  kMaplyWideVecJoinType: kMaplyWideVecMiterJoin,
																  kMaplyDrawPriority: @(kMaplyVectorDrawPriorityDefault),
																  }];
		[self.globeViewController addWideVectors:@[vector] desc:@{kMaplyColor: [UIColor lightGrayColor],
																  kMaplyVecWidth: @5,
																  kMaplyWideVecJoinType: kMaplyWideVecMiterJoin,
																  kMaplyDrawPriority: @(kMaplyVectorDrawPriorityDefault + 1),
																  }];
		//		[self.globeViewController addLoftedPolys:@[vector]
//											 key:nil
//										   cache:nil
//											desc:@{kMaplyColor: [UIColor blueColor],
//												   kMaplyVecWidth: @3,
//												   kMaplyLoftedPolyOutline: @YES,
//												   kMaplyLoftedPolyOutlineColor: [UIColor redColor],
//												   kMaplyLoftedPolyOutlineWidth: @3,
//												   kMaplyLoftedPolyHeight: @(1),
//												   kMaplyLoftedPolyGridSize: @(0.1),
//												   }
//											mode:MaplyThreadAny];
	}
	
}

- (void)addCircleAtCoordinate:(MaplyCoordinate)coordinate {
	CLLocationCoordinate2D coordinate2D = CLLocationCoordinate2DMake(RRDegreesFromRadians(coordinate.y),
																	 RRDegreesFromRadians(coordinate.x));
	
	AnimatedVectorCircle *circle = [AnimatedVectorCircle animatedVectorCircleWithRadius:20000
																	 centerCoordinate2D:coordinate2D
																		 displayOptions:nil
																	   inViewController:self.globeViewController];
	
	[self.globeViewController addActiveObject:circle];
	
	[circle setRadius:1000000 withDuration:3.0];
	[circle setColor:[UIColor colorWithRed:0 green:0 blue:0.1 alpha:0] withDuration:3.0];
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self.globeViewController removeActiveObject:circle];
	});
}

- (void)addRadioAtCoordinate:(MaplyCoordinate)coordinate {
	[self addCircleAtCoordinate:coordinate];
	[self addRadioAtCoordinate2:coordinate];
}

- (void)addRadioAtCoordinate2:(MaplyCoordinate)coordinate {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[self addRadioAtCoordinate:coordinate];
	});
}

- (void)addRadios {
	// set up some locations
	MaplyCoordinate capitals[10];
	capitals[0] = MaplyCoordinateMakeWithDegrees(-77.036667, 38.895111);
	capitals[1] = MaplyCoordinateMakeWithDegrees(120.966667, 14.583333);
	capitals[2] = MaplyCoordinateMakeWithDegrees(55.75, 37.616667);
	capitals[3] = MaplyCoordinateMakeWithDegrees(-0.1275, 51.507222);
	capitals[4] = MaplyCoordinateMakeWithDegrees(-66.916667, 10.5);
	capitals[5] = MaplyCoordinateMakeWithDegrees(139.6917, 35.689506);
	capitals[6] = MaplyCoordinateMakeWithDegrees(166.666667, -77.85);
	capitals[7] = MaplyCoordinateMakeWithDegrees(-58.383333, -34.6);
	capitals[8] = MaplyCoordinateMakeWithDegrees(-74.075833, 4.598056);
	capitals[9] = MaplyCoordinateMakeWithDegrees(-79.516667, 8.983333);
	
	for (unsigned int i = 0; i < 10; i++)
	{
		[self addRadioAtCoordinate:capitals[i]];
	}
}

- (void)addBars {
	// set up some locations
	MaplyCoordinate capitals[10];
	capitals[0] = MaplyCoordinateMakeWithDegrees(-77.036667, 38.895111);
	capitals[1] = MaplyCoordinateMakeWithDegrees(120.966667, 14.583333);
	capitals[2] = MaplyCoordinateMakeWithDegrees(55.75, 37.616667);
	capitals[3] = MaplyCoordinateMakeWithDegrees(-0.1275, 51.507222);
	capitals[4] = MaplyCoordinateMakeWithDegrees(-66.916667, 10.5);
	capitals[5] = MaplyCoordinateMakeWithDegrees(139.6917, 35.689506);
	capitals[6] = MaplyCoordinateMakeWithDegrees(166.666667, -77.85);
	capitals[7] = MaplyCoordinateMakeWithDegrees(-58.383333, -34.6);
	capitals[8] = MaplyCoordinateMakeWithDegrees(-74.075833, 4.598056);
	capitals[9] = MaplyCoordinateMakeWithDegrees(-79.516667, 8.983333);
	
	// get the image and create the markers
	UIImage *icon = [UIImage imageNamed:@"alcohol-shop-24"];
	NSMutableArray *markers = [NSMutableArray array];
	for (unsigned int i = 0; i < 10; i++)
	{
		MaplyScreenMarker *marker = [[MaplyScreenMarker alloc] init];
		marker.image = icon;
		marker.loc = capitals[i];
		marker.size = CGSizeMake(40, 40);
		[markers addObject:marker];
	}
	// add them all at once (for efficency)
	//[self.globeViewController addScreenMarkers:markers desc:nil];
}

#pragma mark - MENU

- (void)setupMenuController {
	self.layersMenuController = [self.storyboard instantiateViewControllerWithIdentifier:@"LayerTable"];
	UIView *menu = self.layersMenuController.view;
	UIView *view = self.view;
	menu.translatesAutoresizingMaskIntoConstraints = NO;
	
	[view addSubview:menu];
	CGRect frame = view.frame;
	frame.origin.x = frame.size.width;
	frame.size.width = 320;
	menu.frame = frame;
	
	//[self addChildViewController:self.layersMenuController];
	
	id topLayoutGuide = self.topLayoutGuide;
	NSDictionary *views = NSDictionaryOfVariableBindings(menu, topLayoutGuide);
	[view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide]-0-[menu]-0-|" options:kNilOptions metrics:nil views:views]];
	[view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[menu(320)]" options:kNilOptions metrics:nil views:views]];
	self.layersMenuConstraint = [NSLayoutConstraint constraintWithItem:menu attribute:NSLayoutAttributeLeading
															 relatedBy:NSLayoutRelationEqual
																toItem:view attribute:NSLayoutAttributeTrailing
															multiplier:1 constant:0];
	[view addConstraint:self.layersMenuConstraint];
	
	self.layersMenuController.selectedLayer = [TileSourceLibrary sources][0];
	self.layersMenuController.selectedOverlay = [TileSourceLibrary overlays][2];
	
	self.layersMenuController.delegate = self;
}

- (IBAction)toggleLayersMenu:(id)sender {
	BOOL isMenuOpen = self.isMenuOpen;
	if (isMenuOpen) {
		[self.layersMenuController viewWillDisappear:YES];
	} else {
		[self.layersMenuController viewWillAppear:YES];
	}
	
	[UIView animateWithDuration:0.35
					 animations:^{
						 self.layersMenuConstraint.constant = isMenuOpen ? 0 : -self.layersMenuController.view.frame.size.width;
						 [self.view setNeedsLayout];
					 }
					 completion:^(BOOL finished) {
						 if (isMenuOpen) {
							 [self.layersMenuController viewDidDisappear:YES];
						 } else {
							 [self.layersMenuController viewDidAppear:YES];
						 }
					 }];
	self.isMenuOpen = !isMenuOpen;
}

- (void)layerTable:(LayerTableViewController *)layerTable didDeselectSource:(NSObject<MaplyTileSource> *)source isOverlay:(BOOL)isOverlay {
	[self removeLayerForOverlay:isOverlay];
}

- (void)layerTable:(LayerTableViewController *)layerTable didSelectSource:(NSObject<MaplyTileSource> *)source isOverlay:(BOOL)isOverlay {
	[self removeLayerForOverlay:isOverlay];
	[self addLayerWithWithSource:source forOverlay:isOverlay];
}

@end
