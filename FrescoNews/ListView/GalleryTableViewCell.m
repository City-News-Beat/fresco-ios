//
//  GalleryTableViewCell.m
//  FrescoNews
//
//  Created by Jason Gresh on 3/25/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import "GalleryTableViewCell.h"
#import "GalleryView.h"
#import "FRSGallery.h"

static NSString * const kCellIdentifier = @"GalleryTableViewCell";

@implementation GalleryTableViewCell

+ (NSString *)identifier
{
    return kCellIdentifier;
}

- (void)awakeFromNib {
    
}



- (void)setGallery:(FRSGallery *)gallery
{
    _gallery = gallery;
    self.galleryView.gallery = gallery;
}

- (void)prepareForReuse
{
    self.gallery = nil;
}
@end