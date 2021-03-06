//
//  FRSGalleryTableViewCell.h
//  Fresco
//
//  Created by Daniel Sun on 1/4/16.
//  Copyright © 2016 Fresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRSGalleryView.h"
#import "FRSActionBar.h"

@class FRSGallery;

static NSString *const galleryCellIdentifier = @"gallery-cell";

@interface FRSGalleryTableViewCell : UITableViewCell <FRSGalleryViewDelegate> {
    BOOL hasPlayed;
}

@property (strong, nonatomic) IBOutlet FRSGalleryView *galleryView;

@property (weak, nonatomic) id<FRSGalleryViewDelegate> delegate;
@property (strong, nonatomic) FRSGallery *gallery;
@property (strong, nonatomic) ShareSheetBlock shareBlock;
@property (strong, nonatomic) ShareSheetBlock readMoreBlock;
@property (strong, nonatomic) NSArray *players;
@property (weak, nonatomic) UINavigationController *navigationController;
@property BOOL hasVideoAsFirstPost;

@property (nonatomic, readwrite) FRSTrackedScreen trackedScreen;

- (void)clearCell;
- (void)configureCell;
- (void)offScreen;
- (void)play;
- (void)pause;

@end
