//
//  FRSAssetsPickerController.m
//  Fresco
//
//  Created by Elmir Kouliev on 10/7/15.
//  Copyright © 2015 Fresco. All rights reserved.
//

#import "AssetsPickerController.h"
#import "AssetGridViewCell.h"
#import "FRSGallery.h"
#import "GalleryPostViewController.h"
#import "FRSRootViewController.h"
#import "FRSTabBarController.h"

@implementation NSIndexSet (Convenience)
- (NSArray *)aapl_indexPathsFromIndexesWithSection:(NSUInteger)section {
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:idx inSection:section]];
    }];
    return indexPaths;
}
@end

@implementation UICollectionView (Convenience)
- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}
@end

@interface AssetsPickerController () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) UIView *noAssetsView;

@property (strong, nonatomic) UICollectionView* collectionView;

@property (strong, nonatomic) UICollectionViewLayout* collectionViewLayout;

@property (strong) PHCachingImageManager *imageManager;

@property CGRect previousPreheatRect;

@end

@implementation AssetsPickerController

static NSString * const CellReuseIdentifier = @"Cell";

static CGSize AssetGridThumbnailSize;

- (instancetype)init{

    self = [super init];
    
    if(self){
        
        //Navigation Controller
        self.navigationItem.title = @"Choose Media";
        self.navigationController.navigationBar.tintColor = [UIColor textHeaderBlackColor];
    
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(returnToCamera)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
        
        self.view.backgroundColor = [UIColor whiteColor];

        
        //Check the orientation
        CGFloat width = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ?
        [[UIScreen mainScreen] bounds].size.width
        :
        [[UIScreen mainScreen] bounds].size.height;
        
        CGFloat height = UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ?
        [[UIScreen mainScreen] bounds].size.height
        :
        [[UIScreen mainScreen] bounds].size.width;
        
        self.assetsFetchResults = [self fetchInitialResults];
        
        if(self.assetsFetchResults.count == 0){
            
            [self configureAuxiliaryView:width andHeight:height];
            
        }
        
        //Initiaize image manager
        self.imageManager = [[PHCachingImageManager alloc] init];
        [self resetCachedAssets];
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
        // Initialize Flow Layout.
        UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 4;
        
        
        //Configure cell size
        AssetGridThumbnailSize = CGSizeMake(width / 3 - 3, width / 3 - 3); // -3 to account for cell spacing
        layout.itemSize = AssetGridThumbnailSize;

        self.collectionViewLayout = layout;
        
        // Initilaize collection view.
        self.collectionView=[[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, width, height - 66) collectionViewLayout:self.collectionViewLayout]; // -66 to account for toolbar height
        self.collectionView.allowsMultipleSelection = YES;
        self.collectionView.allowsSelection = YES;
        
        // Set it as delegate and data source.
        [self.collectionView setDataSource:self];
        [self.collectionView setDelegate:self];
        
        // Register cell class and prepare each cell for re-use for efficiency.
        [self.collectionView registerClass:[AssetGridViewCell class] forCellWithReuseIdentifier:CellReuseIdentifier];
        // Make background view clear
        [self.collectionView setBackgroundColor:[UIColor clearColor]];
        
        // Add collection view as subview to our root view.
        [self.view addSubview:self.collectionView];
        
        //Initialize selected assets property for keeping track of assets
        self.selectedAssets = [NSMutableArray new];
        
    }
    
    return self;

}

- (void)viewDidLoad{

    [super viewDidLoad];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    //Set up tool bar items
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:@selector(createGalleryPost:)];
    UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(createGalleryPost:)];
    
    title.enabled = YES;

    NSArray *toolbarItems = @[space, title, space];
    
    [self.navigationController.toolbar setBarStyle:UIBarStyleDefault];
    [self.navigationController.visibleViewController setToolbarItems:toolbarItems animated:NO];
    [self.navigationController setToolbarHidden:NO];
    [self toggleToolbarAppearance];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateCachedAssets];
}

#pragma mark - Orientation

-(BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = self.assetsFetchResults.count;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AssetGridViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellReuseIdentifier forIndexPath:indexPath];
    
    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    
    PHAsset *asset = self.assetsFetchResults[indexPath.item];

    [self.imageManager requestImageForAsset:asset targetSize:AssetGridThumbnailSize contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage *result, NSDictionary *info) {
        
        // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
        if (cell.tag == currentTag) {
            
            [cell setThumbnailImage:result];
            
        }
        
    }];
    
    return cell;
};

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    [self toggleToolbarAppearance];
    
    //Add PHAsset to selected assets from `assetsFetchResults` array
    [self.selectedAssets addObject:self.assetsFetchResults[indexPath.item]];
    
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath{

    [self toggleToolbarAppearance];

    //Remove PHAsset from selected assets
    [self.selectedAssets removeObject:self.assetsFetchResults[indexPath.item]];
    
}


