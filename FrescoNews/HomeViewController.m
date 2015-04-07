//
//  HomeViewController.m
//  FrescoNews
//
//  Created by Jason Gresh on 3/2/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import "HomeViewController.h"
#import "UIViewController+Additions.h"
#import "FRSDataManager.h"
#import "FRSTag.h"
#import "StoryCell.h"
#import "GalleryHeader.h"

@interface HomeViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation HomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _posts = [[NSMutableArray alloc] init];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setFrescoImageHeader];

    [self.tableView registerNib:[UINib nibWithNibName:@"StoryCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:[StoryCell identifier]];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 400.0;

    [self performNecessaryFetch:nil];
}

#pragma mark - Data Loading

- (void)performNecessaryFetch:(FRSRefreshResponseBlock)responseBlock
{
    // [self setActivityIndicatorVisible:YES];
    if (self.tag || !self.savedPosts) {

        [[FRSDataManager sharedManager] getHomeDataWithResponseBlock:^(NSArray *responseObject, NSError *error) {
            if (!error) {
                [self.posts setArray:responseObject];
                [self reloadData];
                [self setActivityIndicatorVisible:NO];
                if (responseBlock) {
                    responseBlock(YES, nil);
                }
            }
        }];
    }
    else if (self.savedPosts) {
        [self.posts setArray:self.savedPosts];
        [self reloadData];
        [self setActivityIndicatorVisible:NO];
        if (responseBlock) {
            responseBlock(YES, nil);
        }
    }
    else {
        [self setActivityIndicatorVisible:NO];
    }
}

- (void)refreshData
{
    [[FRSDataManager sharedManager] getPostsWithTag:self.tag limit:@(self.posts.count) responseBlock:^(NSArray *responseObject, NSError *error) {
        if (!error) {
            [self.posts setArray:responseObject];
            [self reloadData];
           // [self.refreshControl endRefreshing];
           // [[self listCollectionView] setContentOffset:CGPointZero animated:YES];
        }
    }];
}

- (void)reloadData
{
  //  [[self listCollectionView] reloadData];
  //  [[self detailCollectionView] reloadData];
    [self.tableView reloadData];
}

#pragma mark - loading view

- (void)setActivityIndicatorVisible:(BOOL)visible
{
/*
    [_loadingView removeFromSuperview];
    
    [self setLoadingView:nil];
    
    if (visible) {
        UIActivityIndicatorView *actIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        CGPoint viewCenter = [[self view] center];
        [actIndicator setCenter:viewCenter];
        [[self listCollectionView] addSubview:actIndicator];
        [actIndicator startAnimating];
        [self setLoadingView:actIndicator];
    }*/
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.posts count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger index = indexPath.section;
    
    //Get story for cell at this index
    FRSPost *cellStory = [self.posts objectAtIndex:index];
   
    //If we are in the master list
    // if (collectionView == [self listCollectionView]) {
    
    StoryCell *cell = [tableView dequeueReusableCellWithIdentifier:[StoryCell identifier] forIndexPath:indexPath];
    [cell setPost:cellStory];

    return cell;
    
    //}
    /*
    //If we are in the detail list
    else if ([collectionView isEqual:[self detailCollectionView]]) {
        
        FRSStoryDetailCell *detailViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:[FRSStoryDetailCell identifier] forIndexPath:indexPath];
        
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"photoClicked"]){
            [detailViewCell.tapView setHidden:YES];
        } else {
            CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
            pulseAnimation.duration = .5;
            pulseAnimation.toValue = [NSNumber numberWithFloat:1.1];
            pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            pulseAnimation.autoreverses = YES;
            pulseAnimation.repeatCount = FLT_MAX;
            [detailViewCell.tapView.layer addAnimation:pulseAnimation forKey:nil];
        }
        UITapGestureRecognizer *tapGestureRecognizer =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
        
        [tapGestureRecognizer setCancelsTouchesInView:NO];
        
        [detailViewCell addGestureRecognizer:tapGestureRecognizer];
        
        [detailViewCell.scrollView setDelegate:self];
        [detailViewCell setPost:cellStory];
        detailViewCell.isWeb = false;
        
        return detailViewCell;
    }
    
    return nil;*/
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 36;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    GalleryHeader *storyCellHeader = [tableView dequeueReusableCellWithIdentifier:[GalleryHeader identifier]];

    // remember, one story per section
    FRSPost *cellStory = [self.posts objectAtIndex:section];
    [storyCellHeader setPost:cellStory];
    
    return storyCellHeader;
}

@end
