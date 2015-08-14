//
//  GalleryHeader.m
//  FrescoNews
//
//  Created by Fresco News on 3/17/15.
//  Copyright (c) 2015 Fresco. All rights reserved.
//

#import "GalleryHeader.h"
#import "FRSPost.h"
#import "FRSGallery.h"
#import <FXBlurView.h>

@interface GalleryHeader ()
@property (weak, nonatomic) IBOutlet UILabel *labelTimeAndPlace;
@property (weak, nonatomic) IBOutlet UILabel *labelByLine;
@end

static NSString * const kCellIdentifier = @"GalleryHeader";

@implementation GalleryHeader

+ (NSString *)identifier
{
    return kCellIdentifier;
}

- (void)setGallery:(FRSGallery *)gallery
{
    FRSPost *post = (FRSPost *)[gallery.posts firstObject];
    
    self.labelTimeAndPlace.text = [MTLModel relativeDateStringFromDate:gallery.createTime];
    
    if([post.address isKindOfClass:[NSString class]]){
    
        if ([post.address length] > 0) {
            self.labelTimeAndPlace.text = [NSString stringWithFormat:@"%@, %@", post.address, self.labelTimeAndPlace.text];
            [self.labelTimeAndPlace sizeToFit];
        }
        
    }
    
    self.labelByLine.text = post.byline;
    
    self.backgroundColor = [UIColor whiteColor];
}

@end