#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    // Call might come on any background queue. Re-dispatch to the main queue to handle it.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // check if there are changes to the assets (insertions, deletions, updates)
        PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
        if (collectionChanges) {
            
            // get the new fetch result
            self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];
            
            UICollectionView *collectionView = self.collectionView;
            
            if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
                // we need to reload all if the incremental diffs are not available
                [collectionView reloadData];
                
            } else {
                // if we have incremental diffs, tell the collection view to animate insertions and deletions
                [collectionView performBatchUpdates:^{
                    NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
                    if ([removedIndexes count]) {
                        [collectionView deleteItemsAtIndexPaths:[removedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                    NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
                    if ([insertedIndexes count]) {
                        [collectionView insertItemsAtIndexPaths:[insertedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                    NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
                    if ([changedIndexes count]) {
                        [collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
                    }
                } completion:NULL];
            }
            
            [self resetCachedAssets];
        }
    });
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateCachedAssets];
}

#pragma mark - Asset Caching

/**
 *  Fetchs initial assets
 *
 *  @return PHFetchResult containing assets
 */

- (PHFetchResult *)fetchInitialResults{

    //Photos fetch
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    
    #if TARGET_IPHONE_SIMULATOR
    
    #else
        //Set maximumum 1 day of age
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
        components.day -= 1; //1 day
        NSDate *lastDay  = [calendar dateFromComponents:components];
        options.predicate = [NSPredicate predicateWithFormat:@"(creationDate >= %@)", lastDay];
    #endif
    
    PHFetchResult *results = [PHAsset fetchAssetsWithOptions:options];
    NSMutableArray *filteredAssets = [NSMutableArray new];
    
    [results enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
        //Check if there is a location, and if the video is less than the MAX_VIDEO_LENGTH
        if (asset.location != nil && asset.duration < MAX_VIDEO_LENGTH) {
            [filteredAssets addObject:asset];
        }
    }];
    
    PHAssetCollection *assetCollectionWithLocation = [PHAssetCollection transientAssetCollectionWithAssets:filteredAssets title:@"Assets with location data"];
    
    return [PHAsset fetchAssetsInAssetCollection:assetCollectionWithLocation options:nil];
}

- (void)resetCachedAssets
{
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets
{
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    // If scrolled by a "reasonable" amount...
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:AssetGridThumbnailSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:AssetGridThumbnailSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler
{
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths
{
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item];
        [assets addObject:asset];
    }
    return assets;
}

#pragma mark - UIView 

/**
 *  Sets up auxillary view when there is no content;
 the reason why Width and Height is passed, is because this view is presented from a landscape view controller, and the width and height are swapped inititially
 *
 *  @param width  The width of the super view
 *  @param height The height of the super view
 */

- (void)configureAuxiliaryView:(CGFloat)width andHeight:(CGFloat)height {
    
    self.noAssetsView = [[UIView alloc] initWithFrame:CGRectMake(0,0, width * .9, 120)];
    self.noAssetsView.center = CGPointMake(width /2, height/2);
    
    UILabel *primary = [[UILabel alloc] initWithFrame:CGRectZero];
    primary.font = [UIFont fontWithName:HELVETICA_NEUE_LIGHT size:17];
    primary.textAlignment = NSTextAlignmentCenter;
    primary.textColor = [UIColor textHeaderBlackColor];
    primary.text = @"No Photos or Videos";
    [primary sizeToFit];
    primary.center = CGPointMake(CGRectGetWidth(self.noAssetsView.frame) /2, 0);
    
    UILabel *secondary = [[UILabel alloc] initWithFrame:CGRectZero];
    secondary.font = [UIFont fontWithName:HELVETICA_NEUE_LIGHT size:11];
    secondary.textAlignment = NSTextAlignmentCenter;
    secondary.textColor = [UIColor textHeaderBlackColor];
    secondary.text = @"Only media from the last 24 hours is visible";
    [secondary sizeToFit];
    secondary.center = CGPointMake(CGRectGetWidth(self.noAssetsView.frame) /2, 22);
    
    [self.noAssetsView addSubview:primary];
    [self.noAssetsView addSubview:secondary];
    
    [self.view addSubview:self.noAssetsView];
}

#pragma mark - Toolbar Apperance

- (void)toggleToolbarAppearance {
    
    dispatch_async(dispatch_get_main_queue(), ^{
            
        if (self.selectedAssets.count)
            self.navigationController.toolbar.barTintColor = [UIColor greenToolbarColor];
        else
            self.navigationController.toolbar.barTintColor = [UIColor disabledToolbarColor];
            
    });
}

#pragma mark - BarButtonItem Selectors

/**
 *  Sends App back to Tab Bar Controller
 */

- (void)cancel{

    FRSTabBarController *tabBarController = ((FRSRootViewController *)self.presentingViewController.presentingViewController).tbc;
    
    tabBarController.selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:UD_PREVIOUSLY_SELECTED_TAB];
    
    tabBarController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [tabBarController dismissViewControllerAnimated:YES completion:nil];

}

/**
 *  Dismisses AssetPicker to go back to camera
 */

- (void)returnToCamera{
    
    [self dismissViewControllerAnimated:YES completion:nil];

}

/**
 *  Pushes VC to GalleryPost View Controller with selected assets
 *
 *  @param sender
 */

- (void)createGalleryPost:(id)sender{

    if (!self.selectedAssets.count) {
        
        return;
    }
    
    FRSGallery *gallery = [[FRSGallery alloc] initWithAssets:self.selectedAssets];
    
    if (!gallery) {
        return;
    }
    
    GalleryPostViewController *vc = [[UIStoryboard storyboardWithName:@"Camera" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"galleryPost"];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Media"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    vc.gallery = gallery;
    
    [self.navigationController pushViewController:vc animated:YES];


}


@end